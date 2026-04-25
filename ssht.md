<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `ssht` — force a pseudo-terminal

```sh
ssht() {
    ssh -t "$@"
}
```

## What it does

Wraps `ssh` with `-t`, which forces pseudo-terminal allocation on the remote host. By default `ssh` only allocates a TTY for interactive logins (no command argument); when you pass a command, it doesn't, and that breaks anything expecting a real terminal.

## When to use it

The classic giveaway is one of these errors when you run `ssh host <some-command>`:

- `sudo: a terminal is required to read the password`
- `sudo: no tty present and no askpass program specified`
- `Pseudo-terminal will not be allocated because stdin is not a terminal.`
- `the input device is not a TTY`
- `Error opening terminal: unknown.`

Common cases:

- Running `sudo` over ssh: `ssht host sudo systemctl restart nginx`
- Launching a TUI: `ssht host htop`, `ssht host vim /etc/foo`
- Anything that uses `tput`, colored output, progress bars, or interactive prompts.
- Running a remote shell session that should *behave* like a terminal even if you piped something into it.

## Usage

```sh
ssht user@host sudo systemctl status nginx
ssht user@host htop
ssht -p 2222 user@host
```

For commands that need a TTY *and* you're piping their output, ssh gets unhappy because the local stdin is now a pipe. Use `-tt` to force allocation even then:

```sh
ssh -tt user@host 'sudo apt-get update' < /dev/null > update.log
```

`ssht` itself is just a single `-t`; reach for `-tt` directly when needed.

## Notes

- For interactive ssh (no remote command argument), a TTY is allocated automatically — you don't need `ssht`. It only matters when you pass a command.

- A multiplexed master ([`sshm`](sshm.md)) is opened with whatever TTY decision the first invocation made. If you plan to run `sudo` over the master, open it with `ssht` first.
