output "environment_url" {
  description = "DNS name of load balancer" 
  value       = module.blog_alb.dns_name
}