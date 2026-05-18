# Changelog

All notable changes to this project are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

When cutting a release, move the items below from `[Unreleased]` into a new dated `[vX.Y.Z]` section, then run `gh release create vX.Y.Z --title "…" --notes-file <curated>` — never `git tag` directly.

## [Unreleased]

### Added

- `sshcp` — wraps `ssh-copy-id -o PubkeyAuthentication=no` so agent-loaded keys don't burn through the server's `MaxAuthTries` before the password prompt. Same fix `sshp` gives plain `ssh`, but for the key-push step.
- `wrappers/` directory with standalone `.sh` files for each wrapper, generated from `install.sh`'s `emit_fn()` by `scripts/sync-wrappers.sh`. Source individually with `. wrappers/sshX.sh` instead of running the installer.
- `scripts/sync-wrappers.sh` — regenerates `wrappers/*.sh` from `install.sh` so the two sources can't drift unnoticed.
- `docs/CONTRIBUTING.md` — checklist for adding future wrappers, covering every file/count/metadata block that must stay in sync, including the social-card re-render step that's easy to forget.
- Contributing link on the GitHub Pages landing page.

### Changed

- Repo reorganized: per-wrapper docs moved from project root to `docs/`, including `sshh.md`. `CONTRIBUTING.md` moved to `docs/CONTRIBUTING.md`. `README.md` and `LICENSE` stay at root.
- `sshh` detail-view URL now points at `https://pacnpal.github.io/ssh-wrappers/docs/<name>.md` (was `/<name>.md`).
- Social card rebuilt for 11 wrappers — 5+5+1 chip grid with `sshh` as a featured centered chip on row 3. Tagline now mentions `ssh-copy-id`.
- README lede now leads with the verbatim error strings users Google (`Too many authentication failures`, `client_loop: send disconnect: Broken pipe`, `sudo: a terminal is required`, `ssh-copy-id` exiting before the password prompt, etc.) and explicitly calls out macOS/Linux/POSIX-shell support.
- GitHub repo description and topics expanded for discoverability: added `openssh`, `ssh-copy-id`, `ssh-tools`, `command-line-tool`, `developer-tools`, `linux`, `macos` (now at the 20-topic ceiling).
- Shellcheck CI now lints `scripts/sync-wrappers.sh` in addition to `install.sh`; path filter widened to `scripts/**.sh`.
