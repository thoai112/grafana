

provider "aws" {
  region = var.primary_region
  alias = "primary"
}

provider "aws" {
  region = var.secondary_region
  alias = "secondary"
}


# ********************************primary region*****************************
data "aws_availability_zones" "azs" {
  provider = aws.primary
  state    = "available"
}


resource "aws_vpc" "monitoringvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  provider = aws.primary
  tags = {
    Name = "monitoringvpc"
  }
}

#Create route table and associations
resource "aws_route_table" "primary_monitoringvpc_internet_route" {
  provider = aws.primary
  vpc_id = resource.aws_vpc.monitoringvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitoring_gw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "primary_monitoringvpc_internet_route"
  }
}

resource "aws_route_table" "primary_monitoringvpc_local_route" {
  provider = aws.primary
  vpc_id = resource.aws_vpc.monitoringvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary_monitoring_nat_gateway.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "primary_monitoringvpc_local_route"
  }
}

resource "aws_route_table_association" "primary_monitoring_pub_assoc" {
  provider = aws.primary
  subnet_id      = resource.aws_subnet.primary_monitoring_public.id
  route_table_id = aws_route_table.primary_monitoringvpc_internet_route.id
}

resource "aws_route_table_association" "primary_monitoring_pub1_assoc" {
  provider = aws.primary
  subnet_id      = resource.aws_subnet.primary_monitoring_public_1.id
  route_table_id = aws_route_table.primary_monitoringvpc_internet_route.id
}

resource "aws_route_table_association" "primary_monitoring_priv1_assoc" {
  provider = aws.primary
  subnet_id      = resource.aws_subnet.primary_monitoring_priv1.id
  route_table_id = aws_route_table.primary_monitoringvpc_local_route.id
}

resource "aws_route_table_association" "primary_monitoring_priv2_assoc" {
  provider = aws.primary
  subnet_id      = resource.aws_subnet.primary_monitoring_priv2.id
  route_table_id = aws_route_table.primary_monitoringvpc_local_route.id
}


# Internet gateway
resource "aws_internet_gateway" "monitoring_gw" {
  vpc_id = resource.aws_vpc.monitoringvpc.id
  provider = aws.primary
  tags = {
    Name = "monitoring_gw"
  }

}

# Nat gateway
resource "aws_eip" "primary_nat_gateway_eip" {
  provider = aws.primary
  vpc = true
}
resource "aws_nat_gateway" "primary_monitoring_nat_gateway" {
  provider = aws.primary
  allocation_id = aws_eip.primary_nat_gateway_eip.id
  subnet_id = aws_subnet.primary_monitoring_public.id
  tags = {
    "Name" = "primary_monitoring_nat_gateway"
  }
}



# Public subnet
resource "aws_subnet" "primary_monitoring_public" {
  provider          = aws.primary
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = resource.aws_vpc.monitoringvpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags ={
    Name = "primary_monitoring_public"
  }
}

resource "aws_subnet" "primary_monitoring_public_1" {
  provider          = aws.primary
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = resource.aws_vpc.monitoringvpc.id
  cidr_block        = "10.0.4.0/24"
  map_public_ip_on_launch = true
  tags ={
    Name = "primary_monitoring_public_1"
  }
}


# Private subnet
resource "aws_subnet" "primary_monitoring_priv1" {
  provider          = aws.primary
  vpc_id     = resource.aws_vpc.monitoringvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = element(data.aws_availability_zones.azs.names, 2)

  tags = {
    Name = "primary_monitoring_priv1"
  }
}

# Private subnet
resource "aws_subnet" "primary_monitoring_priv2" {
  provider          = aws.primary
  vpc_id     = resource.aws_vpc.monitoringvpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = element(data.aws_availability_zones.azs.names, 3)

  tags = {
    Name = "primary_monitoring_priv2"
  }
}


#SG for prom lb
resource "aws_security_group" "primary_prom_lb_sg" {
  provider    = aws.primary
  name        = "primary_prom_lb_sg"
  description = "Allow 443 and 80"
  vpc_id      = resource.aws_vpc.monitoringvpc.id
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#SG for prom private lb
resource "aws_security_group" "primary_prom_priv_lb_sg" {
  provider    = aws.primary
  name        = "primary_prom_priv_lb_sg"
  description = "Allow 443 and 80"
  vpc_id      = resource.aws_vpc.monitoringvpc.id
  ingress {
    description     = "allow traffic from grafana"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_grafana_priv_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#SG for grafana lb
resource "aws_security_group" "primary_grafana_lb_sg" {
  provider    = aws.primary
  name        = "primary_grafana_lb_sg"
  description = "Allow 443 and 80"
  vpc_id      = resource.aws_vpc.monitoringvpc.id
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#SG for prom instances
resource "aws_security_group" "primary_prom_priv_sg" {
  provider    = aws.primary
  name        = "primary_prom_priv_sg"
  description = "allow private access"
  vpc_id      = resource.aws_vpc.monitoringvpc.id
  ingress {
    description = "Allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }
  ingress {
    description     = "allow traffic from LB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_prom_lb_sg.id]
  }
  ingress {
    description     = "allow traffic from LB"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_prom_lb_sg.id]
  }
  ingress {
    description     = "allow traffic from LB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_prom_lb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#SG for prom node instances
resource "aws_security_group" "primary_prom_node_priv_sg" {
  provider    = aws.primary
  name        = "primary_prom_node_priv_sg"
  description = "allow private access"
  vpc_id      = resource.aws_vpc.monitoringvpc.id
  ingress {
    description = "Allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#SG for grafana instances
resource "aws_security_group" "primary_grafana_priv_sg" {
  provider    = aws.primary
  name        = "primary_grafana_priv_sg"
  description = "allow private access"
  vpc_id      = resource.aws_vpc.monitoringvpc.id
  ingress {
    description = "Allow 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }
  ingress {
    description     = "allow traffic from LB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_grafana_lb_sg.id]
  }
  ingress {
    description     = "allow traffic from LB"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_grafana_lb_sg.id]
  }
  ingress {
    description     = "allow traffic from LB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_grafana_lb_sg.id]
  }

  ingress {
    description     = "allow traffic from LB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_grafana_lb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



#SG for efs for prom
resource "aws_security_group" "primary_prom_efs_sg" {
  provider    = aws.primary
  name        = "primary_prom_efs_sg"
  description = "allow private access"
  vpc_id      = resource.aws_vpc.monitoringvpc.id

  # ingress from all instance sgs
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    security_groups = [aws_security_group.primary_prom_priv_sg.id,aws_security_group.primary_prom_node_priv_sg.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#SG for efs for grafana
resource "aws_security_group" "primary_graf_efs_sg" {
  provider    = aws.primary
  name        = "primary_graf_efs_sg"
  description = "allow private access"
  vpc_id      = resource.aws_vpc.monitoringvpc.id

  # ingress from all instance sgs
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    security_groups = [aws_security_group.primary_grafana_priv_sg.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# efs for prom
resource "aws_efs_file_system" "primary_prom_efs" {
  provider    = aws.primary
  creation_token = "primary_prom_efs"
  tags = {
    Name = "primary_prom_efs"
  }
}

resource "aws_efs_mount_target" "primary_prom_mnt_priv1" {
  file_system_id  = aws_efs_file_system.primary_prom_efs.id
  subnet_id       = aws_subnet.primary_monitoring_priv1.id
  security_groups = [aws_security_group.primary_prom_efs_sg.id]
}
resource "aws_efs_mount_target" "primary_prom_mnt_priv2" {
  file_system_id  = aws_efs_file_system.primary_prom_efs.id
  subnet_id       = aws_subnet.primary_monitoring_priv2.id
  security_groups = [aws_security_group.primary_prom_efs_sg.id]
}






# efs for graf
resource "aws_efs_file_system" "primary_graf_efs" {
  provider    = aws.primary
  creation_token = "primary_graf_efs"
  tags = {
    Name = "primary_graf_efs"
  }
}

resource "aws_efs_mount_target" "primary_graf_mnt_priv1" {
  file_system_id  = aws_efs_file_system.primary_graf_efs.id
  subnet_id       = aws_subnet.primary_monitoring_priv1.id
  security_groups = [aws_security_group.primary_graf_efs_sg.id]
}
resource "aws_efs_mount_target" "primary_graf_mnt_priv2" {
  file_system_id  = aws_efs_file_system.primary_graf_efs.id
  subnet_id       = aws_subnet.primary_monitoring_priv2.id
  security_groups = [aws_security_group.primary_graf_efs_sg.id]
}


# ********************************primary region*****************************