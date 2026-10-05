#!/usr/bin/env bash
# Join the VM to my tailnet. The one-time auth key goes from the macOS Keychain straight to
# tailscale on the VM over stdin, so it never lands in a file, shell history, or process list.
# Run once after a (re)build, while public SSH is temporarily open (./scripts/allow-my-ip.sh).
set -euo pipefail
cd "$(dirname "$0")/.."
HOST=${OPSLAB_HOST:-$(terraform -chdir=infra output -raw admin_username)@$(terraform -chdir=infra output -raw fqdn)}
security find-generic-password -s tailscale-authkey-opslab >/dev/null 2>&1 || {
  echo 'No key in Keychain. Save it first: security add-generic-password -a "$USER" -s tailscale-authkey-opslab -U -w'; exit 1; }
security find-generic-password -s tailscale-authkey-opslab -w |
  ssh -i ~/.ssh/opslab_ed25519 -o IdentitiesOnly=yes -o LogLevel=error "$HOST" \
    'sudo tailscale up --auth-key=file:/dev/stdin --hostname=opslab --timeout=60s && tailscale ip -4'
