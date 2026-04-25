# `sshi` — use only explicitly configured identities

```sh
sshi() {
    ssh -o IdentitiesOnly=yes "$@"
}
```

## What it does

Wraps `ssh` with `-o IdentitiesOnly=yes`. With this option, `ssh` only offers identities listed via `-i` or via `IdentityFile` in `ssh_config` — it will *not* offer every key loaded into `ssh-agent`.

## When to use it

- Your `ssh-agent` has many keys and you keep hitting `Too many authentication failures` because the server cuts you off after `MaxAuthTries`.
- You want to be precise about which key is presented to which host (e.g. separate GitHub accounts, separate cloud providers).
- You're debugging "why is it using *that* key?" — `IdentitiesOnly=yes` gives you deterministic behavior.

## Usage

Pair it with `-i` to pick the exact key:

```sh
sshi -i ~/.ssh/work_ed25519 user@host
sshi -i ~/.ssh/personal_rsa  git@github.com
```

Or rely on a per-host `IdentityFile` from `~/.ssh/config`:

```sshconfig
Host work-bastion
    HostName bastion.work.example
    User talor
    IdentityFile ~/.ssh/work_ed25519
    IdentitiesOnly yes
```

```sh
sshi work-bastion
```

## Notes

- `IdentitiesOnly=yes` does not stop `ssh` from talking to the agent — it just restricts which identities are offered. The agent still handles the signing for the chosen key.
- If you find yourself always wanting this behavior for a host, set `IdentitiesOnly yes` in `~/.ssh/config` and you won't need the wrapper for that host.
