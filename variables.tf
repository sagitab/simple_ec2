variable "cloud" {
  type        = string
  description = "The target cloud provider (aws or gcp)"
  
  validation {
    condition     = contains(["aws", "gcp"], var.cloud)
    error_message = "The cloud variable must be either 'aws' or 'gcp'."
  }
}

variable "region" {
  type        = string
  default = "us-east-1"
} 