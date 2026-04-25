<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshi` — use only explicitly configured identities

```sh
sshi() {
    ssh -o IdentitiesOnly=yes "$@"
}
```

## What it does

Wraps `ssh` with `-o IdentitiesOnly=yes`. With this option, `ssh` only offers identities listed via `-i` on the command line or via `IdentityFile` in `ssh_config` — it does *not* offer every key loaded into `ssh-agent`.

The agent is still used (it does the signing); it's just no longer the source of truth for *which* keys to try.

## When to use it

- **`Too many authentication failures`.** Your agent has many keys, the server's `MaxAuthTries` is 6, and you exhaust the limit before reaching the right one. `sshi` lets you say "only try this specific key."
- **Multiple GitHub / GitLab accounts.** Each account has its own key — without `IdentitiesOnly`, GitHub sees the first key your agent offers and authenticates as that user, regardless of which account you wanted.
- **Per-host key separation.** Work key for the work bastion, personal key for personal hosts. Without `IdentitiesOnly`, the agent might offer the wrong one first.
- **Debugging "why is it using *that* key?"** With `IdentitiesOnly=yes`, the answer is always "the one you told it to."

## Usage

Pair with `-i` to pick the exact key:

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

## Two GitHub accounts pattern

A common reason people end up here:

```sshconfig
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/personal_ed25519
    IdentitiesOnly yes

Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/work_ed25519
    IdentitiesOnly yes
```

```sh
git clone git@github-personal:me/repo.git
git clone git@github-work:org/repo.git
```

`IdentitiesOnly yes` is the bit that makes this actually work. Without it, both clones try the first agent key first, and GitHub authenticates *whoever owns that key*.

## Related

- [`ssha`](ssha.md) (`-A`) forwards the agent. You almost always want `IdentitiesOnly` set on the original connection so the forwarded agent's key set isn't a free-for-all.
- [`sshv`](sshv.md) (`-vvv`) shows you which keys are being offered. If `sshi` isn't behaving, the verbose output will tell you why.

## Notes

- **`IdentitiesOnly=yes` does not disable the agent.** The agent still handles the cryptographic signing for the chosen key — `ssh` just narrows the list of which keys to try.

- **If the file `-i` points to isn't loaded into the agent**, `ssh` will read the key file directly. `IdentitiesOnly` cooperates with both styles.

- **For "always behave this way for this host"**, set `IdentitiesOnly yes` in `~/.ssh/config` for that host (or for `Host *` if it's your global preference). Many people consider `IdentitiesOnly yes` the saner default and only opt out for hosts that benefit from agent shotgun behavior.

- **Inspecting agent contents:** `ssh-add -l` shows what's loaded. If the agent has more than ~5 keys, you almost certainly want `IdentitiesOnly` on by default.
