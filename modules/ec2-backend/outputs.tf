output "load_balancer_dns" {
  value = aws_lb.resume_backend_lb.dns_name
}

