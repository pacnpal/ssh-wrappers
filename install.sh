#!/bin/sh
# install.sh — install sshp / sshi shell functions into the user's shell rc file.
#
# Usage:
#   sh install.sh                 # install (refuses if sshp/sshi already defined)
#   sh install.sh --force         # install anyway, even if existing definitions found
#   sh install.sh --uninstall     # remove the managed block
#
#   curl -fsSL https://raw.githubusercontent.com/pacnpal/ssh-wrappers/master/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/pacnpal/ssh-wrappers/master/install.sh | sh -s -- --force
#
# Override the target rc file:
#   SSH_WRAPPERS_RC=~/.zprofile sh install.sh

set -eu

BEGIN_MARKER='# >>> ssh-wrappers >>>'
END_MARKER='# <<< ssh-wrappers <<<'

BLOCK=$(cat <<'EOF'
# >>> ssh-wrappers >>>
# https://github.com/pacnpal/ssh-wrappers
# SSH wrapper to force password authentication
sshp() {
    ssh -o PubkeyAuthentication=no "$@"
}

# SSH wrapper to use only explicitly configured identities
sshi() {
    ssh -o IdentitiesOnly=yes "$@"
}
# <<< ssh-wrappers <<<
EOF
)

# --- args ---
MODE=install
FORCE=${SSH_WRAPPERS_FORCE:-0}
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=1 ;;
        --uninstall|-u) MODE=uninstall ;;
        --help|-h)
            sed -n '2,12p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            printf 'ssh-wrappers: unknown argument: %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done

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
Fish uses a different function syntax. Add these to ~/.config/fish/config.fish:

    function sshp
        ssh -o PubkeyAuthentication=no $argv
    end

    function sshi
        ssh -o IdentitiesOnly=yes $argv
    end
EOF
        exit 1
        ;;
esac

# Remove the managed block in-place. POSIX sed -i differs across platforms,
# so do it via a temp file.
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
    # Trim a single trailing blank line we may have left behind, only if present.
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
    printf 'ssh-wrappers: already installed in %s — nothing to do.\n' "$RC_FILE"
    exit 0
fi

# Detect existing sshp/sshi definitions outside our managed block.
defined_in_rc() {
    name=$1
    grep -Eq "^[[:space:]]*(alias[[:space:]]+${name}=|${name}[[:space:]]*\(\)[[:space:]]*\{|function[[:space:]]+${name}([[:space:]]|\(|\{))" \
        "$RC_FILE" 2>/dev/null
}

CONFLICTS=
if defined_in_rc sshp; then CONFLICTS="${CONFLICTS}sshp "; fi
if defined_in_rc sshi; then CONFLICTS="${CONFLICTS}sshi "; fi

if [ -n "$CONFLICTS" ] && [ "$FORCE" != 1 ]; then
    cat >&2 <<EOF
ssh-wrappers: aborting — already defined in $RC_FILE: ${CONFLICTS}
The installer will not silently shadow your existing definitions.

Choose one:
  • Remove the existing definitions from $RC_FILE, then re-run.
  • Keep your existing definitions and skip this installer.
  • Re-run with --force to install anyway (the new block is appended at the
    end of the file and will take precedence in zsh/bash since later
    definitions win).

  curl -fsSL https://raw.githubusercontent.com/pacnpal/ssh-wrappers/master/install.sh | sh -s -- --force

To remove a previously installed managed block:
  curl -fsSL https://raw.githubusercontent.com/pacnpal/ssh-wrappers/master/install.sh | sh -s -- --uninstall
EOF
    exit 1
fi

# Warn (but don't abort) if there's an executable on PATH with the same name.
warn_path() {
    name=$1
    if command -v "$name" >/dev/null 2>&1; then
        existing=$(command -v "$name")
        case "$existing" in
            "$name"|*function*) ;;  # already a shell builtin/function — nothing to say
            *)
                printf 'ssh-wrappers: note — %s already exists at %s; the shell function will take precedence in interactive shells.\n' \
                    "$name" "$existing" >&2
                ;;
        esac
    fi
}
warn_path sshp
warn_path sshi

if [ -n "$CONFLICTS" ]; then
    printf 'ssh-wrappers: --force set; appending despite existing definitions: %s\n' "$CONFLICTS" >&2
fi

# Append a clean blank line + the block.
{
    printf '\n'
    printf '%s\n' "$BLOCK"
} >> "$RC_FILE"

printf 'ssh-wrappers: installed sshp and sshi into %s\n' "$RC_FILE"
printf 'ssh-wrappers: reload your shell or run:  . %s\n' "$RC_FILE"
