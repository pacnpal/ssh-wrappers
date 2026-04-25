<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# `sshh` — list installed wrappers, what they do, how to use them

`sshh` is the help / introspection wrapper. With no arguments it shows every wrapper in the package, marks which ones are installed in the current shell, and prints a one-line description and category for each. Pass a wrapper name and you get the detail view: status, example, and a link to the full doc.

```sh
sshh                # overview of all 10 wrappers
sshh sshp           # detail for one wrapper
sshh sshp sshk      # detail for several
```

## What it shows

### Overview (`sshh`)

A single screen with everything you need to remember which wrapper to reach for:

```
ssh-wrappers  small POSIX shell wrappers around ssh
https://pacnpal.github.io/ssh-wrappers/

  ✓  sshp   [auth]    force password auth (disable pubkey)
  ✓  sshi   [auth]    use only explicit identities (IdentitiesOnly=yes)
  ✓  ssha   [auth]    forward your local ssh-agent (-A) — trusted hosts only
  ✓  sshq   [trust]   quick — skip host key checks (ephemeral hosts)
  ✓  sshk   [conn]    keepalive — do not drop on idle
  ✓  sshm   [conn]    multiplex — instant subsequent reconnects
  ✓  ssht   [i/o]     force a TTY (sudo, htop, vim over ssh)
  ✓  sshc   [i/o]     compression (-C) for slow links and text streams
  ✓  sshv   [debug]   verbose (-vvv) — see auth attempts and KEX
  ✓  sshh   [meta]    this help (run `sshh <name>` for detail)

  10 installed · 0 not installed

Detail:        sshh <name>          e.g. sshh sshp
Uninstall:     curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --uninstall
```

A `✓` (green) means the wrapper is defined in the current shell. A `·` (dim) means it isn't — typically because you did a [selective install](README.md#selective-install) and skipped that one. The footer shows the install / uninstall commands so you can fix it without leaving your terminal.

### Detail (`sshh sshp`)

```
sshp  [auth]  force password auth (disable pubkey)
  status:   installed
  example:  sshp user@host
  docs:     https://pacnpal.github.io/ssh-wrappers/sshp.md
```

Status, an example invocation, and a link straight to the full doc.

## When to use it

- **You forgot which letter goes with which wrapper.** `sshh` is faster than `man ssh` plus reading nine `.md` files.
- **You're not sure if a wrapper is installed in your current shell** (e.g. `bash` doesn't auto-source `~/.zshrc`).
- **You want a colleague to know what's available** without sending them a link.
- **You did a selective install and forgot which subset you picked.**

## Output

- **Colors via `tput`.** When stdout is a TTY and the terminal supports ≥8 colors, `sshh` colors wrapper names, the install marker (`✓` green / `·` dim), and the headers. When piped (e.g. `sshh | grep`), output is plain.
- **POSIX shell only.** No `local`, no arrays, no Bashisms.
- **No network.** All metadata is baked into the function.

## Notes

- **Static metadata.** `sshh` knows about whatever was current at install time. If a new wrapper is added upstream, you won't see it until you re-run the installer:

  ```sh
  curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --force
  ```

- **`type sshh`** is the one-liner version: `type` will tell you whether `sshh` (or any wrapper) is a function. `sshh` itself runs that check across all 10 in one go.

- **No internal helpers leak.** `sshh` uses temp variables prefixed `_sshh_`, all `unset` before returning. Running `sshh` doesn't pollute your shell with helper functions.

- **Want a one-letter alias?** Most shells let you do `alias '?'=sshh` if `?` isn't already taken. (Zsh's `?` is a glob, so it has to be quoted.) Or just `alias h=sshh`.
