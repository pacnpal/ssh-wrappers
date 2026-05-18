# `wrappers/`

Standalone copies of each wrapper function. Generated from `install.sh` by `scripts/sync-wrappers.sh`. **Don't edit these by hand** — edits get clobbered the next time the sync script runs. Edit `install.sh`'s `emit_fn()` block instead, then run:

```sh
sh scripts/sync-wrappers.sh
```

## What's here

One `sshX.sh` per wrapper, each containing the comment header and POSIX shell function — exactly the bytes that `install.sh` would write into your rc file for that wrapper.

```
wrappers/
├── ssha.sh
├── sshc.sh
├── sshcp.sh
├── sshh.sh
├── sshi.sh
├── sshk.sh
├── sshm.sh
├── sshp.sh
├── sshq.sh
├── ssht.sh
└── sshv.sh
```

## Why these exist

The `install.sh` curl-pipe-sh path is the supported install. These files give you three other options:

- **Source one directly.** `. wrappers/sshp.sh` defines `sshp` in the current shell without touching your rc file or pulling in the rest of the package.
- **Cherry-pick into your dotfiles.** Open the file, copy the function, paste it where you want it — your dotfiles repo's `functions.zsh`, a project-specific `.envrc`, wherever.
- **Diff a proposed change.** Editing `install.sh`'s `emit_fn()` and re-running `scripts/sync-wrappers.sh` produces a clean `git diff` of exactly what the function body change is — useful for review.

## Source of truth

`install.sh`. These files are regenerated from it. If a `wrappers/sshX.sh` drifts from what `install.sh` would emit (e.g. someone edited it directly), the next `sync-wrappers.sh` run overwrites the drift.

See [`docs/CONTRIBUTING.md`](../docs/CONTRIBUTING.md) for the full workflow when adding or modifying a wrapper.
