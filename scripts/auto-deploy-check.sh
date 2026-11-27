#!/usr/bin/env bash
# If origin/main has a new fast-forward commit, run deploy-reviews.sh.
# Intended for a systemd timer on the host that serves reviews.zlyxy.me.
#
# Quiet when the live SHA is already current. Logs to stdout (the journal
# when run as a unit). Uses flock so a timer tick and a long deploy cannot overlap.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BRANCH=${BRANCH:-main}
if [ -z "${LOCK:-}" ]; then
  if [ -w /run/lock ]; then
    LOCK=/run/lock/public-data-reviews-deploy.lock
  else
    LOCK=${XDG_RUNTIME_DIR:-/tmp}/public-data-reviews-deploy.lock
  fi
fi
STATE=${STATE:-$REPO/.git/reviews-deployed.sha}
DEPLOY=${DEPLOY:-$REPO/scripts/deploy-reviews.sh}

log() { printf 'auto-deploy: %s\n' "$*"; }
die() { printf 'auto-deploy: ERROR: %s\n' "$*" >&2; exit 1; }

[ -x "$DEPLOY" ] || die "deploy script not found: $DEPLOY"
[ -d "$REPO/.git" ] || die "$REPO is not a git checkout"

exec 9>"$LOCK"
if ! flock -n 9; then
  log "another deploy holds $LOCK; skipping this tick"
  exit 0
fi

cd "$REPO"

if ! git diff --quiet || ! git diff --cached --quiet; then
  die "checkout has uncommitted changes; commit, stash, or deploy manually with --no-pull"
fi

# Never wait on a credential prompt from a systemd unit (use HTTPS, or a
# passphrase-less key, so fetch works without an SSH agent).
export GIT_TERMINAL_PROMPT=0
git fetch -q origin "$BRANCH" || die "git fetch origin $BRANCH failed"

local_sha=$(git rev-parse HEAD)
remote_sha=$(git rev-parse "origin/$BRANCH")
deployed_sha=
[ -f "$STATE" ] && deployed_sha=$(tr -d '[:space:]' <"$STATE")

if [ "$remote_sha" = "$deployed_sha" ]; then
  exit 0
fi

if [ "$local_sha" != "$remote_sha" ] && ! git merge-base --is-ancestor "$local_sha" "$remote_sha"; then
  die "HEAD ($local_sha) is not an ancestor of origin/$BRANCH ($remote_sha); refusing a non-fast-forward deploy"
fi

if [ -n "$deployed_sha" ] && ! git merge-base --is-ancestor "$deployed_sha" "$remote_sha"; then
  die "last deployed $deployed_sha is not an ancestor of origin/$BRANCH ($remote_sha); refusing"
fi

if [ -z "$deployed_sha" ]; then
  log "no recorded live SHA; deploying $(git log -1 --format='%h %s' "$remote_sha") to initialize"
else
  log "origin/$BRANCH moved ${deployed_sha:0:7} -> ${remote_sha:0:7}: $(git log -1 --format='%h %s' "$remote_sha")"
fi

"$DEPLOY"
new_sha=$(git rev-parse HEAD)
[ "$new_sha" = "$remote_sha" ] || die "deploy finished but HEAD is $new_sha, not origin/$BRANCH $remote_sha"
printf '%s\n' "$new_sha" >"$STATE"
log "recorded live SHA $new_sha"
