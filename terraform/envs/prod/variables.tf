variable "env"           {}
variable "region"        {}
variable "vpc_cidr"      {}
variable "public_subnet_cidrs" { type = list(string) }
variable "ami_id"        {}
variable "instance_type" {}
variable "key_name"      {}
