# infra/terraform/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-todo-app-tf-state"
    key    = "todo-app/terraform.tfstate"
    region = "us-east-2"
    use_lockfile = true  # replace deprecated dynamodb_table
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

# 1. EC2 instance
resource "aws_instance" "todo_server" {
  ami           = "ami-0f5fcdfbd140e4ab7"
  instance_type = "c7i-flex.large"
  key_name      = "access"
  subnet_id     = "subnet-0517b2602f8db9eca"
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

# 2. Security group
resource "aws_security_group" "todo_sg" {
  name        = "todo-app-sg"
  description = "Allow web traffic"
  vpc_id      = "vpc-0e44b8581b7a7e098"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "todo-app-sg"
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
    instance_ip = aws_instance.todo_server.public_ip
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
