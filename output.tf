output "publicip" {
  value = aws_instance.name.public_ip
}
output "privateip" {
  value = aws_instance.privateinstance.private_ip
}