# ssh-wrappers

Two small shell functions that wrap `ssh` with safer / more predictable authentication behavior.

| Wrapper | Purpose |
|---------|---------|
| [`sshp`](sshp.md) | Force password authentication (disable pubkey auth) |
| [`sshi`](sshi.md) | Use only explicitly configured identities (`IdentitiesOnly=yes`) |

## Install

Add the functions to your shell rc file (`~/.zshrc`, `~/.bashrc`, etc.):

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
