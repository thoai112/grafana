
variable "secondary_region"{
    default="us-east-2"
}

variable "primary_region"{
    default="us-east-1"
}


variable "access_ip"{
    default="0.0.0.0/0"
}

variable "prom_lb_sgid" {
    default=""
}

variable "prom_lb_private_sgid" {
    default=""
}



variable "graf_lb_sgid" {
    default=""
}


variable "primary_pub_subnet_id" {
    default=""
}

variable "primary_pub_subnet_id_1" {
    default=""
}

variable "primary_priv1_subnet_id" {
    default=""
}

variable "primary_priv2_subnet_id" {
    default=""
}

variable "primary_vpc_id" {
    default = ""
}


variable "prom_ami_id" {
    default = "ami-0cb8f467994974625"
}

variable "graf_ami_id" {
    default = "ami-03889cb338fd2e61a"
}

variable "primary_prom_instance_sg" {
    default = ""
}

variable "primary_prom_node_instance_sg" {
    default = ""
}



variable "primary_graf_instance_sg" {
    default = ""
}


variable "asgprofile" {
    default = ""
}