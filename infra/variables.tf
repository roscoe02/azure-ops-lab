variable "subscription_id" {
  description = "Azure for Students subscription ID (az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  description = "Azure region. Azure for Students allows only a few regions; Central US is the closest allowed one to DFW."
  type        = string
  default     = "centralus"
}

variable "prefix" {
  description = "Short name used in every resource name"
  type        = string
  default     = "opslab"
}

variable "admin_username" {
  type    = string
  default = "ethan"
}

variable "ssh_public_key_path" {
  description = "Public half of the SSH key dedicated to this VM"
  type        = string
  default     = "~/.ssh/opslab_ed25519.pub"
}

variable "enable_public_ssh" {
  description = "Open SSH to admin_cidr from the internet. Off by default: admin access is over Tailscale. Turn on only to bootstrap a rebuilt VM (scripts/allow-my-ip.sh)."
  type        = bool
  default     = false
}

variable "admin_cidr" {
  description = "Public IP allowed to SSH in when enable_public_ssh is true, as a /32"
  type        = string
  default     = "203.0.113.10/32"
}

variable "tailnet_hostname" {
  description = "The VM's name on my tailnet (MagicDNS)"
  type        = string
  default     = "opslab"
}

variable "vm_size" {
  description = "Standard_B2pts_v2 (Arm64) is covered by the Azure for Students free VM hours and offered in Central US"
  type        = string
  default     = "Standard_B2pts_v2"
}

variable "alert_email" {
  description = "Where Azure Monitor and budget alerts go"
  type        = string
}

variable "monthly_budget_usd" {
  type    = number
  default = 10
}

variable "enable_budget" {
  description = "Some sponsored subscriptions don't support Cost Management budgets; set false if apply rejects it"
  type        = bool
  default     = true
}

variable "trusted_launch" {
  description = "Secure Boot + vTPM. Set false if the chosen size/image rejects Trusted Launch."
  type        = bool
  default     = true
}

variable "domain" {
  description = "Custom domain, registered and hosted on Cloudflare"
  type        = string
  default     = "ethanroscoe.com"
}
