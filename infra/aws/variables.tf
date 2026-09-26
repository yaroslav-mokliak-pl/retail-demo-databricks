variable "project" {
  type    = string
  default = "retail-demo"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "force_destroy" {
  description = "Allow destroying the bucket even if it has objects (fine for a pet project)"
  type        = bool
  default     = true
}