terraform {
	backend "remote" {
    organization = "foxhound-unit" 

    workspaces { 
      name = "aws-infra" 
    } 
	}
}

variable "region_name" {
  type        = string
  description = "The AWS region to provision resources into."
}

variable "name_tag" {
  type        = string
  description = "The Name that will be used to tag EC2 resources created by the TF plan."
}

variable "ami_id" {
  type        = string
  description = "The id of the AMI that will be used for the EC2 instances created by the TF plan."
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type that will be used to create new EC2 instances."
}

variable "instance_count" {
  type        = number
  description = "The number of EC2 instances to create."
  default     = 2
}

variable "public_key" {
  type        = string
  description = "The public key to deploy for the new instance(s)."
}

provider "aws" {
  region  = var.region_name
}

resource "aws_security_group" "Terraform_Demo_SG" {
  name        = var.name_tag

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "Terraform_Demo_Key" {
  key_name   = var.name_tag
  public_key = var.public_key
}

resource "aws_instance" "Terraform_Demo_EC2" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.Terraform_Demo_SG.name]
  user_data = file("userdata_Linux.sh")
  key_name = var.name_tag
  tags = {
                Name = "${var.name_tag}-${count.index + 1}"
                Provisioner = "Terraform"
                Manager = "Ansible"
        }
  }

output "instance_ip_addr" {
  value       = "${formatlist("%v", aws_instance.Terraform_Demo_EC2.*.public_ip)}"
  description = "The Public IP address of the instance."
}

output "instance_public_dns" {
  value       = "${formatlist("%v", aws_instance.Terraform_Demo_EC2.*.public_dns)}"
  description = "The Public DNS of the instance."
}

output "instance_tags" {
  value       = "${formatlist("%v", aws_instance.Terraform_Demo_EC2.*.tags_all)}"
  description = "The tags of the instance."
}

