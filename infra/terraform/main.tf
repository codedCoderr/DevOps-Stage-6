# infra/terraform/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Remote Backend (S3 example)
  backend "s3" {
    bucket = "my-todo-app-tf-state"
    key    = "todo-app/terraform.tfstate"
    region = "us-east-2"
    # DynamoDB table for state locking
    dynamodb_table = "terraform-locks" 
  }
}

# 1. Provision the Cloud Server (e.g., an EC2 instance)
resource "aws_instance" "todo_server" {
  ami            = "ami-0f5fcdfbd140e4ab7" # Find a suitable Ubuntu/Amazon Linux 2 AMI
  instance_type  = "t3.medium"
  key_name       = "access"
  
  subnet_id = "subnet-0517b2602f8db9eca"

  vpc_security_group_ids = [aws_security_group.todo_sg.id]
  
  root_block_device {
    volume_size = 20 # Increase to 20GB
    volume_type = "gp3"
    delete_on_termination = true
  }

  # 4. Remote commands (e.g., waiting for cloud-init)
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init...'" # Wait for initial setup
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/Downloads/access.pem") 
      host        = self.public_ip
    }
  }

  # ❌ REMOVED: The local-exec provisioner has been moved to the null_resource below
}

# 2. Configure Security Groups (Allow HTTP/HTTPS/SSH)
resource "aws_security_group" "todo_sg" {
  name        = "todo-app-sg"
  description = "Allow web traffic"
  vpc_id      = "vpc-0e44b8581b7a7e098"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # HTTP 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic is allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Generate an Ansible inventory file dynamically
resource "local_file" "ansible_inventory" {
  # ✅ CORRECT PATH: Creates inventory.ini in the parent directory (/infra/)
  filename = "${path.module}/../inventory.ini"
  
  content = <<EOT
[webservers]
${aws_instance.todo_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/Downloads/access.pem
EOT
}

## ✨ Step 4: Run Ansible via Null Resource (The Fix)

# This resource guarantees that Ansible runs only after the EC2 instance is fully created AND the inventory file has been written to the parent directory.

resource "null_resource" "ansible_run_trigger" {
  # 🔑 FIX: Explicitly wait for the instance and the inventory file to exist.
  depends_on = [
    aws_instance.todo_server,
    local_file.ansible_inventory
  ]

  # This provisioner executes the Ansible command only when dependencies are met.
  provisioner "local-exec" {
    # Set working directory to the module path (/infra/terraform/)
    working_dir = path.module 
    
    # Use relative paths (../inventory.ini and ../ansible/deploy.yml) 
    # to access files in the parent directory (/infra/)
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../inventory.ini ../ansible/deploy.yml"
  }
}