#!/usr/bin/env bash
# Nightly: snapshot the Gatus database and upload it to Blob Storage.
# Authenticates with the VM's managed identity, so there are no keys on disk.
set -euo pipefail
STORAGE_ACCOUNT=$(grep -m1 "^STORAGE_ACCOUNT=" /etc/opslab.env | cut -d= -f2)
stamp=$(date -u +%Y%m%dT%H%M%SZ)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
sqlite3 /opt/status/gatus-data/data.db ".backup '$tmp/data.db'"   # consistent copy while Gatus runs
tar -czf "$tmp/gatus-$stamp.tar.gz" -C "$tmp" data.db
export AZCOPY_AUTO_LOGIN_TYPE=MSI
# azcopy logs its expected first unauthenticated attempt (401) before signing in; logging off, exit code kept
azcopy copy "$tmp/gatus-$stamp.tar.gz" "https://$STORAGE_ACCOUNT.blob.core.windows.net/backups/gatus-$stamp.tar.gz" --log-level NONE >/dev/null \
  || { echo "upload of gatus-$stamp.tar.gz failed"; exit 1; }
echo "backup uploaded: gatus-$stamp.tar.gz"
