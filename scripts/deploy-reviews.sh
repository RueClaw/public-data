#!/usr/bin/env bash
# Update and restart the reviews web service (reviews.zlyxy.me) from this checkout.
#
# Run on the host that serves the site (nautilus), from a git clone of this repo:
#   ~/src/public-data/scripts/deploy-reviews.sh            # pull, test, deploy, restart, verify
#   ~/src/public-data/scripts/deploy-reviews.sh --no-pull  # deploy the checkout as-is
#   ~/src/public-data/scripts/deploy-reviews.sh --restart  # just restart and health-check
#   ~/src/public-data/scripts/deploy-reviews.sh --dry-run  # show what would change
#
# Backs up the live copy first and rolls back automatically if the health check fails.
# Never touches the request queue (/var/lib/public-data) or the env file (/etc/public-data-reviews.env).
set -euo pipefail

TARGET=${TARGET:-/srv/public-data}
SERVICE=${SERVICE:-public-data-reviews}
ENV_FILE=${ENV_FILE:-/etc/public-data-reviews.env}
BACKUP_DIR=${BACKUP_DIR:-/var/backups/public-data}
KEEP_BACKUPS=${KEEP_BACKUPS:-5}
BRANCH=${BRANCH:-main}

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PULL=1 DRY=0 RESTART_ONLY=0
for arg in "$@"; do
  case $arg in
    --no-pull) PULL=0 ;;
    --dry-run) DRY=1 ;;
    --restart) RESTART_ONLY=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

log() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# Read bind address, port and public origin from the installed unit so this works on any host.
unit_exec=$(systemctl show -p ExecStart --value "$SERVICE" 2>/dev/null || true)
[ -n "$unit_exec" ] || die "systemd unit $SERVICE not found"
opt() { sed -nE "s/.*--$1[ =]([^ ;]+).*/\1/p" <<<"$unit_exec" | head -1; }
HOST=$(opt host); PORT=$(opt port); ORIGIN=$(opt public-origin)
HOST=${HOST:-127.0.0.1}; PORT=${PORT:-8765}
VHOST=${ORIGIN#https://}; VHOST=${VHOST#http://}; VHOST=${VHOST:-127.0.0.1:$PORT}

health() {
  # The app requires the private gateway header; read it as root without printing it.
  local hdr=()
  if sudo test -r "$ENV_FILE"; then
    local tok
    tok=$(sudo sed -nE 's/^PUBLIC_DATA_GATEWAY_TOKEN=["'\'']?([^"'\'']*)["'\'']?$/\1/p' "$ENV_FILE" | tail -1)
    [ -n "$tok" ] && hdr=(-H "X-Public-Data-Gateway: $tok")
  fi
  curl -fsS -m 5 -o /dev/null -H "Host: $VHOST" "${hdr[@]}" "http://$HOST:$PORT/api/health"
}

restart_and_check() {
  log "Restarting $SERVICE"
  sudo systemctl restart "$SERVICE"
  for _ in $(seq 1 15); do
    if health 2>/dev/null; then log "Healthy: http://$HOST:$PORT/api/health (Host: $VHOST)"; return 0; fi
    sleep 1
  done
  sudo systemctl status "$SERVICE" --no-pager -n 15 || true
  return 1
}

if [ "$RESTART_ONLY" = 1 ]; then
  restart_and_check || die "$SERVICE did not come back healthy"
  exit 0
fi

[ -d "$REPO/.git" ] || die "$REPO is not a git checkout"
cd "$REPO"

if [ "$PULL" = 1 ]; then
  git diff --quiet && git diff --cached --quiet || die "checkout has uncommitted changes; commit/stash or use --no-pull"
  log "Pulling origin/$BRANCH"
  git fetch -q origin "$BRANCH"
  git checkout -q "$BRANCH"
  git merge -q --ff-only "origin/$BRANCH"
fi
log "Deploying $(git log -1 --format='%h %s')"

log "Running tests"
for t in scripts/test_review_web.py scripts/test_library_agent.py; do
  [ -f "$t" ] || continue
  PYTHONDONTWRITEBYTECODE=1 python3 "$t" || die "$t failed; nothing deployed"
done

RSYNC=(rsync -a --delete --checksum
  --exclude .git/ --exclude __pycache__/ --exclude '*.py[cod]'
  --exclude review-requests/ --exclude .agents/ --exclude .aws/ --exclude .codex/ --exclude .env*)

if [ "$DRY" = 1 ]; then
  log "Dry run: changes that would be made to $TARGET"
  sudo "${RSYNC[@]}" --dry-run --itemize-changes "$REPO/" "$TARGET/"
  exit 0
fi

if ! diff -q deploy/public-data-reviews.service <(systemctl cat "$SERVICE" 2>/dev/null | sed 1d) >/dev/null; then
  log "Note: deploy/public-data-reviews.service differs from the installed unit (expected for host/origin); not changed."
fi

ts=$(date +%Y%m%d-%H%M%S)
backup="$BACKUP_DIR/srv-public-data-$ts.tgz"
log "Backing up $TARGET to $backup"
sudo mkdir -p "$BACKUP_DIR"
sudo tar -czf "$backup" -C "$(dirname "$TARGET")" "$(basename "$TARGET")"
ls -1t "$BACKUP_DIR"/srv-public-data-*.tgz 2>/dev/null | tail -n +$((KEEP_BACKUPS + 1)) | xargs -r sudo rm -f

log "Syncing code to $TARGET"
sudo "${RSYNC[@]}" "$REPO/" "$TARGET/"
sudo chown -R root:root "$TARGET"
sudo chmod -R u+rwX,go+rX,go-w "$TARGET"

if ! restart_and_check; then
  log "Health check failed; rolling back to $backup"
  sudo rm -rf "$TARGET.failed" && sudo mv "$TARGET" "$TARGET.failed"
  sudo tar -xzf "$backup" -C "$(dirname "$TARGET")"
  restart_and_check || die "rollback also failed; check: journalctl -u $SERVICE"
  die "deploy failed and was rolled back; the bad copy is in $TARGET.failed"
fi
log "Done"
