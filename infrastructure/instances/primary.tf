

provider "aws" {
  region = var.primary_region
  alias = "primary"
}

provider "aws" {
  region = var.secondary_region
  alias = "secondary"
}


# ---------------------------primary region---------------------------


resource "aws_key_pair" "primary_monitoring_ssh_key" {
  provider   = aws.primary
  key_name   = "primary_monitoring_ssh_key"
  public_key = file("${path.module}/ssh_key/id_rsa.pub")

}

resource "aws_lb" "primary_monitoring_prom_lb" {
  provider           = aws.primary
  name               = "primary-monitoring-prom-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.prom_lb_sgid]
  subnets            = [var.primary_pub_subnet_id,var.primary_pub_subnet_id_1,var.primary_priv1_subnet_id,var.primary_priv2_subnet_id]
  tags = {
    Name = "primary_monitoring_prom_lb"
  }
}

resource "aws_lb_target_group" "primary_monitoring_prom_lb_tg" {
  provider    = aws.primary
  name        = "primary-monitoring-prom-lb-tg"
  port        = 8080
  target_type = "instance"
  vpc_id      = var.primary_vpc_id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = 8080
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "primary_monitoring_prom_lb_tg"
  }
}

resource "aws_lb_listener" "primary_monitoring_prom_lb_tg_listener_http" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary_monitoring_prom_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary_monitoring_prom_lb_tg.arn
  }
}



resource "aws_launch_configuration" "primary_monitoring_prom_lc" {
  provider          = aws.primary
  name_prefix = "monitoring-prom-lc"
  image_id    = var.prom_ami_id
  instance_type = "t2.micro"
  security_groups = [var.primary_prom_instance_sg]
  iam_instance_profile    = var.asgprofile
  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}


resource "aws_autoscaling_group" "primary_monitoring_prom_asg" {
  name                 = "primary-prom-asg"
  provider          = aws.primary
  launch_configuration = aws_launch_configuration.primary_monitoring_prom_lc.id
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  health_check_type    = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier  = [var.primary_priv1_subnet_id,var.primary_priv2_subnet_id]
  

  tag {
    key                 = "instance_role"
    value               = "prometheus_central_server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "primary_monitoring_prom_asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "primary_monitoring_prom_asg_attachment" {
  provider          = aws.primary
  autoscaling_group_name = aws_autoscaling_group.primary_monitoring_prom_asg.name
  lb_target_group_arn   = aws_lb_target_group.primary_monitoring_prom_lb_tg.arn
}



# ################# prom node autoscaling group
resource "aws_launch_configuration" "primary_monitoring_prom_node_lc" {
  provider          = aws.primary
  name_prefix = "monitoring-prom-node-lc"
  image_id    = var.prom_ami_id
  instance_type = "t2.micro"
  iam_instance_profile    = var.asgprofile
  security_groups = [var.primary_prom_node_instance_sg]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}


resource "aws_autoscaling_group" "primary_monitoring_prom_node_asg" {
  name                 = "primary-prom-node-asg"
  provider          = aws.primary
  launch_configuration = aws_launch_configuration.primary_monitoring_prom_node_lc.id
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  health_check_type    = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier  = [var.primary_priv1_subnet_id,var.primary_priv2_subnet_id]
  tag {
    key                 = "instance_role"
    value               = "prometheus_node_server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "primary_monitoring_prom_node_asg"
    propagate_at_launch = true
  }
}




# for grafana
resource "aws_lb" "primary_monitoring_graf_lb" {
  provider           = aws.primary
  name               = "primary-monitoring-graf-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.graf_lb_sgid]
  subnets            = [var.primary_pub_subnet_id,var.primary_pub_subnet_id_1,var.primary_priv1_subnet_id,var.primary_priv2_subnet_id]
  tags = {
    Name = "primary_monitoring_graf_lb"
  }
}

resource "aws_lb_target_group" "primary_monitoring_graf_lb_tg" {
  provider    = aws.primary
  name        = "primary-monitoring-graf-lb-tg"
  port        = 3000
  target_type = "instance"
  vpc_id      = var.primary_vpc_id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = 3000
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "primary_monitoring_graf_lb_tg"
  }
}

resource "aws_lb_listener" "primary_monitoring_graf_lb_tg_listener_http" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary_monitoring_graf_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary_monitoring_graf_lb_tg.arn
  }
}



resource "aws_launch_configuration" "primary_monitoring_graf_lc" {
  provider          = aws.primary
  name_prefix = "monitoring-graf-lc"
  image_id    = var.graf_ami_id
  iam_instance_profile    = var.asgprofile
  instance_type = "t2.micro"
  security_groups = [var.primary_graf_instance_sg]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p 3000 &
              EOF
}


resource "aws_autoscaling_group" "primary_monitoring_graf_asg" {
  name                 = "primary-graf-asg"
  provider          = aws.primary
  launch_configuration = aws_launch_configuration.primary_monitoring_graf_lc.id
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  health_check_type    = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier  = [var.primary_priv1_subnet_id,var.primary_priv2_subnet_id]
  tag {
    key                 = "instance_role"
    value               = "grafana_node"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "primary_monitoring_graf_asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "primary_monitoring_graf_asg_attachment" {
  provider          = aws.primary
  autoscaling_group_name = aws_autoscaling_group.primary_monitoring_graf_asg.name
  lb_target_group_arn   = aws_lb_target_group.primary_monitoring_graf_lb_tg.arn
}


#----------private lb for prom central servers

resource "aws_lb" "primary_monitoring_prom_private_lb" {
  provider           = aws.primary
  name               = "primary-monitoring-prom-priv-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.prom_lb_private_sgid]
  subnets            = [var.primary_priv1_subnet_id,var.primary_priv2_subnet_id]
  tags = {
    Name = "primary_monitoring_prom_private_lb"
  }
}

resource "aws_lb_target_group" "primary_monitoring_prom_lb_private_tg" {
  provider    = aws.primary
  name        = "primary-mng-prom-lb-priv-tg"
  port        = 8080
  target_type = "instance"
  vpc_id      = var.primary_vpc_id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = 8080
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "primary_monitoring_prom_lb_private_tg"
  }
}

resource "aws_lb_listener" "primary_monitoring_prom_lb_tg_listener_private_http" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary_monitoring_prom_private_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary_monitoring_prom_lb_private_tg.arn
  }
}

resource "aws_autoscaling_attachment" "primary_monitoring_prom_asg_private_attachment" {
  provider          = aws.primary
  autoscaling_group_name = aws_autoscaling_group.primary_monitoring_prom_asg.name
  lb_target_group_arn   = aws_lb_target_group.primary_monitoring_prom_lb_private_tg.arn
}

