<p align="left">
  <a href="README.md"><img src="assets/logo.svg" width="48" alt="ssh-wrappers" align="left" style="margin-right:14px"></a>
</p>

# Adding a new wrapper

This is the operational checklist for adding a new wrapper to `ssh-wrappers`. Read it top to bottom before opening a PR — every section matters, and missing one of them leaves the project in an inconsistent state (e.g. the installer ships the wrapper but `sshh` doesn't know about it).

The count in the README, the count in `index.html`, the `sshh` metadata, and the `ALL_WRAPPERS` allowlist must all agree. There's no script that enforces this — it's manual coordination across the files listed below.

## Before you start: is it really a wrapper?

A wrapper qualifies if **all** of these are true:

- It's a one-line tweak of `ssh` (or a closely related tool like `ssh-copy-id`) — *not* a script that does several things, not a wrapper that adds business logic.
- The fix is something users currently solve by typing a long `-o key=value` chain or remembering an obscure flag.
- The fix is *general* (useful across many hosts and workflows), not specific to one team or one network.
- It has a short, memorable name that doesn't collide with an existing tool on most systems.

If you're tempted to add interactive prompts, config-file parsing, or logic that branches on the target host: this probably isn't the right project. Wrappers here are mechanical, one-line, transparent.

## Pick a name

Convention: `ssh<one-letter>` (e.g. `sshp`, `sshk`). When all the obvious single letters are taken or none fit the mnemonic, a short `ssh<2-3 letters>` is acceptable (e.g. `sshcp` — wraps `ssh-copy-id`, mnemonic `cp` = copy).

Constraints:

- Must be a valid POSIX shell function name (`[A-Za-z_][A-Za-z0-9_]*`).
- Must start with `ssh` — the installer's argument validator only accepts names matching `ssh*`. If you ever need to relax this, update the `ssh*)` case in `install.sh`'s arg-parsing loop.
- Must not match an existing wrapper or an existing OpenSSH binary (`ssh`, `sshd`, `ssh-add`, `ssh-agent`, `ssh-keygen`, `ssh-keyscan`, `ssh-copy-id`, `scp`, `sftp`).
- Should be visually distinct from existing wrappers — `sshcp` next to `sshc` is borderline; `sship` next to `sshi` is not OK.

## Pick a category

Used by `sshh` and by the `.cats` strip in `index.html`. Current categories:

| Category | Meaning | Existing wrappers |
|----------|---------|-------------------|
| `auth` | How the connection authenticates | `sshp`, `sshi`, `ssha`, `sshcp` |
| `trust` | Host-key / `known_hosts` behavior | `sshq` |
| `conn` | Connection lifetime (idle, multiplexing) | `sshk`, `sshm` |
| `i/o` | What flows over the connection (TTY, compression) | `ssht`, `sshc` |
| `debug` | Verbose / introspection output | `sshv` |
| `meta` | Wrappers about the package itself | `sshh` |

If your wrapper genuinely fits none of these, you can add a category — but that's a separate decision that needs updates in `index.html` (the `.cats` strip) as well as the metadata line. Don't quietly invent one.

## Files to touch

The checklist below is comprehensive. Every wrapper added since v0.1 has needed all of these.

### 1. `install.sh` — four edits

This is the source of truth. The four edits live in different parts of one file and must all be made.

1. **`ALL_WRAPPERS` constant** (top of file).
   Add the new name. Order matters only for `--list` and `sshh` overview output, both of which read in this order — group by category for readability.

   ```sh
   ALL_WRAPPERS="sshp sshi ssha sshcp sshq sshk sshm ssht sshc sshv sshh"
   #                       ^^^^^ new wrapper goes near its category-mates
   ```

2. **`emit_fn()` case branch**.
   Add a new `case` arm with the function definition wrapped in a `cat <<'EOF' ... EOF` heredoc. Always single-quote the `'EOF'` delimiter — otherwise `$@`, `$HOME`, etc. get expanded at install time instead of at call time, which would silently break the wrapper.

   Include a comment header above the function explaining what it does and why (1–4 lines, no marketing). The comment ships into the user's rc file, so future-them grepping their rc can figure out what `sshcp` is without leaving the terminal.

   ```sh
   sshcp) cat <<'EOF'
   # sshcp — push a key with ssh-copy-id but skip pubkey auth so the
   # agent's loaded keys don't burn through MaxAuthTries before the
   # password prompt. ...
   sshcp() {
       ssh-copy-id -o PubkeyAuthentication=no "$@"
   }
   EOF
       ;;
   ```

3. **`_sshh_data` line inside the `sshh)` heredoc**.
   Pipe-delimited: `name|category|short description|example invocation`. Keep the description ≤60 chars so `sshh` overview alignment stays readable in an 80-col terminal. Quotes inside the example must use `'\''` (the standard POSIX heredoc escape for a single quote inside a single-quoted string).

   ```
   sshcp|auth|ssh-copy-id without pubkey auth (skip MaxAuthTries burn)|sshcp user@host
   ```

4. **Fish snippet** in the `unsupported:fish` error block.
   The installer doesn't manage fish but does print copy-pasteable definitions. Add a one-liner translation:

   ```sh
   function sshcp ; ssh-copy-id -o PubkeyAuthentication=no $argv ; end
   ```

### 2. New `sshX.md` doc

Create one new file at the project root. Use [`sshp.md`](sshp.md) as the structural template:

```
sshX.md
├── logo header block (copy verbatim from any existing wrapper doc)
├── # `sshX` — short title (≤8 words)
├── function code block (the same body emitted in install.sh)
├── ## What it does          ← one paragraph; what option(s) it sets, what they do
├── ## When to use it        ← bulleted list of concrete scenarios
├── ## Usage                 ← 2–4 example invocations covering common flags
├── ## Related               ← cross-links to other wrappers in the same neighborhood
└── ## Notes                 ← edge cases, server-side caveats, the "Forgot the
                                other wrappers? Run sshh" footer pointer
```

Keep the file self-contained. The user lands here from `sshh sshX` and shouldn't need to read the README to understand the wrapper.

### 3. `README.md` — six edits

1. **Lede paragraph count** ("Eleven small POSIX shell wrappers …"). Spelled out, not numeric.
2. **The wrappers table.** Add a row. Keep it in the same order as `ALL_WRAPPERS`.
3. **"Why?" section bullets.** Add a one-line scenario explaining the problem the wrapper fixes.
4. **Usage code block.** Add an example invocation alongside the others.
5. **Per-wrapper docs link list** at the end of "Usage". Append your wrapper to the appropriate category line.
6. **Project layout glob** under "Development". Update the `ssh{…}.md` brace expansion to include your new doc.

### 4. `sshh.md` — three count updates

1. The `sshh                # overview of all N wrappers` example.
2. The sample overview block (add a `✓ sshX [cat] description` line, bump the `N installed · 0 not installed` footer).
3. The "across all N in one go" line near the bottom.

### 5. `index.html` — seven edits

The landing page is hand-maintained HTML; there's no template. Be careful — the `<title>`, three meta descriptions, the badge, the card grid, the install tab(s), the features list, and the footer all reference the count or the wrapper name list.

1. **`<title>`** — "eleven small ssh helpers" / etc.
2. **`<meta name="description">`** — spelled-out count.
3. **`<meta property="og:description">`** and **`<meta property="og:image:alt">`** — same.
4. **`<meta name="twitter:description">`** — also lists every wrapper name. Add yours in `ALL_WRAPPERS` order.
5. **`<span class="badge">N wrappers</span>`** — numeric count.
6. **`.grid` card.** Copy the structure of an existing card, pick an icon from the `<symbol>` defs at the top of the file (or add a new one if none fit), and write a one-paragraph blurb mirroring the wrapper's "When to use it" framing. Insert the card next to its category-mates so the visual grouping matches the table.
7. **Install tabs** (`.tabs > .tab[data-cmd]`) — if your wrapper joins one of the curated subsets ("Auth only", "Connection only"), append the name to that tab's `data-cmd`.
8. **`<ul class="features">`** — "default installs all N" line.
9. **`<footer>`** — "N wrappers" line.

If you added a new category (rare — see "Pick a category" above), also update the `.cats` strip near the top of the body.

### 6. `assets/social-card.svg` + re-render `assets/social-card.png`

This is the file most contributors forget. The social card is the 1280×640 image GitHub and Twitter show as the OG preview, and it visibly lists every wrapper as a chip — so missing it means a stale image ships everywhere the repo is linked.

Edits to `social-card.svg`:

1. **`<svg aria-label="…">`** — update the count and the "around ssh" phrase if you added support for a new underlying tool.
2. **"N wrappers" pill** — the `<text>` inside the first pill at the top.
3. **Tagline** — only if you've changed the framing (e.g. added `ssh-copy-id` as a second underlying tool, like `sshcp` did).
4. **Chip grid** — add a chip. Current layout is 5+5+1: two full rows of 5 plus `sshh` as a featured centered chip on row 3. Each chip is `216×56` with a `14`-unit gap. A chip is:

   ```xml
   <g transform="translate(X, Y)">
     <rect width="216" height="56" rx="12" fill="#111827" stroke="#334155" stroke-width="1"/>
     <circle cx="30" cy="28" r="14" fill="#312e81"/>
     <g transform="translate(22, 20)" fill="none" stroke="#a78bfa" stroke-width="2.4"
        stroke-linecap="round" stroke-linejoin="round">
       <!-- 16×16 icon paths here -->
     </g>
     <text x="58" y="26" font-family="ui-monospace, SF Mono, Menlo, monospace"
           font-size="17" font-weight="700" fill="#f1f5f9">sshX</text>
     <text x="58" y="44" font-size="12" fill="#94a3b8">short label</text>
   </g>
   ```

   Adding a 12th wrapper breaks the 5+5+1 layout — you'll need to re-pack to 6+5+1, 4+4+4, or 6+6 (the last would let `sshh` rejoin the main grid). If you pick a layout that changes row count, slide `<!-- install command -->`, `<!-- post-install hint -->`, and the footer `<text>` down by the same delta so they don't collide with the new bottom row.

   Don't reuse another wrapper's icon. Pick something semantically tied to what the wrapper does (sshcp uses an upload arrow → push-key motion). Keep paths within a 16×16 box so the existing inner-circle and translate offsets still apply.

5. **Re-render the PNG.** The SVG is the source of truth; the PNG is what social previewers actually load. They cache aggressively, so an outdated PNG with a fresh SVG means stale previews for weeks.

   ```sh
   rsvg-convert -w 1280 -h 640 assets/social-card.svg -o assets/social-card.png
   file assets/social-card.png   # must report: PNG image data, 1280 x 640
   ```

   Commit *both* the `.svg` and the regenerated `.png`. CI does not auto-render.

6. **Eyeball the PNG.** Open it. Check the new chip lines up with the grid, the icon is visible at the rendered size (the icon is ~16×16 SVG units → ~16px at 1× output), the text isn't clipped, and nothing collides with the install bar or footer.

`assets/logo.svg` and `assets/logo.png` do not need re-rendering — they have no text and no wrapper count.

### 7. `.github/workflows/shellcheck.yml`

No edits. It lints `install.sh` as-is. Don't add per-wrapper CI; the installer is the only shell file in the repo.

## Verify before opening the PR

Run all four checks. They're fast and catch the mistakes that have actually happened.

```sh
# 1. Lint the installer.
shellcheck --shell=sh install.sh

# 2. Smoke test: install only the new wrapper into a temp file, inspect it.
tmp=$(mktemp)
SSH_WRAPPERS_RC="$tmp" sh install.sh sshX
grep -A2 "^sshX()" "$tmp"   # function body present?
grep -F "# sshX —"    "$tmp"   # comment header present?

# 3. Smoke test: install everything, source it, run sshh.
tmp=$(mktemp)
SSH_WRAPPERS_RC="$tmp" sh install.sh
bash -c ". '$tmp'; sshh"          # overview lists the new wrapper with ✓
bash -c ". '$tmp'; sshh sshX"     # detail view renders cleanly
rm -f "$tmp"

# 4. Count audit. None of these should match anything stale.
grep -rn -E '\b(Ten|ten|Eleven|eleven|Twelve|twelve)\b|[0-9]+ wrappers|all [0-9]+' \
    --include='*.md' --include='*.html' --include='*.sh' .
```

If the count audit shows a number you didn't intend to change, that's a stale reference — fix it before the PR.

## What *not* to add

- A test suite for the wrappers themselves. The wrapper bodies are one-liners; the cost of test infrastructure outweighs the bug surface.
- A new dependency. Every wrapper must work with a POSIX `/bin/sh` installer and stock OpenSSH client.
- A wrapper that hardcodes a username, hostname, key path, or network. Wrappers must accept `"$@"` and pass it straight through.
- A wrapper that prints anything to stdout/stderr beyond what `ssh` itself prints. Users pipe these into scripts; surprise output breaks pipelines.
- A second meta wrapper. `sshh` is the help; don't add `sshls`, `sshmenu`, `sshupdate`, etc. — they're features of `sshh` if they belong anywhere.

## Release

Follow the standard release flow (CHANGELOG entry, `gh release create vX.Y.Z` — never `git tag` directly). Adding a wrapper is a minor-version bump (new feature, no breakage).
