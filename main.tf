terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""

}

locals {
  key_name         = "demokey"
  private_key_path = "/home/jiso/terraform/demokey.pem"
}

# resource "aws_ebs_volume" "awsvolume" {
#   availability_zone = "us-east-1b"
#   size              = 1

#   tags = {
#     Name = "HelloWorld"
#   }
# }

# resource "aws_volume_attachment" "mountvolumetoec2" {
#   device_name = "/dev/sdd"
#   instance_id = aws_instance.demo.public_ip
#   volume_id = aws_ebs_volume.awsvolume.id
# }


# create a security group

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web traffic"


  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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
    Name = "allow_web"
  }
}




resource "aws_instance" "demo" {
  ami             = "ami-0cff7528ff583bf9a"
  instance_type   = "t2.micro"
  key_name        = "demokey"
  security_groups = ["${aws_security_group.allow_web.name}"]
  tags = {
    "Name" = "demoo"
  }

  root_block_device {
    volume_size           = 8 # GB
    delete_on_termination = true
    volume_type           = "gp2"
  }
  provisioner "remote-exec" {
    inline = ["echo 'wait until ssh is ready'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/jiso/terraform/demokey.pem")
      host        = aws_instance.demo.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u root -i ${aws_instance.demo.public_ip}, --private-key ${local.private_key_path} jjp.yaml"

  }


}


output "ec2_global_ips" {
  value = ["${aws_instance.demo.*.public_ip}"]

}

