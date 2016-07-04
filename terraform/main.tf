provider "aws" {
  region = "us-west-2"
}

// TODO(jen20): Look this up with an data.aws_ami and build custom
variable "openvpn_ami" {
  type    = "string"
  default = "ami-b7418dd7"
}

variable "instance_type" {
  type    = "string"
  default = "t2.small"
}

variable "key_name" {
  type    = "string"
}

data "terraform_remote_state" "vpc" {
  backend = "atlas"

  config = {
    name = "ny-hug/vpc"
  }
}

resource "aws_security_group" "openvpn" {
  name        = "openvpn-sg"
  description = "Security group for Open VPN instances"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  tags {
    Name = "OpenVPN"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "openvpn" {
  ami           = "${var.openvpn_ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${element(data.terraform_remote_state.vpc.public_subnet_ids, 0)}"

  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.openvpn.id}"]
  key_name                    = "${var.key_name}"

  tags {
    Name = "VPN"
  }
}

output "vpn_ip" {
  value = "${aws_instance.openvpn.public_ip}"
}

output "vpn_setup_command" {
  value = "${format("ssh openvpnas@%s", aws_instance.openvpn.public_ip)}"
}

output "vpn_portal" {
  value = "${format("https://%s", aws_instance.openvpn.public_ip)}"
}
