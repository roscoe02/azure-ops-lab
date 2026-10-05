#!/usr/bin/env bash
# Idempotent host setup, run by scripts/deploy.sh on every deploy (as root, from /tmp/host).
# Argument: the SSH client IP of the deploy, used to decide when it's safe to close public SSH.
set -euo pipefail
cd "$(dirname "$0")"
client_ip=${1:-}

# Tailscale from its official apt repo, so unattended-upgrades keeps it patched
if ! command -v tailscale >/dev/null; then
  curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg -o /usr/share/keyrings/tailscale-archive-keyring.gpg
  curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list -o /etc/apt/sources.list.d/tailscale.list
  apt-get update -qq
fi
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tailscale auditd debsums apt-show-versions libpam-tmpdir lynis >/dev/null
systemctl enable --now tailscaled auditd >/dev/null

install -m 644 sshd-hardening.conf /etc/ssh/sshd_config.d/99-hardening.conf
install -m 644 issue.net /etc/issue.net
install -m 644 issue.net /etc/issue
sshd -t && systemctl reload-or-restart ssh

install -m 644 sysctl-hardening.conf /etc/sysctl.d/99-hardening.conf
sysctl -q --system
install -m 644 modprobe-blacklist.conf /etc/modprobe.d/opslab-blacklist.conf
echo '* hard core 0' > /etc/security/limits.d/90-no-core.conf

install -m 644 unattended-upgrades-local /etc/apt/apt.conf.d/52unattended-upgrades-local
# Also auto-update Tailscale, not just Ubuntu security updates
cat > /etc/apt/apt.conf.d/53unattended-upgrades-origins <<'CONF'
Unattended-Upgrade::Origins-Pattern { "origin=Tailscale"; };
CONF

install -m 640 audit.rules /etc/audit/rules.d/opslab.rules
augenrules --load >/dev/null

# Gatus runs as uid 1000 (not root) in its container
chown -R 1000:1000 /opt/status/gatus-data

# SSH over the tailnet is always allowed. Public SSH is removed from ufw only once this deploy
# itself arrived over Tailscale (100.64.0.0/10), which proves the tailnet path works.
ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH over Tailscale' >/dev/null
IFS=. read -r a b _ _ <<<"$client_ip"
if [ "${a:-0}" = 100 ] && [ "${b:-0}" -ge 64 ] && [ "${b:-0}" -le 127 ]; then
  ufw delete allow 22/tcp >/dev/null 2>&1 || true
  echo "Public SSH closed in ufw (deploy came over Tailscale)"
fi
