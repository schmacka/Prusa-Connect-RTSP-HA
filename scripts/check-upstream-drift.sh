#!/usr/bin/env bash
#
# Detect upstream drift without ever touching the add-on's own source.
#
# prusa_connect_rtsp/main.py started life as a copy of upstream's main.py but has
# diverged substantially: it carries repo-local fixes (forced FFMPEG backend,
# startup connection retry, offline back-off) that upstream does not have. An
# automated copy of upstream over that file reverts all of them, so nothing here
# writes to prusa_connect_rtsp/ at all.
#
# Instead upstream/ holds a pristine, byte-exact snapshot of the upstream
# revision we last reviewed. This script compares live upstream against that
# snapshot and reports what changed, leaving the port into
# prusa_connect_rtsp/main.py as a deliberate human merge.
#
# Exit codes:
#   0  snapshot matches upstream — nothing to do
#   1  upstream has moved — a human needs to review and port
#   2  error (fetch failed, bad arguments, or the safety guard tripped)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT_DIR="$REPO_ROOT/upstream"
PROTECTED_DIR="prusa_connect_rtsp"

UPSTREAM_REPO="Knopersikcuo/Prusa-Connect-RTSP"
UPSTREAM_RAW="https://raw.githubusercontent.com/$UPSTREAM_REPO/main"
UPSTREAM_API="https://api.github.com/repos/$UPSTREAM_REPO/commits/main"

# Files we track from upstream. These are snapshot paths, never add-on paths.
TRACKED_FILES=(main.py requirements.txt)

update_snapshot=0
from_dir=""
summary_file=""

die() { printf 'error: %s\n' "$*" >&2; exit 2; }

usage() {
  cat <<'USAGE'
Usage: scripts/check-upstream-drift.sh [options]

  --update-snapshot    Advance upstream/ to the fetched revision. Use only when
                       the diff has been reviewed and any needed changes have
                       been ported into prusa_connect_rtsp/ by hand.
  --from-dir DIR       Read upstream files from DIR instead of the network.
                       Lets you dry-run this script offline.
  --summary-file FILE  Append the Markdown report to FILE (for
                       $GITHUB_STEP_SUMMARY).
  -h, --help           Show this help.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --update-snapshot) update_snapshot=1; shift ;;
    --from-dir) [ $# -ge 2 ] || die "--from-dir needs a directory"; from_dir="$2"; shift 2 ;;
    --summary-file) [ $# -ge 2 ] || die "--summary-file needs a path"; summary_file="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unknown argument: $1" ;;
  esac
done

[ -d "$SNAPSHOT_DIR" ] || die "snapshot directory missing: $SNAPSHOT_DIR"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# ---------------------------------------------------------------------------
# Collect the current upstream files into $work_dir. Nothing is written outside
# it until the snapshot is explicitly advanced.
# ---------------------------------------------------------------------------
upstream_rev="unknown"

if [ -n "$from_dir" ]; then
  [ -d "$from_dir" ] || die "--from-dir is not a directory: $from_dir"
  for f in "${TRACKED_FILES[@]}"; do
    [ -f "$from_dir/$f" ] || die "--from-dir is missing $f"
    cp "$from_dir/$f" "$work_dir/$f"
  done
  [ -f "$from_dir/UPSTREAM_REV" ] && upstream_rev="$(tr -d '[:space:]' < "$from_dir/UPSTREAM_REV")"
  printf 'Using upstream files from %s (revision: %s)\n' "$from_dir" "$upstream_rev"
else
  for f in "${TRACKED_FILES[@]}"; do
    curl -sSfL "$UPSTREAM_RAW/$f" -o "$work_dir/$f" \
      || die "could not fetch $f from $UPSTREAM_RAW"
    # A repo that has moved or renamed a file can answer 200 with an error page.
    [ -s "$work_dir/$f" ] || die "fetched $f is empty — has upstream moved it?"
  done
  upstream_rev="$(curl -sSfL "$UPSTREAM_API" \
    | sed -n 's/^[[:space:]]*"sha"[[:space:]]*:[[:space:]]*"\([0-9a-f]\{7,40\}\)".*/\1/p' \
    | head -n 1)"
  [ -n "$upstream_rev" ] || upstream_rev="unknown"
  printf 'Fetched upstream %s at revision %s\n' "$UPSTREAM_REPO" "$upstream_rev"
fi

# ---------------------------------------------------------------------------
# Compare against the reviewed snapshot.
# ---------------------------------------------------------------------------
drifted=()
for f in "${TRACKED_FILES[@]}"; do
  if [ ! -f "$SNAPSHOT_DIR/$f" ]; then
    drifted+=("$f")
  elif ! cmp -s "$work_dir/$f" "$SNAPSHOT_DIR/$f"; then
    drifted+=("$f")
  fi
done

report="$work_dir/report.md"
snapshot_rev="unknown"
[ -f "$SNAPSHOT_DIR/UPSTREAM_REV" ] && snapshot_rev="$(tr -d '[:space:]' < "$SNAPSHOT_DIR/UPSTREAM_REV")"

if [ ${#drifted[@]} -eq 0 ]; then
# The report is Markdown, so the single-quoted printf formats below are full of
# backticks that must reach the output verbatim.
# shellcheck disable=SC2016
  {
    printf '## Upstream sync: no drift\n\n'
    printf '`upstream/` already matches `%s` at `%s`.\n' "$UPSTREAM_REPO" "$upstream_rev"
  } > "$report"
else
# The report is Markdown, so the single-quoted printf formats below are full of
# backticks that must reach the output verbatim.
# shellcheck disable=SC2016
  {
    printf '## Upstream sync: drift detected\n\n'
    printf 'Upstream `%s` has moved since the snapshot was last reviewed.\n\n' "$UPSTREAM_REPO"
    printf '| | revision |\n|---|---|\n'
    printf '| reviewed snapshot | `%s` |\n' "$snapshot_rev"
    printf '| current upstream | `%s` |\n\n' "$upstream_rev"
    printf 'Changed files: %s\n\n' "$(printf '`%s` ' "${drifted[@]}")"
    printf '> **`prusa_connect_rtsp/` was not modified and must not be overwritten\n'
    printf '> from upstream.** `prusa_connect_rtsp/main.py` has diverged and carries\n'
    printf '> local fixes (forced FFMPEG backend, startup connection retry, offline\n'
    printf '> back-off) that upstream does not have. Port anything useful by hand.\n\n'
    for f in "${drifted[@]}"; do
      printf '<details><summary>Diff for <code>%s</code> (reviewed snapshot → current upstream)</summary>\n\n' "$f"
      printf '```diff\n'
      diff -u "$SNAPSHOT_DIR/$f" "$work_dir/$f" \
        --label "upstream/$f (reviewed $snapshot_rev)" \
        --label "upstream/$f ($upstream_rev)" || true
      printf '```\n\n</details>\n\n'
    done
  } > "$report"
fi

cat "$report"
if [ -n "$summary_file" ]; then
  cat "$report" >> "$summary_file"
fi

# ---------------------------------------------------------------------------
# Advance the snapshot only when asked.
# ---------------------------------------------------------------------------
if [ "$update_snapshot" -eq 1 ] && [ ${#drifted[@]} -gt 0 ]; then
  for f in "${TRACKED_FILES[@]}"; do
    cp "$work_dir/$f" "$SNAPSHOT_DIR/$f"
  done
  printf '%s\n' "$upstream_rev" > "$SNAPSHOT_DIR/UPSTREAM_REV"
  printf '\nSnapshot advanced to %s.\n' "$upstream_rev"
fi

# ---------------------------------------------------------------------------
# Safety guard. This is the whole point of the script: whatever happened above,
# the add-on's own sources must be untouched. Fail loudly rather than let an
# overwrite reach a pull request.
# ---------------------------------------------------------------------------
if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  touched="$(git -C "$REPO_ROOT" status --porcelain -- "$PROTECTED_DIR")"
  if [ -n "$touched" ]; then
    printf '\n' >&2
    printf 'error: this run modified protected files under %s/:\n' "$PROTECTED_DIR" >&2
    printf '%s\n' "$touched" >&2
    printf 'Upstream syncing must never write to the add-on sources. Aborting.\n' >&2
    exit 2
  fi
  printf 'Guard: %s/ is untouched.\n' "$PROTECTED_DIR"
fi

[ ${#drifted[@]} -eq 0 ] && exit 0
exit 1
