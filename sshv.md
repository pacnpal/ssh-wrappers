<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshv` — verbose debug

```sh
sshv() {
    ssh -vvv "$@"
}
```

## What it does

Runs `ssh` at the highest verbosity (`-vvv`). Three levels in OpenSSH:

- `-v` — connection establishment, host key matching, what auth methods the server offers, which one wins.
- `-vv` — adds the cipher / KEX / MAC negotiation.
- `-vvv` — adds wire-level details, every packet, identity offer, and rejection.

`sshv` jumps straight to `-vvv` because if you're reaching for verbose at all, you usually want to see *everything*.

## When to use it

You're debugging "why won't this connect?" or "why is it asking for a password when I have a key?" — questions plain `ssh` answers with one-line errors and no detail.

Common things `sshv` reveals:

- **Wrong key being offered.** `Offering public key: /Users/me/.ssh/id_rsa` followed by `Authentications that can continue: publickey,password` means the server didn't accept that key.
- **MaxAuthTries hit.** `Received disconnect from ... Too many authentication failures` after `sshv` shows you all the keys it tried. Combine with [`sshi`](sshi.md) to fix.
- **Host key mismatch.** Detailed message about which key was expected vs offered, with file/line of the conflict in `known_hosts`.
- **Cipher / KEX negotiation failure.** Old servers may not support modern algorithms. `sshv` shows the proposed and accepted lists; you can then add `-o KexAlgorithms=+diffie-hellman-group14-sha1` etc.
- **Network reachability.** `debug1: connect to address X port 22: Connection refused` vs. `Operation timed out` distinguishes "no service" from "filtered".

## Usage

```sh
sshv user@host
sshv -i ~/.ssh/specific_key user@host  # see if the right key is being offered
sshv user@host 'true' 2>&1 | less       # capture the full transcript
```

## Reading the output

The interesting lines are usually:

- `debug1: Authentications that can continue:` — what the server will accept.
- `debug1: Next authentication method:` — what `ssh` is about to try.
- `debug1: Offering public key:` — which keys the agent is offering, in order.
- `debug1: Server accepts key:` — match.
- `debug2: we did not send a packet, disable method` — that auth method was rejected; ssh moves on.
- `Authenticated to ...` — success.

Most everything else is noise on a healthy connection. When debugging, scan for those markers first.

## Notes

- `sshv` writes debug output to stderr, so piping `2>&1 | less` (or `| grep`) keeps the regular output usable.
- If you only want one level: `ssh -v "$@"` is plenty for most "why isn't this connecting" cases. `sshv` is the "give me everything" hammer.
- Pair with [`sshi`](sshi.md) to control *which* keys are offered, then `sshv` to confirm only those are tried.

- **Forgot the other wrappers?** Run [`sshh`](sshh.md) for a one-screen summary of what's installed and what each one does.
