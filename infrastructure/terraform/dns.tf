provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Get the Cloudflare zone ID
data "cloudflare_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

# Create DNS records for the main app
resource "cloudflare_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.cloudflare_zone.main[0].id
  name    = var.app_subdomain != "" ? var.app_subdomain : "@"
  type    = "CNAME"
  content = aws_alb.main.dns_name
  ttl     = 1
  proxied = var.cloudflare_proxy_enabled

  comment = "ALB for ${var.project_name} application"

  depends_on = [aws_alb.main]
}

resource "cloudflare_record" "reverb" {
  count   = var.domain_name != "" && var.enable_websockets ? 1 : 0
  zone_id = data.cloudflare_zone.main[0].id
  name    = var.reverb_subdomain
  type    = "CNAME"
  content = aws_alb.main.dns_name
  ttl     = 1
  proxied = var.cloudflare_proxy_enabled

  comment = "Reverb WebSocket service for ${var.project_name}"

  depends_on = [aws_alb.main]
}