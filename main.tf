terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

}

variable "aws_access_key" {
  
}

variable "aws_secret_key" {
  
}
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
  default = "vpc-01cd1ac18f2c93b55"
}

# 10.0.0.0/16

variable "subnets" {
  description = "A list of maps, where each map contains subnet-specific attributes"
  type = list(object({
    cidr_block = string
    az         = string
  }))
  default = [
    {
      cidr_block = "10.0.1.0/24"
      az         = "us-west-2a"
    },
    {
      cidr_block = "10.0.2.0/24"
      az         = "us-west-2b"
    },
    {
      cidr_block = "10.0.3.0/24"
      az         = "us-west-2c"
    }
  ]
}

variable "security_group_rules" {
  description = "A list of security group rules"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

resource "aws_vpc" "env0_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "env0-vpc"
  }
}

resource "aws_subnet" "env0_subnet" {
  for_each = { for subnet in var.subnets : subnet.cidr_block => subnet }

  vpc_id            = aws_vpc.env0_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    Name = "env0-subnet-${each.value.az}"
  }
}

resource "aws_security_group" "env0_security_group" {
  name        = "env0-security-group"
  vpc_id      = aws_vpc.env0_vpc.id

  dynamic "ingress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "egress"]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = "env0-security-group"
  }
}


# The aws_subnet resource does not support nested blocks that 
# would require the use of a dynamic block. Instead, dynamic 
# blocks are usually used in complex resources that have nested configurations.
