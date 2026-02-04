resource "aws_instance" "bastion" {
  ami                    = "ami-0b6c6ebed2801a5cb"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.bastion-pub-a.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = "deployment"

  tags = {
    Name = "ec2-bastion"
  }
}

resource "aws_instance" "app" {
  ami                    = "ami-0b6c6ebed2801a5cb"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.app-priv-a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = "deployment"

  tags = {
    Name = "ec2-app"
  }
}

resource "aws_launch_template" "lt-web" {
  name_prefix   = "lt-web"
  image_id      = "ami-0fedcedd25241a683"
  instance_type = "t3.small"
  key_name      = "deployment"

  vpc_security_group_ids = [aws_security_group.app.id]
}

resource "aws_lb_target_group" "tg-web" {
  name     = "tg-web"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.app.id

  health_check {
    protocol = "HTTP"
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_autoscaling_group" "asg-web" {
  name                      = "asg-web"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

  vpc_zone_identifier = [aws_subnet.app-priv-a.id, aws_subnet.app-priv-b.id]

  target_group_arns = [aws_lb_target_group.tg-web.arn]

  launch_template {
    id      = aws_launch_template.lt-web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}  

resource "aws_lb" "lb-app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.app-pub-a.id]

  tags = {
    Environment = "app-lb"
  }
}

resource "aws_lb_listener" "nlb-listener" {
  load_balancer_arn = aws_lb.lb-app.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-web.arn
  }
}
