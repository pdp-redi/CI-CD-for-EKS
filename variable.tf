variable "aws_region" {
  description = "region name"
  type        = string
  default     = "ap-south-1"
}

variable "env" {
  description = "demo-asg-alb-acm-route53"
  type        = string
  default     = "eks"
}

variable "public_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    subnet1 = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-south-1a"
    }
    subnet2 = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "ap-south-1b"
    }
  }
}

variable "private_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    subnet1 = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "ap-south-1a"
    }
    subnet2 = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "ap-south-1b"
    }
  }
}