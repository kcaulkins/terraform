variable "serverCount" {
  type = number
 default = 1
}
variable "region" {
  type = string
  description = "AWS region for hosting our your network"
  default = "us-east-1"
}
variable "public_key_path" {
  type = string
  description = "Enter the path to the SSH Public Key to add to AWS."
  default = "~/.ssh/id_rsa.pub"
}
variable "key_name" {
  type = string
  description = "Key name for SSHing into EC2"
  default = "kaypair_name"
}
variable "amis" {
  type = string
  description = "Base AMI to launch the instances"
  default = {
    us-east-1 = "ami-0d29b48622869dfd9"
  }
}
variable "office_ip" {
  type = string
  description = "Allowed SSH IP address"
  default = "0.0.0.0/0"
}
variable "profile" {
  type = string
  description = "What AWS CLI profile to use"
  default = "default"
}
variable "app_name" {
  type = string
  description = "Name of the application that will run"
  default = "website-prod"
}
variable "ssl_cert_arn" {
  type = string
  description = "ARN of the SSL Certificate"
  default = "arn:aws:acm:us-east-1:0000000000:certificate/000-0000-0000"
}