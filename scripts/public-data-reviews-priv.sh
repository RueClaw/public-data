#!/usr/bin/env bash
# Allowlist wrapper for the sudo commands in scripts/deploy-reviews.sh.
# Install as root:root 0755 at /usr/local/sbin/public-data-reviews-priv
# (never sudo the copy in the git clone: a push could replace it).
set -euo pipefail

ENV_FILE=${ENV_FILE:-/etc/public-data-reviews.env}
TARGET=${TARGET:-/srv/public-data}
SERVICE=${SERVICE:-public-data-reviews}
BACKUP_DIR=${BACKUP_DIR:-/var/backups/public-data}
CLONE=${CLONE:-/home/zob/src/public-data}

# Exact sed program deploy-reviews.sh uses to read the gateway token.
TOKEN_SED='s/^PUBLIC_DATA_GATEWAY_TOKEN=["'\'']?([^"'\'']*)["'\'']?$/\1/p'

reject() {
  printf 'public-data-reviews-priv: refused:' >&2
  printf ' %q' "$@" >&2
  printf '\n' >&2
  exit 2
}

run() {
  if [ "${PUBLIC_DATA_PRIV_VALIDATE_ONLY:-}" = 1 ]; then
    printf 'ok:'
    printf ' %q' "$@"
    printf '\n'
    exit 0
  fi
  exec "$@"
}

if [ "${PUBLIC_DATA_PRIV_VALIDATE_ONLY:-}" != 1 ]; then
  [ "$(id -u)" -eq 0 ] || { echo "public-data-reviews-priv: must run as root" >&2; exit 1; }
fi
[ $# -ge 1 ] || reject "$@"

cmd=$(basename -- "$1")
shift

backup_ok() {
  local path=$1 base
  base=$(basename -- "$path")
  [[ $path == "$BACKUP_DIR/$base" ]] || return 1
  [[ $base =~ ^srv-public-data-[0-9]{8}-[0-9]{6}\.tgz$ ]] || return 1
}

case "$cmd" in
  test)
    if [ $# -eq 2 ] && [ "$1" = -r ] && [ "$2" = "$ENV_FILE" ]; then
      run /usr/bin/test -r "$ENV_FILE"
    fi
    reject test "$@"
    ;;
  sed)
    if [ $# -eq 3 ] && [ "$1" = -nE ] && [ "$2" = "$TOKEN_SED" ] && [ "$3" = "$ENV_FILE" ]; then
      run /usr/bin/sed -nE "$TOKEN_SED" "$ENV_FILE"
    fi
    reject sed "$@"
    ;;
  systemctl)
    if [ $# -eq 2 ] && [ "$1" = restart ] && [ "$2" = "$SERVICE" ]; then
      run /usr/bin/systemctl restart "$SERVICE"
    fi
    if [ $# -eq 5 ] && [ "$1" = status ] && [ "$2" = "$SERVICE" ] && [ "$3" = --no-pager ] && [ "$4" = -n ] && [ "$5" = 15 ]; then
      run /usr/bin/systemctl status "$SERVICE" --no-pager -n 15
    fi
    reject systemctl "$@"
    ;;
  mkdir)
    if [ $# -eq 2 ] && [ "$1" = -p ] && [ "$2" = "$BACKUP_DIR" ]; then
      run /usr/bin/mkdir -p "$BACKUP_DIR"
    fi
    reject mkdir "$@"
    ;;
  tar)
    if [ $# -eq 5 ] && [ "$1" = -czf ] && [ "$3" = -C ] && [ "$4" = "$(dirname "$TARGET")" ] && [ "$5" = "$(basename "$TARGET")" ]; then
      backup_ok "$2" || reject tar "$@"
      run /usr/bin/tar -czf "$2" -C "$(dirname "$TARGET")" "$(basename "$TARGET")"
    fi
    if [ $# -eq 4 ] && [ "$1" = -xzf ] && [ "$3" = -C ] && [ "$4" = "$(dirname "$TARGET")" ]; then
      backup_ok "$2" || reject tar "$@"
      run /usr/bin/tar -xzf "$2" -C "$(dirname "$TARGET")"
    fi
    reject tar "$@"
    ;;
  rm)
    if [ $# -eq 2 ] && [ "$1" = -rf ] && [ "$2" = "$TARGET.failed" ]; then
      run /usr/bin/rm -rf "$TARGET.failed"
    fi
    if [ $# -ge 2 ] && [ "$1" = -f ]; then
      shift
      for f in "$@"; do
        backup_ok "$f" || reject rm -f "$@"
      done
      run /usr/bin/rm -f "$@"
    fi
    reject rm "$@"
    ;;
  mv)
    if [ $# -eq 2 ] && [ "$1" = "$TARGET" ] && [ "$2" = "$TARGET.failed" ]; then
      run /usr/bin/mv "$TARGET" "$TARGET.failed"
    fi
    reject mv "$@"
    ;;
  chown)
    if [ $# -eq 3 ] && [ "$1" = -R ] && [ "$2" = root:root ] && [ "$3" = "$TARGET" ]; then
      run /usr/bin/chown -R root:root "$TARGET"
    fi
    reject chown "$@"
    ;;
  chmod)
    if [ $# -eq 3 ] && [ "$1" = -R ] && [ "$2" = u+rwX,go+rX,go-w ] && [ "$3" = "$TARGET" ]; then
      run /usr/bin/chmod -R u+rwX,go+rX,go-w "$TARGET"
    fi
    reject chmod "$@"
    ;;
  rsync)
    expected=(
      -a --delete --checksum
      --exclude .git/ --exclude __pycache__/ --exclude '*.py[cod]'
      --exclude review-requests/ --exclude .agents/ --exclude .aws/
      --exclude .codex/ --exclude .env*
    )
    args=("$@")
    n=${#args[@]}
    if [ "$n" -lt 2 ]; then
      reject rsync "$@"
    fi
    src=${args[n-2]}
    dst=${args[n-1]}
    if [ "$src" != "$CLONE/" ] || [ "$dst" != "$TARGET/" ]; then
      reject rsync "$@"
    fi
    flags=("${args[@]:0:n-2}")
    if [ ${#flags[@]} -eq $(( ${#expected[@]} + 2 )) ] && [ "${flags[${#expected[@]}]}" = --dry-run ] && [ "${flags[$((${#expected[@]}+1))]}" = --itemize-changes ]; then
      flags=("${flags[@]:0:${#expected[@]}}")
    fi
    if [ ${#flags[@]} -ne ${#expected[@]} ]; then
      reject rsync "$@"
    fi
    i=0
    for f in "${flags[@]}"; do
      if [ "$f" != "${expected[$i]}" ]; then
        reject rsync "$@"
      fi
      i=$((i + 1))
    done
    run /usr/bin/rsync "$@"
    ;;
  *)
    reject "$cmd" "$@"
    ;;
esac
