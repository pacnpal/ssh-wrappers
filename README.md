# ssh-wrappers

![views](https://visitor-badge.laobi.icu/badge?page_id=pacnpal.ssh-wrappers)

Two small shell functions that wrap `ssh` with safer / more predictable authentication behavior.

| Wrapper | Purpose |
|---------|---------|
| [`sshp`](sshp.md) | Force password authentication (disable pubkey auth) |
| [`sshi`](sshi.md) | Use only explicitly configured identities (`IdentitiesOnly=yes`) |

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
sshi -i ~/.ssh/specific_key user@host
```

See the per-wrapper docs for details and use cases.
