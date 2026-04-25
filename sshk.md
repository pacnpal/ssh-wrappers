<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshk` — keepalive (don't drop on idle)

```sh
sshk() {
    ssh -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=4 \
        -o TCPKeepAlive=yes \
        "$@"
}
```

## What it does

Three options that keep an idle ssh session alive long past whatever NAT, firewall, or load balancer would otherwise drop it.

- `ServerAliveInterval=30` — every 30s of silence, send an encrypted no-op message asking the server to acknowledge.
- `ServerAliveCountMax=4` — if four of those messages in a row go unanswered (~2 min), give up and disconnect.
- `TCPKeepAlive=yes` — also enable kernel-level TCP keepalives. This is on by default in many `ssh` builds; setting it explicitly removes ambiguity.

Combined: the connection stays alive through ~2 minutes of network blip, and survives the kind of idle-timeout drops you get from corporate firewalls, NAT gateways, and home routers.

## When to use it

- You're SSH'd into a remote machine and step away for coffee. With plain `ssh`, you come back to `client_loop: send disconnect: Broken pipe`.
- Long-running commands you watch from your laptop: `tail -f`, `journalctl -fu`, builds, deploys.
- Any session where you'd otherwise reach for `tmux` just to survive idle timeouts.
- VPN connections or NAT'd networks that aggressively reap idle TCP connections.

## Usage

```sh
sshk user@host
sshk -p 2222 user@host
sshk prod-bastion 'tail -f /var/log/syslog'
```

## Notes

- This sends traffic every 30 seconds whether the connection is active or not. Trivial bandwidth, but it does mean a metered connection (cellular tethering, satellite) isn't truly idle.

- The same options can be set globally in `~/.ssh/config`:

  ```sshconfig
  Host *
      ServerAliveInterval 30
      ServerAliveCountMax 4
  ```

  If you're never *not* wanting keepalives, that's a better default than always typing `sshk`. The wrapper exists for when you specifically want this behavior on top of your normal `ssh` config, or when you're using a config-less ssh on a remote host or container.

- If the *server* is doing the dropping, `sshk` doesn't help — you'd need `ClientAliveInterval` in the server's `sshd_config`, which only the admin can set.

- Distinct from [`sshm`](sshm.md): `sshk` keeps one connection alive longer; `sshm` makes new connections to the same host instant. Both are about session lifetime, but they solve different parts of the problem.
