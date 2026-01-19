# Variables

variable "region" {
  type        = string
  default = "us-east-1"
} 

variable "bucket_name" {
  type        = string
  default = "sasha-devops-project" 
}

variable "ami" {
  type        = string
  default = "ami-07ff62358b87c7116"
}

variable "instance_type" {
  type        = string
  default = "t2.micro" 
}

variable "subnet_id" {
  type        = string
  default = "subnet-05af4b9fcf2cdc250"
}

variable "port" {
  type        = number
  default = 80
}


variable "vpc_id" {
  type        = string
  default = "vpc-0835614ee6f077288"
}