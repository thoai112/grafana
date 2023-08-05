terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.9.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "3.4.0"
    }
  }

cloud {
    organization = "kuratajr"

    workspaces {
      name = "grafana"
    }
  }

}


provider "aws" {
  region = var.primary_region
  alias = "primary"
}


resource "aws_vpc" "amitempvpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "amitempvpc"
  }
}

resource "aws_internet_gateway" "amitemp_gw" {
  vpc_id = resource.aws_vpc.amitempvpc.id
  provider   = aws.primary

  tags = {
    Name = "amitemp_gw"
  }

}

resource "aws_security_group" "amitemp_sg" {
  name        = "amitemp_sg"
  description = "sg for ami temp"
  vpc_id      = resource.aws_vpc.amitempvpc.id
  provider   = aws.primary

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 9090
    to_port    = 9090
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 6443
    to_port    = 6443
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 3000
    to_port    = 3000
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "amitemp_sg"
  }
}

resource "aws_route_table" "amitemp_rt" {
  vpc_id = resource.aws_vpc.amitempvpc.id
  provider   = aws.primary

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = resource.aws_internet_gateway.amitemp_gw.id
  }

  tags = {
    Name = "amitemp_rt"
  }
}

resource "aws_subnet" "amitemp_subnet" {
  provider   = aws.primary
  vpc_id     = resource.aws_vpc.amitempvpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "amitemp_subnet"
  }
}

resource "aws_route_table_association" "amitemp_kube_subnet_assoc" {
  provider   = aws.primary
  subnet_id      = resource.aws_subnet.amitemp_subnet.id
  route_table_id = resource.aws_route_table.amitemp_rt.id
}



resource "aws_key_pair" "amitemp_ssh_key" {
  provider   = aws.primary
  key_name   = "amitemp_ssh_key"
  public_key = file("${path.module}/ssh_key/id_rsa.pub")

}

data "aws_iam_policy_document" "amitemp-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cust_amitemp_access" {
  statement {
    actions   = ["logs:*","s3:*","dynamodb:*","cloudwatch:*","sns:*","lambda:*","connect:*","secretsmanager:*","ds:*","ec2:*"]
    effect   = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "custamitemprole" {
    name               = "custamitemprole"
    assume_role_policy = data.aws_iam_policy_document.amitemp-assume-role-policy.json
    inline_policy {
        name   = "policy-867530233"
        policy = data.aws_iam_policy_document.cust_amitemp_access.json
    }

}

resource "aws_iam_instance_profile" "custamitempprofile" {
  name = "custamitempprofile"
  role = "${aws_iam_role.custamitemprole.name}"
}

resource "aws_network_interface" "amitemp_instance_eni" {
  subnet_id       = resource.aws_subnet.amitemp_subnet.id
  security_groups = [resource.aws_security_group.amitemp_sg.id]

  
}
resource "aws_instance" "amitemp_instance" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = resource.aws_network_interface.amitemp_instance_eni.id
    device_index         = 0
  }
  availability_zone = "us-east-1a"
  key_name = resource.aws_key_pair.amitemp_ssh_key.key_name
  iam_instance_profile = resource.aws_iam_instance_profile.custamitempprofile.name

  tags= {
    Name = "amitemp_ec2"
  }



}

resource "aws_s3_bucket" "cntralpromconfigbucket" {
  bucket = var.cntralpromconfigbucket
  acl    = "private"

  tags = {
    Name        = "cntralpromconfigbucket"
  }
}

resource "aws_s3_bucket_object" "cntralpromconfig" {
  bucket = var.cntralpromconfigbucket
  key    = "prometheus.yml"
  source ="${path.module}/prometheus.yml"
  depends_on = [
    aws_s3_bucket.cntralpromconfigbucket
  ]
}

resource "aws_s3_bucket_object" "grafanaconfig" {
  bucket = var.cntralpromconfigbucket
  key    = "grafana.ini"
  source ="${path.module}/grafana.ini"
  depends_on = [
    aws_s3_bucket.cntralpromconfigbucket
  ]
}