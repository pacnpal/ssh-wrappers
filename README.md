# ssh-wrappers

[![shellcheck](https://github.com/pacnpal/ssh-wrappers/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/pacnpal/ssh-wrappers/actions/workflows/shellcheck.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![shell: POSIX](https://img.shields.io/badge/shell-POSIX-success)
![platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-lightgrey)
[![GitHub stars](https://img.shields.io/github/stars/pacnpal/ssh-wrappers?style=flat&logo=github)](https://github.com/pacnpal/ssh-wrappers/stargazers)
[![GitHub last commit](https://img.shields.io/github/last-commit/pacnpal/ssh-wrappers/master)](https://github.com/pacnpal/ssh-wrappers/commits/master)
![views](https://visitor-badge.laobi.icu/badge?page_id=pacnpal.ssh-wrappers)

Two small POSIX shell wrappers around `ssh` that fix the two most common day-to-day annoyances:

| Wrapper | Purpose |
|---------|---------|
| [`sshp`](sshp.md) | Force **p**assword authentication (disable pubkey auth for one connection) |
| [`sshi`](sshi.md) | Use only explicitly configured **i**dentities (`IdentitiesOnly=yes`) |

Homepage: <https://pacnpal.github.io/ssh-wrappers/>

## Why?

If your `ssh-agent` has many keys loaded, `ssh` will offer all of them in turn. Most servers have `MaxAuthTries=6`, so you can hit `Too many authentication failures` long before `ssh` tries the right key — or before it ever asks for a password.

- `sshp` skips pubkey auth entirely, so the server falls through to password / keyboard-interactive.
- `sshi` tells `ssh` to *only* offer identities that are explicitly configured (via `-i` or `IdentityFile` in `ssh_config`), instead of every key in the agent.

Both are one-line tweaks of `ssh` options. Wrapped in functions so you don't have to remember (or type) the option flags.

## Install

### One-liner

```sh
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh
```

The installer:

- auto-detects your shell from `$SHELL` (zsh, bash, ksh)
- writes the functions to the matching rc file (`~/.zshrc`, `~/.bash_profile` on macOS bash, `~/.bashrc` elsewhere, `~/.kshrc`, …)
- is idempotent — re-running does nothing if the managed block is already there
- **refuses** to silently shadow `sshp`/`sshi` if you've already defined them (use `--force` to install anyway)
- supports `--uninstall` to cleanly remove the managed block

Override the target file:

```sh
SSH_WRAPPERS_RC=~/.zprofile sh install.sh
```

Force install over existing definitions (later definitions win in zsh/bash):

```sh
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --force
```

Uninstall (removes only the managed block, leaves the rest of your rc file alone):

```sh
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --uninstall
```

Fish isn't covered by the installer (different function syntax) — it'll print snippets you can paste into `~/.config/fish/config.fish`.

### Manual

Append to your shell rc file:

```sh
# SSH wrapper to force password authentication
sshp() {
    ssh -o PubkeyAuthentication=no "$@"
}

# SSH wrapper to use only explicitly configured identities
sshi() {
    ssh -o IdentitiesOnly=yes "$@"
}
```

Then reload your shell:

```sh
source ~/.zshrc   # or ~/.bashrc
```

## Usage

Both wrappers accept the same arguments as `ssh`:

```sh
sshp user@host
sshp -p 2222 user@host 'uptime'

sshi -i ~/.ssh/specific_key user@host
sshi work-bastion          # if configured in ~/.ssh/config
```

See the per-wrapper docs for details, edge cases, and `~/.ssh/config` examples:

- [sshp.md](sshp.md) — force password auth
- [sshi.md](sshi.md) — restrict identities

## Requirements

- POSIX shell (`/bin/sh`) for the installer
- `ssh` (OpenSSH 5.1+ — `IdentitiesOnly` and `PubkeyAuthentication` have been stable for years)
- Interactive shell of zsh, bash, or ksh for the wrappers (fish has its own snippet — see install)

No build step, no dependencies beyond what comes with your OS.

## Troubleshooting

**`Too many authentication failures` when using `sshp`** — your client is still offering keys before falling through to password. `sshp` only disables pubkey *answers*, but the server may still be tracking offered keys. Try `sshi` (or `sshp -o IdentitiesOnly=yes`) so only the keys you explicitly select are offered.

**`Permission denied (publickey)` with `sshp`** — the server has `PasswordAuthentication no`. There is no client-side wrapper that can fix this; the server must allow password auth.

**`sshp`/`sshi` "command not found" after install** — open a fresh shell, or `source ~/.zshrc`. Shell functions only exist in interactive shells that have sourced your rc file.

**Function overridden by an alias or another script in `PATH`** — shell functions take precedence over executables in interactive shells, but not in non-interactive scripts. Check `type sshp` to see what's actually being invoked.

## Development

Lint the installer locally:

```sh
shellcheck --shell=sh install.sh
```

CI runs the same on every push to `master` — see the badge above.

## License

[MIT](LICENSE) © pacnpal
