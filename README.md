# ssh-wrappers

Two small shell functions that wrap `ssh` with safer / more predictable authentication behavior.

| Wrapper | Purpose |
|---------|---------|
| [`sshp`](sshp.md) | Force password authentication (disable pubkey auth) |
| [`sshi`](sshi.md) | Use only explicitly configured identities (`IdentitiesOnly=yes`) |

## Install

### One-liner

```sh
curl -fsSL https://raw.githubusercontent.com/pacnpal/ssh-wrappers/master/install.sh | sh
```

The installer:

- auto-detects your shell from `$SHELL` (zsh, bash, ksh)
- writes the functions to the matching rc file (`~/.zshrc`, `~/.bash_profile` on macOS bash, `~/.bashrc` elsewhere, `~/.kshrc`, …)
- is idempotent — re-running does nothing if already installed
- warns if `sshp`/`sshi` already exist as an alias, function, or executable

Override the target file if you want:

```sh
SSH_WRAPPERS_RC=~/.zprofile sh install.sh
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
sshi -i ~/.ssh/specific_key user@host
```

See the per-wrapper docs for details and use cases.
