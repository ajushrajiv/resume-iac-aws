output "load_balancer_dns" {
  value = aws_lb.resume_frontend_lb.dns_name
}

