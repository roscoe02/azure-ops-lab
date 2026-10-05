#!/usr/bin/env bash
# Push the status stack and backup job to the VM, then (re)start the containers.
# Run from anywhere: ./scripts/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."
HOST=$(terraform -chdir=infra output -raw ssh_command | awk '{print $2}')
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)

rsync -az --delete -e "ssh ${SSH_OPTS[*]}" stack/ "$HOST:/opt/status/stack/"
scp "${SSH_OPTS[@]}" scripts/backup.sh scripts/opslab-backup.service scripts/opslab-backup.timer "$HOST:/tmp/"
ssh "${SSH_OPTS[@]}" "$HOST" 'set -e
  sudo install -m 755 /tmp/backup.sh /usr/local/bin/opslab-backup
  sudo install -m 644 /tmp/opslab-backup.service /tmp/opslab-backup.timer /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable --now opslab-backup.timer
  cd /opt/status/stack
  docker compose pull -q
  docker compose up -d --remove-orphans
  docker compose ps'
