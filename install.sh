#!/bin/sh
# install.sh — install sshp / sshi shell functions into the user's shell rc file.
#
# Usage:
#   sh install.sh
#   curl -fsSL https://raw.githubusercontent.com/pacnpal/ssh-wrappers/master/install.sh | sh
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

# Make sure the rc file exists so we can append to it.
if [ ! -e "$RC_FILE" ]; then
    printf 'ssh-wrappers: creating %s\n' "$RC_FILE"
    : > "$RC_FILE"
fi

if grep -Fq "$BEGIN_MARKER" "$RC_FILE" 2>/dev/null; then
    printf 'ssh-wrappers: already installed in %s — nothing to do.\n' "$RC_FILE"
    exit 0
fi

# Warn if sshp/sshi already exist outside our managed block (alias, function, script in PATH).
warn_existing() {
    name=$1
    if grep -Eq "^[[:space:]]*(alias[[:space:]]+${name}=|${name}[[:space:]]*\(\)[[:space:]]*\{)" "$RC_FILE" 2>/dev/null; then
        printf 'ssh-wrappers: warning — %s is already defined in %s; the new definition will shadow it.\n' "$name" "$RC_FILE" >&2
    elif command -v "$name" >/dev/null 2>&1; then
        existing=$(command -v "$name")
        printf 'ssh-wrappers: warning — %s already exists at %s; the shell function will take precedence in interactive shells.\n' "$name" "$existing" >&2
    fi
}

warn_existing sshp
warn_existing sshi

# Append a clean blank line + the block.
{
    printf '\n'
    printf '%s\n' "$BLOCK"
} >> "$RC_FILE"

printf 'ssh-wrappers: installed sshp and sshi into %s\n' "$RC_FILE"
printf 'ssh-wrappers: reload your shell or run:  . %s\n' "$RC_FILE"
