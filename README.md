<p align="center">
  <img src="assets/social-card.svg" alt="ssh-wrappers — small POSIX shell wrappers around ssh" width="720">
</p>

<h1 align="center">ssh-wrappers</h1>

<p align="center">
  <a href="https://github.com/pacnpal/ssh-wrappers/actions/workflows/shellcheck.yml"><img alt="shellcheck" src="https://github.com/pacnpal/ssh-wrappers/actions/workflows/shellcheck.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="license: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="shell: POSIX" src="https://img.shields.io/badge/shell-POSIX-success">
  <img alt="platforms" src="https://img.shields.io/badge/platforms-macOS%20%7C%20Linux-lightgrey">
  <a href="https://github.com/pacnpal/ssh-wrappers/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/pacnpal/ssh-wrappers?style=flat&logo=github"></a>
  <a href="https://github.com/pacnpal/ssh-wrappers/commits/master"><img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/pacnpal/ssh-wrappers/master"></a>
  <img alt="views" src="https://visitor-badge.laobi.icu/badge?page_id=pacnpal.ssh-wrappers">
</p>

Eleven small POSIX shell wrappers around `ssh` and `ssh-copy-id` that fix the most common day-to-day OpenSSH annoyances — `Too many authentication failures` from agents with too many keys, `client_loop: send disconnect: Broken pipe` on idle sessions, `sudo: a terminal is required to read the password`, `ssh-copy-id` exiting before the password prompt, host-key prompts on ephemeral cloud VMs, reconnect latency on bastion hops, and the rest of the well-known papercuts. Each wrapper is a one-line tweak of options, packaged behind a name short enough that you'll actually use it. Plus a built-in `sshh` to remind you which is which.

Works on macOS, Linux, and any POSIX shell — `zsh`, `bash`, `ksh`, with a fish snippet for copy-paste.

Homepage: <https://pacnpal.github.io/ssh-wrappers/>

## The wrappers

| Wrapper | Purpose | Mnemonic |
|---------|---------|----------|
| [`sshp`](docs/sshp.md) | Force **p**assword authentication (disable pubkey for one connection) | **p**assword |
| [`sshi`](docs/sshi.md) | Use only explicitly configured **i**dentities (`IdentitiesOnly=yes`) | **i**dentities |
| [`ssha`](docs/ssha.md) | Forward your local ssh-**a**gent to the remote host (`-A`) | **a**gent |
| [`sshcp`](docs/sshcp.md) | **C**o**p**y a key with `ssh-copy-id` without pubkey auth (skip the `MaxAuthTries` burn) | **c**o**p**y |
| [`sshq`](docs/sshq.md) | **Q**uiet/quick: skip host key prompts, don't pollute `known_hosts` | **q**uick |
| [`sshk`](docs/sshk.md) | **K**eepalive: don't drop on idle (`ServerAlive*`) | **k**eepalive |
| [`sshm`](docs/sshm.md) | **M**ultiplex: instant subsequent connections (`ControlMaster`) | **m**ultiplex |
| [`ssht`](docs/ssht.md) | Force a pseudo-**t**erminal (`-t`) — for `sudo`, `htop`, `vim` over ssh | **t**ty |
| [`sshc`](docs/sshc.md) | **C**ompression (`-C`) — wins on slow links and text-heavy streams | **c**ompression |
| [`sshv`](docs/sshv.md) | **V**erbose debug (`-vvv`) — see exactly what `ssh` is trying | **v**erbose |
| [`sshh`](docs/sshh.md) | **H**elp — list installed wrappers, what they do, how to use | **h**elp |

## Why?

`ssh` is configurable to a fault. Most of its sharp edges have a fix that's a single `-o option=value` away — but it's the kind of fix you have to remember exists, type correctly, and know when to apply.

These wrappers turn each fix into a one-character mnemonic:

- Agent has too many keys, server says `Too many authentication failures` → `sshi`.
- Need to type a password but `ssh` keeps offering keys instead → `sshp`.
- Pushing your key to a fresh server but `ssh-copy-id` fails before the password prompt → `sshcp`.
- Connection dropped while you got coffee → `sshk`.
- Spinning up the same host's connection 50 times in a deploy script → `sshm`.
- Run `sudo` over ssh, get `sudo: a terminal is required` → `ssht`.
- Cloud VM with a fresh host key, don't want to litter `known_hosts` → `sshq`.
- Need agent forwarding for `git pull` on a bastion → `ssha`.
- Streaming logs over a slow link → `sshc`.
- Connection failing for an unknown reason → `sshv`.
- Forgot which wrapper does what → `sshh`.

## Install

### One-liner (everything)

```sh
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh
```

### Selective install

Pass wrapper names as positional arguments to install only those:

```sh
# Just the auth helpers
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- sshp sshi ssha

# Just connection management
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- sshk sshm

# Single wrapper
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- ssht
```

List the available names with `--list`:

```sh
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --list
```

### What the installer does

- auto-detects your shell from `$SHELL` (zsh, bash, ksh)
- writes the selected functions to the matching rc file (`~/.zshrc`, `~/.bash_profile` on macOS bash, `~/.bashrc` elsewhere, `~/.kshrc`, …) inside a marked block
- is idempotent — re-running does nothing if the managed block is already there
- **refuses** to silently shadow wrappers you've already defined yourself (use `--force` to install anyway)
- supports `--uninstall` to cleanly remove the managed block (and only the managed block)

### Override the target file

```sh
SSH_WRAPPERS_RC=~/.zprofile sh install.sh
```

### Replace an existing install with a different selection

```sh
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --force sshp sshi sshk sshm
```

`--force` removes the existing managed block and writes the new selection.

### Uninstall

```sh
curl -fsSL https://pacnpal.github.io/ssh-wrappers/install.sh | sh -s -- --uninstall
```

Removes only the marked block; anything else in your rc file is untouched.

### Fish

Not covered by the installer (different function syntax). Run the installer once to see the snippet you can paste into `~/.config/fish/config.fish`, or copy the bodies straight from the per-wrapper docs in [`docs/`](docs/).

### Manual

Skip the installer entirely — three ways:

- Copy the function definition you want from the per-wrapper doc in [`docs/`](docs/) into your rc file (each `docs/sshX.md` shows the function at the top).
- Source a standalone file directly: `. wrappers/sshX.sh` defines just that one wrapper in your current shell. Files under [`wrappers/`](wrappers/) are regenerated copies of what `install.sh` would write — useful for cherry-picking into your dotfiles.
- Open `install.sh` and read the `emit_fn()` block — it's the source of truth for every wrapper body.

## Usage

Every wrapper accepts the same arguments as `ssh`:

```sh
sshp user@host                                  # password instead of keys
sshi -i ~/.ssh/work_ed25519 user@host           # only this key
ssha bastion                                    # forward agent
sshcp user@new-host                             # push key, skip pubkey auth
sshq ec2-user@10.0.0.42                         # ephemeral cloud VM
sshk prod-bastion 'tail -f /var/log/syslog'     # long idle session
sshm work-bastion                               # then re-run; instant
ssht user@host sudo systemctl restart nginx     # sudo over ssh
sshc remote-builder 'tail -f build.log'         # compression
sshv user@host                                  # debug auth failure
sshh                                            # show all wrappers + install status
sshh sshm                                       # detail for one wrapper
```

Read the per-wrapper docs for what each option actually does, security tradeoffs, and `~/.ssh/config` equivalents:

- [sshp](docs/sshp.md) · [sshi](docs/sshi.md) · [ssha](docs/ssha.md) · [sshcp](docs/sshcp.md) — auth
- [sshq](docs/sshq.md) — trust
- [sshk](docs/sshk.md) · [sshm](docs/sshm.md) — connection lifetime
- [ssht](docs/ssht.md) · [sshc](docs/sshc.md) — I/O
- [sshv](docs/sshv.md) — debugging
- [sshh](docs/sshh.md) — help / introspection

## Requirements

- POSIX shell (`/bin/sh`) for the installer
- OpenSSH client (any version from the past decade — every option used here has been stable for years)
- Interactive shell of zsh, bash, or ksh for the wrappers (fish has its own snippet — see install)

No build step, no runtime dependencies beyond what comes with your OS.

## Troubleshooting

**`Too many authentication failures`** — your agent has more keys than the server's `MaxAuthTries` (default 6). Use [`sshi`](docs/sshi.md) to offer only one specific key, or [`sshp`](docs/sshp.md) to skip pubkey entirely.

**`Permission denied (publickey)` with `sshp`** — the server has `PasswordAuthentication no`. No client-side wrapper can fix this; the server must allow password auth.

**`ssh-copy-id` exits with `Too many authentication failures` before asking for a password** — your agent's loaded keys are exhausting `MaxAuthTries` before the password prompt. Use [`sshcp`](docs/sshcp.md) instead of plain `ssh-copy-id`.

**`sudo: a terminal is required` over ssh** — pass the command through [`ssht`](docs/ssht.md) instead of plain `ssh`.

**`client_loop: send disconnect: Broken pipe` after idle** — use [`sshk`](docs/sshk.md), or set `ServerAliveInterval 30` for `Host *` in `~/.ssh/config`.

**`sshp`/`sshi`/etc. "command not found" after install** — open a fresh shell, or `source ~/.zshrc`. Shell functions only exist in interactive shells that have sourced your rc file. Check `type sshp` in the new shell.

**Function overridden by an alias or another script in `PATH`** — shell functions take precedence over executables in interactive shells, but not in non-interactive scripts. `type sshp` reveals what's actually being invoked.

**Wrapper conflicts with one I already defined** — the installer refuses to silently shadow you. Either remove your existing definition, install only the wrappers that don't conflict, or pass `--force` to overwrite.

**Pages URL returns 404 or stale content** — the GitHub Pages CDN caches for ~10 min. Use the commit-pinned raw URL or `https://cdn.jsdelivr.net/gh/pacnpal/ssh-wrappers/install.sh` to bust the cache once.

## Development

Lint the installer locally:

```sh
shellcheck --shell=sh install.sh scripts/sync-wrappers.sh
```

CI runs the same on every push to `master` — see the badge above.

After editing `install.sh`'s `emit_fn()` block (function bodies live there), regenerate the standalone copies in `wrappers/`:

```sh
sh scripts/sync-wrappers.sh
```

See [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) for the full checklist when adding a new wrapper — every file/count/metadata block that needs to stay in sync.

Project layout:

```
.
├── README.md                 # this file
├── LICENSE
├── CHANGELOG.md              # release history; edit the [Unreleased] section
├── install.sh                # the installer (source of truth for function bodies)
├── index.html                # GitHub Pages landing page
├── wrappers/                 # standalone copies of each wrapper, one .sh per
│   ├── README.md             # what this dir is and how it's regenerated
│   └── ssh{p,i,a,cp,q,k,m,t,c,v,h}.sh
├── docs/                     # per-wrapper docs + CONTRIBUTING
│   ├── CONTRIBUTING.md       # how to add a wrapper
│   └── ssh{p,i,a,cp,q,k,m,t,c,v,h}.md
├── scripts/
│   └── sync-wrappers.sh      # regenerate wrappers/ from install.sh
├── assets/
│   ├── logo.svg              # the mark
│   ├── logo.png              # rendered 512x512
│   ├── social-card.svg       # 1280x640 OG image
│   └── social-card.png       # rendered
└── .github/workflows/
    └── shellcheck.yml        # CI
```

## Contributing

See [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) for what to touch when adding a new wrapper. The short version: edit `install.sh`'s `emit_fn()` plus `_sshh_data`, add `docs/sshX.md`, update the count in `README.md` / `docs/sshh.md` / `index.html` / `assets/social-card.svg`, re-render the social card PNG, and run `sh scripts/sync-wrappers.sh`.

## License

[MIT](LICENSE) © pacnpal
