variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "bucketpront"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "flask-lambda-function"
}