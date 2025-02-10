output "requesterinstance" {
  value = aws_instance.name.public_ip
}
output "privateip" {
  value = aws_instance.privateinstance.private_ip
}
output "accepterinstance" {
  value = aws_instance.name1.public_ip
}