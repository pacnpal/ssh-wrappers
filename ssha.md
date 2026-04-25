<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `ssha` — agent forwarding

```sh
ssha() {
    ssh -A "$@"
}
```

## What it does

Forwards your local `ssh-agent` to the remote host. Programs on the remote (most commonly `git`, but also further `ssh` hops) can sign with your local keys without ever seeing the key material.

The keys themselves don't travel. Only signing requests do — sent back to your local agent, which performs the operation and returns the signature.

## When to use it

- **Pushing/pulling git over ssh from a server.** `ssha bastion`, then `git pull` on the bastion uses your local key.
- **Bastion / jump-host workflows.** Hop through one box to reach another without copying keys onto the bastion.
- **Build / CI workers** that need to clone private repos or deploy via ssh, when you don't want to provision a long-lived deploy key.

## Security tradeoff (read this)

Agent forwarding is **not the same as copying your key** — but anyone with root on the remote host can use your forwarded socket to sign arbitrary requests *while you're connected*. That means root on the remote can `ssh` *as you* to anywhere your keys can reach.

Don't forward to:

- Hosts you don't control.
- Shared hosts where other users (or root) might be malicious.
- Anything you wouldn't trust to silently impersonate you for the duration of the session.

For untrusted hops, prefer:

- **`ssh -J`** (ProxyJump) — connects through the bastion without ever exposing the agent socket on it.
- **Ephemeral signed certificates** — short-lived, scoped, revocable.
- A dedicated deploy key on the remote.

If `ssh -J` works for your case, prefer it over `ssha`. Reach for `ssha` only when you genuinely need code on the remote (not just the ssh client) to use your keys.

## Usage

```sh
ssha user@bastion
# now on the bastion:
git pull origin main             # uses your local agent
ssh inner-host                   # also uses your local agent for further hops
```

You can also be explicit about *which* keys are forwarded by combining with [`sshi`](sshi.md):

```sh
ssha -o IdentitiesOnly=yes -i ~/.ssh/work_ed25519 user@bastion
```

## Notes

- **Confirm before signing.** Add keys to your agent with `ssh-add -c ~/.ssh/id_ed25519`; you'll get a graphical prompt every time something tries to use the key, including over a forwarded agent. Catches misuse in the moment.

- **Check what's exposed.** On the remote, `ssh-add -L` lists the public keys your forwarded agent is offering. If you wouldn't be OK with the remote root using *every* key in that list, don't forward.

- **Forwarding never persists.** When the ssh session ends, the forwarded socket goes away. There's no leftover state.

- Sometimes you want `-A` on, sometimes off — `ssha` is the explicit "yes, on for this connection" form. Don't put `ForwardAgent yes` in `~/.ssh/config` for `Host *`; scope it to specific known-trusted hosts.
