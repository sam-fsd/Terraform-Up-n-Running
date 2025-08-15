# Configure the AWS Provider
provider "aws" {
  region  = "us-east-2"
}

# Define the port variable for the web server
# Define the port variable for the web server
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080  # Non-standard port to avoid conflicts
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

# Get information about the default VPC
data "aws_vpc" "default" {
  default = true  # Find the default VPC in the region
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Auto Scaling Group to manage multiple instances
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids  # Deploy across all subnets

  target_group_arns = [aws_lb_target_group.asg.arn]  # Register instances with load balancer
  health_check_type = "ELB"  # Use load balancer health checks

  min_size             = 2   # Minimum 2 instances
  max_size             = 10  # Maximum 10 instances

  # Tag all instances in the ASG
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch  = true
  }
}

# Application Load Balancer to distribute traffic
resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"  # Layer 7 load balancer
  subnets            = data.aws_subnets.default.ids  # Deploy across all subnets
  security_groups    = [aws_security_group.alb.id]   # Attach ALB security group
}

# Load balancer listener for HTTP traffic
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80    # Standard HTTP port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Target group for the Auto Scaling Group
resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port  # Port 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  # Health check configuration
  health_check {
    path     = "/"              # Health check endpoint
    protocol = "HTTP"
    matcher  = "200"            # Expect HTTP 200 response
    interval = 15               # Check every 15 seconds
    timeout  = 3                # Wait 3 seconds for response
    healthy_threshold   = 2     # 2 successful checks = healthy
    unhealthy_threshold = 2     # 2 failed checks = unhealthy
  }
}

# Listener rule to forward all traffic to the target group
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100  # Rule priority (lower = higher priority)

  # Match all paths
  condition {
    path_pattern {
      values = ["*"]  # Forward all requests
    }
  }

  # Forward to target group
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
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

# Security group for the Application Load Balancer
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests from anywhere
  ingress {
    from_port   = 80           # Standard HTTP port
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from any IP address
  }

  # Allow all outbound requests (needed for health checks)
  egress {
    from_port   = 0            # All ports
    to_port     = 0
    protocol    = "-1"         # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # To any IP address
  }
}

# Output the load balancer DNS name
output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}