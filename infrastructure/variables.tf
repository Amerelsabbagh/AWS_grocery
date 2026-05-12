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
  description = " public subnet cidr"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_b" {
  description = " private subnet cidr b"
  type        = string
  default     = "10.0.2.0/24"
}
variable "private_subnet_cidr_c" {
  description = "private subnet cidr c"
  type        = string
  default     = "10.0.3.0/24"
}
variable "my_ami" {
  description = "ami"
  type        = string
  default     = "ami-0de6934e87badb694"

}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "grocerymate_db"
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
variable "db_engine" {
  description = "Database engine for RDS"
  type        = string
  default     = "postgres"
}
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling (GB)"
  type        = number
  default     = 100
}

variable "db_publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on RDS deletion"
  type        = bool
  default     = true
}

variable "db_storage_encrypted" {
  description = "Enable storage encryption for RDS"
  type        = bool
  default     = true
}
