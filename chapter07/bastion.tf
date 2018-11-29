resource "aws_security_group" "ssh_bastion" {
  name        = "ssh-bastion"
  description = "group for ssh-bastion hosts"
  vpc_id      = "${aws_vpc.k8s.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-bastion"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ssh_bastion" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  subnet_id              = "${aws_subnet.public.*.id[0]}"
  vpc_security_group_ids = ["${aws_security_group.ssh_bastion.id}"]

  key_name  = "${var.key_name}"

  tags {
    Name = "ssh-bastion"
  }

  lifecycle {
    create_before_destroy = true
  }
}
