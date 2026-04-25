<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshp` — force password authentication

```sh
sshp() {
    ssh -o PubkeyAuthentication=no "$@"
}
```

## What it does

Wraps `ssh` with `-o PubkeyAuthentication=no`, which disables public key authentication for that connection. The server falls back to other allowed methods — typically `keyboard-interactive` or `password`.

## When to use it

- **You need to authenticate with a password, but `ssh` keeps trying (and exhausting) your local keys first.** This is the classic case: agent has 8 keys loaded, server has `MaxAuthTries 6`, and you get `Permission denied (publickey,password).` before the server ever asks for the password.
- **You're testing whether password auth is enabled on a server** without disturbing your local keys or hitting `known_hosts`.
- **You're connecting as a user whose keys aren't on the box** and you'd rather skip the pubkey dance entirely instead of watching `ssh` offer 8 wrong keys before it gets to a useful prompt.
- **Initial provisioning** of a server before any keys have been pushed to `~/.ssh/authorized_keys`.

## Usage

```sh
sshp user@host
sshp -p 2222 user@host
sshp user@host 'uptime'
```

All normal `ssh` flags pass through.

## Related

- If the problem is "agent offers too many keys" rather than "I want a password," [`sshi`](sshi.md) is usually a better tool — it offers *only* the key you specify (via `-i` or config), avoiding the `MaxAuthTries` exhaustion without dropping back to a password.
- For "I want to see exactly which methods the server offers and why mine fail," use [`sshv`](sshv.md).

## Notes

- **`sshp` only changes the client side.** If the server has `PasswordAuthentication no` in `sshd_config`, the connection will still fail. There is no client-side wrapper that can re-enable a server-side disable.

- **`keyboard-interactive` vs `password`.** The two are subtly different — `password` sends the cleartext password as a single auth message; `keyboard-interactive` is a generic prompt-driven protocol used for password + 2FA, OTP, etc. Most servers accept both. `PubkeyAuthentication=no` disables only pubkey; both password methods remain on the table.

- **For the inverse** (force key auth, refuse fallback to passwords), use:

  ```sh
  ssh -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no host
  ```

  No wrapper for that one — most users want it as a per-host config rather than a one-off command.

- **Auditing.** `sshp` shows up in the server's auth log as a normal password attempt, no different from typing the password into plain `ssh`. There's no client-side fingerprint identifying the wrapper.

- **Forgot the other wrappers?** Run [`sshh`](sshh.md) for a one-screen summary of what's installed and what each one does.
