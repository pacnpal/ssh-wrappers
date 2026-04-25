<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshm` — multiplex (instant subsequent connections)

```sh
sshm() {
    ssh -o ControlMaster=auto \
        -o ControlPath="$HOME/.ssh/cm-%r@%h:%p" \
        -o ControlPersist=10m \
        "$@"
}
```

## What it does

Enables OpenSSH connection multiplexing.

- `ControlMaster=auto` — first connection to a given user/host/port becomes a master and listens on a control socket; subsequent connections detect the socket and reuse the existing TCP + auth.
- `ControlPath=$HOME/.ssh/cm-%r@%h:%p` — where the control socket lives. `%r` = remote user, `%h` = host, `%p` = port. The `cm-` prefix marks them so they're easy to spot or clean up.
- `ControlPersist=10m` — even after every interactive client exits, keep the master alive for 10 minutes so the *next* connection is also instant.

The result: the first `sshm host` is a normal ssh connection. The second one (within 10 min) is essentially free — no TCP handshake, no key exchange, no re-auth.

## When to use it

- Tools that fan out lots of short-lived ssh invocations: ansible, fabric, capistrano, your own deploy scripts, `for h in ...; do ssh $h ...; done` loops.
- Working with the same remote host all afternoon — every new tab/window connects in under a second.
- Iterating on remote files via `scp` / `rsync` / VS Code remote / IDE remote shells (these reuse the master too).
- Anywhere the connection setup cost is more than the work being done.

## Usage

```sh
sshm user@host                    # opens (or attaches to) the master
sshm user@host 'uptime'           # second invocation is instant
ssh user@host                     # plain ssh ALSO uses the master if config matches
```

Once a master is up, you can list active masters and tear one down:

```sh
ls ~/.ssh/cm-*                                # see active masters
ssh -O check user@host                        # is the master alive?
ssh -O exit  user@host                        # close the master now
```

## ssh_config equivalent

If you want this behavior for *every* host without typing `sshm`, add to `~/.ssh/config`:

```sshconfig
Host *
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
```

That's almost always what people end up doing — `sshm` is most useful when you can't (or don't want to) modify config, e.g. on a coworker's machine, in a container, or when testing whether multiplexing solves a specific problem.

## Notes

- **Sockets stay around.** `~/.ssh/cm-*` files build up over time. Run `rm ~/.ssh/cm-*` to nuke them all, or `ssh -O exit` per-host. Sockets that point at a dead master are harmless — `ssh` just falls back to opening a new connection.

- **Sudo and TTY allocation.** A multiplexed session inherits the master's TTY-allocation decision. If your master was opened without `-t`, a child connection running `sudo` may get `sudo: a terminal is required`. Open the master with `ssht` (or pass `-t` once) when that matters.

- **Auth changes are sticky.** If the master authenticated with key A, subsequent attaches reuse that auth — they won't try key B even if you pass `-i ~/.ssh/keyB`. Tear down the master (`ssh -O exit`) and reconnect to switch.

- **`%C` is also useful.** `%C` is a hash of `%l%h%p%r` — guaranteed-short and fits in path-length-limited environments (sockets have a ~104-char limit on macOS). If you hit "too long for Unix domain socket", switch to `~/.ssh/cm-%C`.

- Distinct from [`sshk`](sshk.md): `sshk` keeps one long-lived connection from dropping; `sshm` makes opening new connections fast. Both can be used together.
