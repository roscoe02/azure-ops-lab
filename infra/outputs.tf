output "status_page_url" {
  value = "https://${azurerm_public_ip.vm.fqdn}"
}

output "public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "fqdn" {
  value = azurerm_public_ip.vm.fqdn
}

output "admin_username" {
  value = var.admin_username
}

# Admin access is over Tailscale unless public SSH is temporarily enabled
output "ssh_host" {
  value = var.enable_public_ssh ? "${var.admin_username}@${azurerm_public_ip.vm.fqdn}" : "${var.admin_username}@${var.tailnet_hostname}"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/opslab_ed25519 ${var.enable_public_ssh ? "${var.admin_username}@${azurerm_public_ip.vm.fqdn}" : "${var.admin_username}@${var.tailnet_hostname}"}"
}

output "backup_container" {
  value = "https://${azurerm_storage_account.backups.name}.blob.core.windows.net/${azurerm_storage_container.backups.name}"
}

output "status_host" {
  value = "status.${var.domain}"
}
