#!/usr/bin/env bash
# Break-glass: temporarily reopen public SSH from your current IP (for example, to bootstrap a rebuilt
# VM before it's on the tailnet). Close it again with a plain `terraform apply`.
set -euo pipefail
cd "$(dirname "$0")/../infra"
ip=$(curl -s https://api.ipify.org)
echo "Opening SSH from $ip"
terraform apply -auto-approve -var "enable_public_ssh=true" -var "admin_cidr=$ip/32" -target=azurerm_network_security_group.web
