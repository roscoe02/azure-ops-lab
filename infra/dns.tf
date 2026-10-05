# DNS for ethanroscoe.com, managed as code.
#   ethanroscoe.com / www  -> portfolio on GitHub Pages
#   status.ethanroscoe.com -> this Azure VM (Caddy gets its own Let's Encrypt certificate)
#   ask.ethanroscoe.com    -> Cloudflare Worker custom domain, created by wrangler (not managed here)
# Records are DNS-only (not proxied) so GitHub Pages and Caddy can issue their own certificates.

data "cloudflare_zone" "main" {
  filter = { name = var.domain }
}

locals {
  github_pages_ipv4 = ["185.199.108.153", "185.199.109.153", "185.199.110.153", "185.199.111.153"]
  github_pages_ipv6 = ["2606:50c0:8000::153", "2606:50c0:8001::153", "2606:50c0:8002::153", "2606:50c0:8003::153"]
}

resource "cloudflare_dns_record" "apex_a" {
  for_each = toset(local.github_pages_ipv4)
  zone_id  = data.cloudflare_zone.main.zone_id
  name     = var.domain
  type     = "A"
  content  = each.value
  ttl      = 1 # automatic
  proxied  = false
  comment  = "GitHub Pages (portfolio)"
}

resource "cloudflare_dns_record" "apex_aaaa" {
  for_each = toset(local.github_pages_ipv6)
  zone_id  = data.cloudflare_zone.main.zone_id
  name     = var.domain
  type     = "AAAA"
  content  = each.value
  ttl      = 1
  proxied  = false
  comment  = "GitHub Pages (portfolio)"
}

resource "cloudflare_dns_record" "www" {
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "www.${var.domain}"
  type    = "CNAME"
  content = "roscoe02.github.io"
  ttl     = 1
  proxied = false
  comment = "GitHub Pages (portfolio)"
}

resource "cloudflare_dns_record" "status" {
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "status.${var.domain}"
  type    = "A"
  content = azurerm_public_ip.vm.ip_address
  ttl     = 1
  proxied = false
  comment = "Azure VM status page (managed by Terraform)"
}
