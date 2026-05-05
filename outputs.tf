output "vpc_id" {
  value = aws_vpc.main.id
}
output "web_server_public_ip" {
  value = aws_instance.web.public_ip
}
output "web_server_public_dns" {
  value = aws_instance.web.public_dns
}
output "app_server_private_ip" {
  value = aws_instance.app.private_ip
}
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}
