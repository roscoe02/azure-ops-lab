#!/usr/bin/env bash
# Update the SSH firewall rule to your current public IP (run after changing networks).
set -euo pipefail
cd "$(dirname "$0")/../infra"
ip=$(curl -s https://api.ipify.org)
echo "Allowing SSH from $ip"
terraform apply -auto-approve -var "admin_cidr=$ip/32" -target=azurerm_network_security_group.web
