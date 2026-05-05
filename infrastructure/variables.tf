variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "grocery-app"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name for SSH"
  type        = string
}

variable "my_ip" {
  description = "Public IP in CIDR format for SSH, example: 1.2.3.4/32"
  type        = string
}

variable "my_vpc_cidr" {
  description = "the vpc subnet of cidr"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = " public subnet cider"
  type        = string
  default     = "10.0.1.0/24"
}

variable "my_ami" {
  description = "ami"
  type        = string
  default     = "ami-0de6934e87badb694"

}

variable "private_subnet_cidr" {
  description = "CIDR block for second subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "grocerydb"
}
variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}
