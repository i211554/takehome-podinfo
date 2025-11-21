resource "aws_instance" "vm" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.sg_id]

  key_name = var.key_name

  user_data = file("${path.module}/install_docker.sh")

  tags = {
    Name = "${var.env}-app-vm"
  }
}

resource "aws_eip" "vm_ip" {
  instance = aws_instance.vm.id
}
