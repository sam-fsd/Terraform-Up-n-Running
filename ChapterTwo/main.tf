# Configure the AWS Provider
provider "aws" {
  region  = "us-east-2"
}

# Define the port variable for the web server
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

# Create a single EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-0fb653ca2d3203ac1"  # Ubuntu 20.04 LTS
  instance_type = "t2.micro"                # Free tier eligible
  vpc_security_group_ids = [aws_security_group.instance.id]

  # Startup script to create a simple web server
  user_data = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.xhtml
        nohup busybox httpd -f -p ${var.server_port} &
        EOF
  user_data_replace_on_change = true

  # Tag the instance for identification
  tags = {
    Name = "terraform-example-instance"
  }
}

# Launch configuration for Auto Scaling Group (used in later chapters)
resource "aws_launch_configuration" "example" {
  image_id = "ami-0fb653ca2d3203ac1"  # Ubuntu 20.04 LTS
  instance_type = "t2.micro"           # Free tier eligible
  security_groups = [aws_security_group.instance.id]

  # Same startup script as the single instance
  user_data = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.xhtml
        nohup busybox httpd -f -p ${var.server_port} &
        EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids

  min_size             = 2
  max_size             = 10

tag {
  key                 = "Name"
  value               = "terraform-asg-example"
  propagate_at_launch  = true
}
}

# Security group to allow HTTP traffic
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  # Allow inbound HTTP traffic from anywhere
  ingress {
    from_port   = var.server_port  # Port 8080
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]    # Allow from any IP address
  }
}

# Output the public IP address of the instance
output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}