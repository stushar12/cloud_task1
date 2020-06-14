provider "aws" {
  region = "ap-south-1"
  profile = "tushar"
}




resource "tls_private_key" "cloud_task1_key" {
algorithm = "RSA"
}




resource "aws_key_pair" "my_keypair_1" {
key_name = "cloud_task1_key"
public_key = "${tls_private_key.cloud_task1_key.public_key_openssh}"
depends_on = [
tls_private_key.cloud_task1_key
]
}





resource "aws_security_group" "cloud_task1_security_group" {
name = "cloud_task1_security_group"
description = "Allows SSH and HTTP protocol only"
vpc_id = "	vpc-33e1fc5b "

ingress {
description = "SSH protocol"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = [ "0.0.0.0/0" ]
}

ingress {
description = "HTTP protocol"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = [ "0.0.0.0/0" ]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags = {
Name = "cloud_task1_security_group"
}
}





resource "aws_instance" "cloud_task1_instance" {
  ami           = "ami-0bc6c1aaa8f81b239"
  instance_type = "t2.micro"
  key_name= aws_key_pair.my_keypair_1.key_name
  security_groups=[aws_security_group.cloud_task1_security_group.name]

connection {
agent = "false"
type = "ssh"
user = "ec2-user"
private_key = "${tls_private_key.cloud_task1_key.private_key_pem}"
host = "${aws_instance.cloud_task1_instance.public_ip}"
}

provisioner "remote-exec" {
inline = [
"sudo yum install httpd -y",
"sudo yum install git -y",
"sudo systemctl restart httpd",
"sudo systemctl enable httpd",
]
}
tags={
Name="cloud_task1_OS"
}
}






resource "aws_ebs_volume" "my_EBS_1" {
  availability_zone = aws_instance.cloud_task1_instance.availability_zone
  size              = 1

  tags = {
    Name = "my_EBS"
  }
}





resource "aws_volume_attachment" "EBS_attach" {
device_name = "/dev/xvdh"
volume_id   =  aws_ebs_volume.my_EBS_1.id
instance_id = aws_instance.cloud_task1_instance.id
force_detach=true
}





resource "null_resource" "mounting_storage" {
depends_on = [
aws_volume_attachment.EBS_attach,
]
connection {
agent = "false"
type = "ssh"
user = "ec2-user"
private_key = "${tls_private_key.cloud_task1_key.private_key_pem}"
host = "${aws_instance.cloud_task1_instance.public_ip}"
}
provisioner "remote-exec" {
inline = [
"sudo mkfs.ext4 /dev/xvdh",
"sudo mount /dev/xvdh /var/www/html",
"sudo rm -rf /var/www/html/*",
"sudo git clone https://github.com/stushar12/cloud_task1.git /var/www/html"
]
}
}





resource "null_resource" "execute"  {


depends_on = [
    null_resource.mounting_storage,
  ]

	provisioner "local-exec" {
	    command = "chrome  ${aws_instance.cloud_task1_instance.public_ip}/index.html"
  	}
}


