

output "nat_gateway_ip" {
  value = aws_eip.primary_nat_gateway_eip.public_ip
}

output "primary_prom_lb_sgid" {
  value = aws_security_group.primary_prom_lb_sg.id
}

output "primary_graf_lb_sgid" {
  value = aws_security_group.primary_grafana_lb_sg.id
}

output "primary_pub_subnet_id" {
    value = aws_subnet.primary_monitoring_public.id
}

output "primary_pub_subnet_id_1" {
    value = aws_subnet.primary_monitoring_public_1.id
}

output "primary_vpc_id" {
    value = aws_vpc.monitoringvpc.id
}

output "primary_priv1_subnet_id" {
    value = aws_subnet.primary_monitoring_priv1.id
}

output "primary_priv2_subnet_id" {
    value = aws_subnet.primary_monitoring_priv2.id
}

output "primary_prom_instance_sg" {
    value = aws_security_group.primary_prom_priv_sg.id
}

output "primary_prom_node_instance_sg" {
    value = aws_security_group.primary_prom_node_priv_sg.id
}

output "primary_graf_instance_sg" {
    value = aws_security_group.primary_grafana_priv_sg.id
}


output "prom_lb_private_sgid" {
    value = aws_security_group.primary_prom_node_priv_sg.id
}