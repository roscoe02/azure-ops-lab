#!/usr/bin/env bash
# Nightly, right after the backup: download the newest backup from Blob Storage, restore it to a
# scratch folder, and check that the database is intact and recent. The result is pushed to the
# status page ("Backups: Nightly restore test"), which also turns red if no result arrives in 26 hours.
set -uo pipefail
env_val() { grep -m1 "^$1=" /etc/opslab.env | cut -d= -f2-; }
STORAGE_ACCOUNT=$(env_val STORAGE_ACCOUNT)
TOKEN=$(env_val GATUS_PUSH_TOKEN)
container="https://$STORAGE_ACCOUNT.blob.core.windows.net/backups"
export AZCOPY_AUTO_LOGIN_TYPE=MSI
start=$(date +%s)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

report() {   # report <true|false> <message>
  echo "restore check: $2"
  curl -fsS -o /dev/null -X POST --resolve status.ethanroscoe.com:443:127.0.0.1 \
    -H "Authorization: Bearer $TOKEN" \
    "https://status.ethanroscoe.com/api/v1/endpoints/backups_nightly-restore-test/external?success=$1&duration=$(( $(date +%s) - start ))s&error=$(printf %s "$2" | jq -sRr @uri)" \
    || echo "could not report to the status page"
  [ "$1" = true ]; exit $?
}

latest=$(azcopy list "$container" 2>/dev/null | grep -o 'gatus-[0-9]\{8\}T[0-9]\{6\}Z\.tar\.gz' | sort | tail -1)
[ -n "$latest" ] || report false "no backups found in storage"

# The backup itself must be from the last 26 hours
ts=${latest#gatus-}; ts=${ts%.tar.gz}
age_h=$(( ($(date -u +%s) - $(date -u -d "${ts:0:8} ${ts:9:2}:${ts:11:2}:${ts:13:2}" +%s)) / 3600 ))
[ "$age_h" -le 26 ] || report false "newest backup $latest is ${age_h}h old"

azcopy copy "$container/$latest" "$tmp/$latest" --log-level NONE >/dev/null || report false "download of $latest failed"
tar -xzf "$tmp/$latest" -C "$tmp" || report false "$latest is not a valid archive"

integrity=$(sqlite3 -readonly "$tmp/data.db" "PRAGMA integrity_check;" 2>&1)
[ "$integrity" = ok ] || report false "integrity check failed: $integrity"
rows=$(sqlite3 -readonly "$tmp/data.db" "SELECT count(*) FROM endpoint_results;" 2>&1)
[ "$rows" -gt 0 ] 2>/dev/null || report false "restored database has no check results"

report true "restored $latest: integrity ok, $rows check results"
