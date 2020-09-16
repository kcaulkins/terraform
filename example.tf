provider "aws" {
  profile = "${var.profile}"
  region  = "us-east-1"
}

data "aws_availability_zones" "all" {}
# Creating EC2 instance
resource "aws_instance" "${var.app_name}" {
  ami               = "${lookup(var.amis,var.region)}"
  count             = "${var.serverCount}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  source_dest_check = false
  instance_type = "t2.micro"
tags {
    Name = "${format("${var.app_name}_%03d", count.index + 1)}"
  }
}

# Creating Security Group for EC2
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow SSH from office IP
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.office_ip}"]
  }
}

# Creating Launch Configuration
resource "aws_launch_configuration" "${var.app_name}_launch-configuration" {
  image_id               = "${lookup(var.amis,var.region)}"
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.instance.id}"]
  key_name               = "${var.key_name}"
  user_data              = "${file("user_data.sh")}" 
  lifecycle {
    create_before_destroy = true
  }
}
# Creating AutoScaling Group
resource "aws_autoscaling_group" "${var.app_name}_asg" {
  launch_configuration = "${aws_launch_configuration.${var.app_name}_launch-configuration.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  min_size = 2
  max_size = 10
  load_balancers = ["${aws_elb.${var.app_name}_elb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg_${var.app_name}"
    propagate_at_launch = true
  }
}

# Security Group for ELB
resource "aws_security_group" "elb" {
  name = "${var.app_name}_elb-sg"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating ELB
resource "aws_elb" "${var.app_name}_elb" {
  name = "terraform-asg_${var.app_name}"
  security_groups = ["${aws_security_group.elb.id}"]
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 4
    interval = 5
    target = "HTTPS:443/health"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
  listener {
    lb_port = 443
    lb_protocol = "https"
    instance_port = "443"
    instance_protocol = "https"
    ssl_certificate_id = "${var.ssl_cert_arn}"
  }
}

# CodeDeploy app
resource "aws_codedeploy_app" "${var.app_name}_cd" {
  compute_platform = "Server"
  name             = "${var.app_name}_cd"
}