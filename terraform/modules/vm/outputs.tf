output "public_ip" {
  value = aws_eip.vm_ip.public_ip
}
