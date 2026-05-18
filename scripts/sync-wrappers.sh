#!/bin/sh
# scripts/sync-wrappers.sh — regenerate wrappers/sshX.sh from install.sh.
#
# install.sh is the source of truth for what gets installed. The files in
# wrappers/ are standalone copies of each function — useful for users who
# want to `. wrappers/sshp.sh` instead of running the installer, and for
# diffing what would change when editing a wrapper.
#
# Run this after editing the emit_fn() block in install.sh.
#
# Usage:
#   sh scripts/sync-wrappers.sh         # regenerate all
#   sh scripts/sync-wrappers.sh sshp    # regenerate just one

set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd)
INSTALL_SH=$REPO/install.sh
WRAPPERS_DIR=$REPO/wrappers

[ -f "$INSTALL_SH" ] || { echo "sync-wrappers: $INSTALL_SH not found" >&2; exit 1; }
[ -d "$WRAPPERS_DIR" ] || mkdir -p "$WRAPPERS_DIR"

# Source ALL_WRAPPERS and emit_fn from install.sh without running the
# imperative install logic. We extract just those two definitions by
# line range — emit_fn() spans from its declaration to the last `^}$`
# before the `# --- args ---` section header.
TMP=$(mktemp -d "${TMPDIR:-/tmp}/sync-wrappers.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

START=$(grep -n -E '^emit_fn' "$INSTALL_SH" | head -1 | cut -d: -f1)
NEXT=$(grep -n -E '^# --- args' "$INSTALL_SH" | head -1 | cut -d: -f1)
END=$(awk -v s="$START" -v n="$NEXT" 'NR>s && NR<n && /^}$/ {last=NR} END{print last}' "$INSTALL_SH")

[ -n "${START:-}" ] && [ -n "${END:-}" ] || {
    echo "sync-wrappers: could not locate emit_fn() in $INSTALL_SH" >&2
    exit 1
}

awk '/^ALL_WRAPPERS=/' "$INSTALL_SH" > "$TMP/all_wrappers.sh"
awk -v s="$START" -v e="$END" 'NR>=s && NR<=e' "$INSTALL_SH" > "$TMP/emit_fn.sh"

# shellcheck disable=SC1091
. "$TMP/all_wrappers.sh"
# shellcheck disable=SC1091
. "$TMP/emit_fn.sh"

# Validate the caller's selection, if any.
SELECTED="$*"
[ -z "$SELECTED" ] && SELECTED="$ALL_WRAPPERS"
for w in $SELECTED; do
    ok=0
    for a in $ALL_WRAPPERS; do [ "$w" = "$a" ] && ok=1 && break; done
    [ "$ok" -eq 1 ] || { echo "sync-wrappers: not a wrapper: $w" >&2; exit 2; }
done

count=0
for w in $SELECTED; do
    emit_fn "$w" > "$WRAPPERS_DIR/$w.sh"
    count=$((count + 1))
done

printf 'sync-wrappers: wrote %d file(s) to %s\n' "$count" "$WRAPPERS_DIR"
