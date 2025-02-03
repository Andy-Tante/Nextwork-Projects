variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "publicsubnet" {
  type    = string
  default = "10.0.0.0/24"
}
variable "availability_zone" {
  type    = string
  default = "eu-central-1a"
}