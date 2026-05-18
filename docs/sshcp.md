<p align="left">
  <a href="../README.md"><img src="../assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshcp` — push a key with `ssh-copy-id` without pubkey auth

```sh
sshcp() {
    ssh-copy-id -o PubkeyAuthentication=no "$@"
}
```

## What it does

Wraps `ssh-copy-id` with `-o PubkeyAuthentication=no`. `ssh-copy-id` forwards `-o` straight through to the underlying `ssh` connection it makes to push the key, so this disables pubkey authentication for that one attempt and lets `ssh-copy-id` fall through to `password` / `keyboard-interactive`.

## Why this is the right default

`ssh-copy-id`'s job is "I don't have a key on the remote yet — put one there." But the moment you run it, `ssh-copy-id` opens an `ssh` connection, and `ssh` will happily offer every key your agent has loaded *before* asking you for a password.

If your agent has more keys than the server's `MaxAuthTries` (default: 6), you get:

```
Permission denied (publickey,password).
ERROR: ssh: Too many authentication failures
```

…and `ssh-copy-id` exits without ever pushing your key. The fix is to tell `ssh` not to try keys at all. That's exactly what `sshcp` does.

## When to use it

- **First-time provisioning** of a server — pushing your key after the cloud provider gave you a one-time password.
- **You added a new key to your agent** and want to authorize it on a host where the agent's *other* keys are already trusted (so plain `ssh-copy-id` would auth via an old key and silently not push the new one).
- **Servers with low `MaxAuthTries`.** Some hardening guides set it to 3, which any modestly loaded agent exhausts instantly.
- **You're not sure which of your loaded keys (if any) the remote trusts** and just want to type the password and move on.

## Usage

```sh
sshcp user@host                          # push default identity
sshcp -i ~/.ssh/new_ed25519.pub user@host    # push a specific public key
sshcp -p 2222 user@host                  # non-default port
```

All normal `ssh-copy-id` flags pass through.

## Related

- [`sshp`](sshp.md) is the same idea (`-o PubkeyAuthentication=no`) but for plain `ssh` connections — once your key is installed via `sshcp`, you generally don't need `sshp` for that host anymore.
- [`sshi`](sshi.md) is the inverse approach: instead of disabling pubkey, offer *only* the one identity you specify. Use `sshi` when you've already pushed a key and just want to stop the agent from shotgun-offering everything.
- [`sshv`](sshv.md) — if `sshcp` still fails, run `sshv user@host` first to see what auth methods the server actually offers.

## Notes

- **`sshcp` needs `ssh-copy-id` installed.** It ships with OpenSSH on Linux and is in Homebrew's `openssh` on macOS (Apple's bundled OpenSSH does not include it). Check with `command -v ssh-copy-id`.

- **Server must allow password auth.** If `sshd_config` has `PasswordAuthentication no`, no client-side wrapper can fix that — `sshcp` will fail the same way plain `ssh-copy-id` would. You'd need console / cloud-provider key injection instead.

- **Pushes `~/.ssh/id_*.pub` by default.** With no `-i`, `ssh-copy-id` pushes every default identity file's `.pub`. Pass `-i path/to/key.pub` to push exactly one. `sshcp` does not change this — it inherits whatever `ssh-copy-id` does.

- **Use `-n` to dry-run.** `ssh-copy-id -n` prints which keys *would* be pushed without actually pushing them — `sshcp -n user@host` works the same way and is a safe sanity check before committing to a copy.

- **One-shot, not a config change.** `sshcp` only changes the one connection `ssh-copy-id` makes. It does not modify your `~/.ssh/config` and does not affect subsequent `ssh` connections to the same host.

- **Forgot the other wrappers?** Run [`sshh`](sshh.md) for a one-screen summary of what's installed and what each one does.
