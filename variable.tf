variable "cidr_block" {
  type    = string
  default = "10.1.0.0/16"
}
variable "publicsubnet" {
  type    = string
  default = "10.1.1.0/24"
}
variable "availability_zone" {
  type    = string
  default = "eu-central-1a"
}
variable "privatesubnet" {
  type    = string
  default = "10.1.2.0/24"
}
#day6
variable "vpc2" {
  type    = string
  default = "10.2.0.0/16"
}
variable "peersubnet" {
  type    = string
  default = "10.2.1.0/24"
}
variable "peerAZ" {
  type    = string
  default = "eu-central-1b"
}