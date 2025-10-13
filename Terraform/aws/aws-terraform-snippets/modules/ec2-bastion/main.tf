resource "aws_security_group" "sg" {
  name        = "${var.name}-bastion-sg"
  description = "SSH access"
  vpc_id      = var.vpc_id

  ingress { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = [var.ssh_cidr] }
  egress  { from_port = 0  to_port = 0  protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }

  tags = var.tags
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name" values = ["al2023-ami-*-x86_64"] }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true

  tags = merge(var.tags, { Name = "${var.name}-bastion" })
}

output "public_ip"   { value = aws_instance.bastion.public_ip }
output "instance_id" { value = aws_instance.bastion.id }
