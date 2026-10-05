variable "subscription_id" {
  description = "Azure for Students subscription ID (az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  description = "Azure region. South Central US (San Antonio) is closest to DFW."
  type        = string
  default     = "southcentralus"
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
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "admin_cidr" {
  description = "Public IP allowed to SSH in, as a /32 (your home IP). Update and re-apply if it changes."
  type        = string
}

variable "vm_size" {
  description = "Standard_B2ats_v2 is covered by the Azure for Students free VM hours"
  type        = string
  default     = "Standard_B2ats_v2"
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
