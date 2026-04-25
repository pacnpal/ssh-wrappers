#!/bin/sh
# install.sh — install ssh-wrappers shell functions into the user's shell rc file.
#
# Usage:
#   sh install.sh                       # install all wrappers (default)
#   sh install.sh sshp sshk             # install only the named wrappers
#   sh install.sh --force               # install anyway, even if a managed
#                                       # block already exists or definitions
#                                       # would shadow your own
#   sh install.sh --uninstall           # remove the managed block
#   sh install.sh --list                # print available wrappers and exit
#
#   curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh
#   curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- sshp sshk
#   curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --force sshp
#   curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --uninstall
#
# Override the target rc file:
#   SSH_WRAPPERS_RC=~/.zprofile sh install.sh

set -eu

BEGIN_MARKER='# >>> ssh-wrappers >>>'
END_MARKER='# <<< ssh-wrappers <<<'

ALL_WRAPPERS="sshp sshi ssha sshq sshk sshm ssht sshc sshv"

# Print a single function definition. Any change here is the source of truth.
emit_fn() {
    case "$1" in
        sshp) cat <<'EOF'
# sshp — force password authentication (disable pubkey for one connection)
sshp() {
    ssh -o PubkeyAuthentication=no "$@"
}
EOF
            ;;
        sshi) cat <<'EOF'
# sshi — use only explicitly configured identities (IdentitiesOnly=yes)
sshi() {
    ssh -o IdentitiesOnly=yes "$@"
}
EOF
            ;;
        sshq) cat <<'EOF'
# sshq — quiet/quick: skip host key prompts and don't pollute known_hosts.
# Use for ephemeral hosts (cloud VMs, CI runners, lab gear). NOT for prod —
# this disables a real protection against man-in-the-middle attacks.
sshq() {
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$@"
}
EOF
            ;;
        sshk) cat <<'EOF'
# sshk — keepalive: send a probe every 30s, drop after 4 missed probes.
# Stops "client_loop: send disconnect: Broken pipe" on idle sessions.
sshk() {
    ssh -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=4 \
        -o TCPKeepAlive=yes \
        "$@"
}
EOF
            ;;
        sshm) cat <<'EOF'
# sshm — multiplex: first connection opens a master, subsequent connections
# to the same host:port:user reuse it for ~instant attach. Master persists
# 10 minutes after the last client exits.
sshm() {
    ssh -o ControlMaster=auto \
        -o ControlPath="$HOME/.ssh/cm-%r@%h:%p" \
        -o ControlPersist=10m \
        "$@"
}
EOF
            ;;
        ssht) cat <<'EOF'
# ssht — force a pseudo-terminal. Needed for interactive remote commands
# like sudo, htop, vim when run as `ssh host <cmd>`.
ssht() {
    ssh -t "$@"
}
EOF
            ;;
        ssha) cat <<'EOF'
# ssha — forward your local ssh-agent to the remote host so commands
# there (e.g. `git push`) can use your local keys without copying them.
# Only do this on hosts you trust — agent forwarding lets root on the
# remote impersonate you to anywhere your keys can reach.
ssha() {
    ssh -A "$@"
}
EOF
            ;;
        sshc) cat <<'EOF'
# sshc — enable compression. Worth it on slow / high-latency links and
# for transferring lots of text (logs, stdout from remote builds).
# Wasteful on fast LANs and for already-compressed data.
sshc() {
    ssh -C "$@"
}
EOF
            ;;
        sshv) cat <<'EOF'
# sshv — verbose debug (-vvv). Use when ssh isn't connecting and you
# need to see auth method offers, key matching, kex/cipher negotiation.
sshv() {
    ssh -vvv "$@"
}
EOF
            ;;
        *)
            printf 'ssh-wrappers: unknown wrapper: %s\n' "$1" >&2
            return 1
            ;;
    esac
}

# --- args ---
MODE=install
FORCE=${SSH_WRAPPERS_FORCE:-0}
SELECTED=
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=1 ;;
        --uninstall|-u) MODE=uninstall ;;
        --list|-l) MODE=list ;;
        --help|-h) MODE=help ;;
        --) ;;
        --*)
            printf 'ssh-wrappers: unknown flag: %s\n' "$arg" >&2
            exit 2
            ;;
        ssh*)
            # validate against the allowlist
            ok=0
            for w in $ALL_WRAPPERS; do
                if [ "$arg" = "$w" ]; then ok=1; break; fi
            done
            if [ "$ok" -ne 1 ]; then
                printf 'ssh-wrappers: not a wrapper name: %s (try --list)\n' "$arg" >&2
                exit 2
            fi
            SELECTED="${SELECTED}${arg} "
            ;;
        *)
            printf 'ssh-wrappers: unrecognized argument: %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done

if [ "$MODE" = help ]; then
    sed -n '2,21p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'
    exit 0
fi

if [ "$MODE" = list ]; then
    printf 'Available wrappers (default install: all):\n'
    for w in $ALL_WRAPPERS; do
        printf '  %s\n' "$w"
    done
    exit 0
fi

# Default to "install everything" when no positional names are given.
[ -z "$SELECTED" ] && SELECTED="$ALL_WRAPPERS"

detect_rc() {
    if [ -n "${SSH_WRAPPERS_RC:-}" ]; then
        printf '%s\n' "$SSH_WRAPPERS_RC"
        return
    fi

    shell_name=$(basename "${SHELL:-/bin/sh}")
    case "$shell_name" in
        zsh)
            printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc"
            ;;
        bash)
            # macOS bash users typically use .bash_profile; Linux uses .bashrc.
            if [ "$(uname -s)" = "Darwin" ] && [ -f "$HOME/.bash_profile" ]; then
                printf '%s\n' "$HOME/.bash_profile"
            else
                printf '%s\n' "$HOME/.bashrc"
            fi
            ;;
        ksh)
            printf '%s\n' "$HOME/.kshrc"
            ;;
        fish)
            printf 'unsupported:fish\n'
            ;;
        *)
            printf '%s\n' "$HOME/.profile"
            ;;
    esac
}

RC_FILE=$(detect_rc)

case "$RC_FILE" in
    unsupported:fish)
        cat >&2 <<'EOF'
ssh-wrappers: fish shell is not supported by this installer.
Fish uses a different function syntax. Add what you need to ~/.config/fish/config.fish:

    function sshp ; ssh -o PubkeyAuthentication=no $argv ; end
    function sshi ; ssh -o IdentitiesOnly=yes $argv ; end
    function ssha ; ssh -A $argv ; end
    function sshq ; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $argv ; end
    function sshk ; ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=4 -o TCPKeepAlive=yes $argv ; end
    function sshm ; ssh -o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-%r@%h:%p -o ControlPersist=10m $argv ; end
    function ssht ; ssh -t $argv ; end
    function sshc ; ssh -C $argv ; end
    function sshv ; ssh -vvv $argv ; end
EOF
        exit 1
        ;;
esac

# Build the managed block from SELECTED.
build_block() {
    printf '%s\n' "$BEGIN_MARKER"
    printf '# https://github.com/pacnpal/ssh-wrappers\n'
    for w in $SELECTED; do
        printf '\n'
        emit_fn "$w"
    done
    printf '%s\n' "$END_MARKER"
}

# Remove the managed block in-place via temp file (POSIX sed -i is non-portable).
remove_block() {
    file=$1
    if ! grep -Fq "$BEGIN_MARKER" "$file" 2>/dev/null; then
        return 1
    fi
    tmp=$(mktemp "${TMPDIR:-/tmp}/ssh-wrappers.XXXXXX")
    awk -v b="$BEGIN_MARKER" -v e="$END_MARKER" '
        $0 == b {skip=1; next}
        skip && $0 == e {skip=0; next}
        !skip {print}
    ' "$file" > "$tmp"
    # Trim a trailing blank line we may have left behind.
    awk 'NR==FNR{n=NR;next} FNR==n && $0=="" {next} {print}' "$tmp" "$tmp" > "$tmp.2"
    mv "$tmp.2" "$file"
    rm -f "$tmp"
    return 0
}

# --- uninstall path ---
if [ "$MODE" = uninstall ]; then
    if [ ! -e "$RC_FILE" ]; then
        printf 'ssh-wrappers: %s does not exist — nothing to remove.\n' "$RC_FILE"
        exit 0
    fi
    if remove_block "$RC_FILE"; then
        printf 'ssh-wrappers: removed managed block from %s\n' "$RC_FILE"
    else
        printf 'ssh-wrappers: no managed block found in %s — nothing to remove.\n' "$RC_FILE"
    fi
    exit 0
fi

# --- install path ---

# Make sure the rc file exists so we can append to it.
if [ ! -e "$RC_FILE" ]; then
    printf 'ssh-wrappers: creating %s\n' "$RC_FILE"
    : > "$RC_FILE"
fi

if grep -Fq "$BEGIN_MARKER" "$RC_FILE" 2>/dev/null; then
    if [ "$FORCE" = 1 ]; then
        printf 'ssh-wrappers: --force set; replacing existing managed block in %s\n' "$RC_FILE" >&2
        remove_block "$RC_FILE" || :
    else
        printf 'ssh-wrappers: already installed in %s — nothing to do.\n' "$RC_FILE"
        printf 'ssh-wrappers: use --uninstall first, or --force to replace with a different selection.\n' >&2
        exit 0
    fi
fi

# Detect existing wrapper definitions outside our managed block,
# only for the wrappers we are about to install.
defined_in_rc() {
    name=$1
    grep -Eq "^[[:space:]]*(alias[[:space:]]+${name}=|${name}[[:space:]]*\(\)[[:space:]]*\{|function[[:space:]]+${name}([[:space:]]|\(|\{))" \
        "$RC_FILE" 2>/dev/null
}

CONFLICTS=
for w in $SELECTED; do
    if defined_in_rc "$w"; then CONFLICTS="${CONFLICTS}${w} "; fi
done

if [ -n "$CONFLICTS" ] && [ "$FORCE" != 1 ]; then
    cat >&2 <<EOF
ssh-wrappers: aborting — already defined in $RC_FILE: ${CONFLICTS}
The installer will not silently shadow your existing definitions.

Choose one:
  • Remove the existing definitions from $RC_FILE, then re-run.
  • Install only the wrappers you don't already have, e.g.
        sh install.sh $(for w in $ALL_WRAPPERS; do
            already=0
            for c in $CONFLICTS; do [ "$w" = "$c" ] && already=1; done
            [ "$already" -eq 0 ] && printf '%s ' "$w"
        done)
  • Re-run with --force to install anyway (the new block is appended at the
    end of the file and will take precedence in zsh/bash since later
    definitions win).

  curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --force

To remove a previously installed managed block:
  curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --uninstall
EOF
    exit 1
fi

# Warn (but don't abort) if there's an executable on PATH with the same name.
warn_path() {
    name=$1
    if command -v "$name" >/dev/null 2>&1; then
        existing=$(command -v "$name")
        case "$existing" in
            "$name"|*function*) ;;
            *)
                printf 'ssh-wrappers: note — %s already exists at %s; the shell function will take precedence in interactive shells.\n' \
                    "$name" "$existing" >&2
                ;;
        esac
    fi
}
for w in $SELECTED; do warn_path "$w"; done

if [ -n "$CONFLICTS" ]; then
    printf 'ssh-wrappers: --force set; appending despite existing definitions: %s\n' "$CONFLICTS" >&2
fi

# Append a clean blank line + the block.
{
    printf '\n'
    build_block
} >> "$RC_FILE"

# Comma-join SELECTED for the user-facing message.
joined=$(printf '%s' "$SELECTED" | tr -s ' ' | sed 's/ $//' | sed 's/ /, /g')
printf 'ssh-wrappers: installed %s into %s\n' "$joined" "$RC_FILE"
printf 'ssh-wrappers: reload your shell or run:  . %s\n' "$RC_FILE"
