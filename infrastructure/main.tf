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
      name = "grafana-2"
    }
  }

}


module "networking_module" {
    source = "./networking"
}

module "security_module" {
    source = "./security_module"
}


module "instance_module" {
    source = "./instances"
    prom_lb_sgid = module.networking_module.primary_prom_lb_sgid
    primary_pub_subnet_id = module.networking_module.primary_pub_subnet_id
    primary_pub_subnet_id_1 = module.networking_module.primary_pub_subnet_id_1
    primary_vpc_id = module.networking_module.primary_vpc_id
    primary_priv1_subnet_id = module.networking_module.primary_priv1_subnet_id
    primary_priv2_subnet_id = module.networking_module.primary_priv2_subnet_id
    primary_prom_instance_sg = module.networking_module.primary_prom_instance_sg
    primary_graf_instance_sg = module.networking_module.primary_graf_instance_sg
    graf_lb_sgid = module.networking_module.primary_graf_lb_sgid
    primary_prom_node_instance_sg = module.networking_module.primary_prom_node_instance_sg
    prom_lb_private_sgid = module.networking_module.prom_lb_private_sgid
    asgprofile=module.security_module.asg_instance_profile
}