# `sshp` — force password authentication

```sh
sshp() {
    ssh -o PubkeyAuthentication=no "$@"
}
```

## What it does

Wraps `ssh` with `-o PubkeyAuthentication=no`, which disables public key authentication for that connection. The server will fall back to other allowed methods — typically keyboard-interactive or password.

## When to use it

- You need to authenticate with a password, but `ssh` keeps trying (and exhausting) your local keys first.
- Your agent has many keys loaded and the server hits `MaxAuthTries` before it ever gets to ask for a password.
- You're testing that password auth is actually enabled on a server.
- You're connecting as a user whose keys are not on the box and you'd rather skip the pubkey dance entirely.

## Usage

```sh
sshp user@host
sshp -p 2222 user@host
sshp user@host 'uptime'
```

All normal `ssh` flags pass through.

## Notes

- This does not disable password auth on the server — it only changes what the *client* offers. If the server has `PasswordAuthentication no`, the connection will still fail.
- For the inverse (force key auth, refuse passwords), use `-o PasswordAuthentication=no -o KbdInteractiveAuthentication=no`.
