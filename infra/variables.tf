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

variable "admin_cidr" {
  description = "Public IP allowed to SSH in, as a /32 (your home IP). Update and re-apply if it changes."
  type        = string
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
