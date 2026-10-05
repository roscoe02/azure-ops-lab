#!/usr/bin/env bash
# Push host settings, the status stack, and the backup job to the VM, then (re)start the containers.
# Run from anywhere: ./scripts/deploy.sh   (connects over Tailscale; override with OPSLAB_HOST=user@host)
set -euo pipefail
cd "$(dirname "$0")/.."
HOST=${OPSLAB_HOST:-$(terraform -chdir=infra output -raw ssh_host)}
FQDN=$(terraform -chdir=infra output -raw fqdn)
STATUS_HOST=$(terraform -chdir=infra output -raw status_host 2>/dev/null || true)
SITE_ADDRESS="$FQDN"
# Add the custom name only once its DNS points here, so Caddy doesn't fail certificate requests for it
if [ -n "$STATUS_HOST" ] && [ "$(dig +short "$STATUS_HOST" A | tail -1)" = "$(dig +short "$FQDN" A | tail -1)" ]; then
  SITE_ADDRESS="$STATUS_HOST, $FQDN"   # Caddy gets a certificate for each name
fi
echo "Deploying to $HOST, serving on: $SITE_ADDRESS"
SSH_OPTS=(-i ~/.ssh/opslab_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o LogLevel=error)

rsync -az --delete -e "ssh ${SSH_OPTS[*]}" host/ "$HOST:/tmp/host/"
rsync -az --delete -e "ssh ${SSH_OPTS[*]}" stack/ "$HOST:/opt/status/stack/"
scp -q "${SSH_OPTS[@]}" scripts/backup.sh scripts/opslab-backup.service scripts/opslab-backup.timer "$HOST:/tmp/"
ssh "${SSH_OPTS[@]}" "$HOST" "sudo sed -i 's|^SITE_ADDRESS=.*|SITE_ADDRESS=$SITE_ADDRESS|' /etc/opslab.env"
ssh "${SSH_OPTS[@]}" "$HOST" 'set -e
  sudo /tmp/host/apply.sh "${SSH_CONNECTION%% *}"
  sudo install -m 755 /tmp/backup.sh /usr/local/bin/opslab-backup
  sudo install -m 644 /tmp/opslab-backup.service /tmp/opslab-backup.timer /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now opslab-backup.timer
  cd /opt/status/stack
  docker compose pull -q
  docker compose up -d --remove-orphans --force-recreate
  docker compose ps'
