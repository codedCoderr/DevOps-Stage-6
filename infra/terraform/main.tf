terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "my-todo-app-tf-state"
    key          = "todo-app/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

# Manage all tags consistently via provider default_tags
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = "todo-app"
      Environment = "dev"
    }
  }
}

variable "ssh_private_key" {
  type = string
}

# --- Core Networking Lookup (FIXED: Using Data Sources to find existing VPC) ---
# Find the VPC ID based on the existing subnet ID used for the EC2 instance.
# This prevents the InvalidGroup.NotFound error.
data "aws_subnet" "selected_subnet" {
  id = "subnet-0517b2602f8db9eca"
}

data "aws_vpc" "selected_vpc" {
  id = data.aws_subnet.selected_subnet.vpc_id
}
# --- End Lookup ---


# 1. EC2 instance
resource "aws_instance" "todo_server" {
  ami                 = "ami-0f5fcdfbd140e4ab7"
  instance_type       = "c7i-flex.large"
  key_name            = "access"
  subnet_id           = "subnet-0517b2602f8db9eca"
  vpc_security_group_ids = [aws_security_group.todo_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "todo-server"
  }
}


# 2. Security group (Will now be created in the correct, existing VPC)
resource "aws_security_group" "todo_sg" {
  name        = "todo-sg"
  description = "Allow inbound traffic for Traefik and SSH"
  # Reference the VPC ID found via the data source
  vpc_id      = data.aws_vpc.selected_vpc.id 

  # Keeps the instance attached to the old SG until the new one is ready
  lifecycle {
    create_before_destroy = true
  }

  # --- INGRESS RULES ---

  # 1. Allow HTTP (Port 80)
  ingress {
    description = "HTTP access for Lets Encrypt validation" 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 2. Allow HTTPS (Port 443) for secure application access
  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 3. Allow SSH (Port 22) for deployment/management
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # --- EGRESS RULE ---

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todo-sg"
  }
}

# 3. Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  depends_on = [aws_instance.todo_server]

  filename = "${path.module}/../inventory.ini"

  content = <<EOT
[webservers]
${aws_instance.todo_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/tmp/access.pem
EOT

  file_permission      = "0644"
  directory_permission = "0755"
}

# 4. Trigger Ansible
resource "null_resource" "ansible_run_trigger" {
  depends_on = [local_file.ansible_inventory]

  triggers = {
    public_ip = aws_instance.todo_server.public_ip
  }

  provisioner "local-exec" {
    command = <<EOT
echo "${var.ssh_private_key}" | base64 --decode > /tmp/access.pem
chmod 600 /tmp/access.pem
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../inventory.ini ../ansible/deploy.yml --private-key /tmp/access.pem
rm /tmp/access.pem
EOT
  }
}