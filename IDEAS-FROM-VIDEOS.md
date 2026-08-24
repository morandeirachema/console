# Improvement ideas — distilled from 4 videos

> **Status:** **P1 implemented** on 2026-07-11 (tmux-sessionizer, fabric, pass,
> deeper fzf previews) — see the *Done* markers below and `ROADMAP.md`. P2/P3
> remain as a shortlist to evaluate, mapped onto what `console` already has.
> **Compiled:** 2026-07-11.

## Sources

Sources 1–3 are by **Mischa van den Burg** (DevOps / stateless-workstation focus);
source 4 is by **Jay LaCroix / Learn Linux TV** (sysadmin Bash/Vim/tmux + Ansible):

1. My Entire Neovim + Tmux + AI Workflow (2026 Update) — <https://www.youtube.com/watch?v=fjoGZ90bOzw>
2. How I Rebuilt My Entire Workstation After Quitting Arch Linux — <https://www.youtube.com/watch?v=S6T5M4jLqR8>
3. 5 CLI Tools That Actually Changed How I Work in 2026 — <https://www.youtube.com/watch?v=tmnd3M1k5Jw>
4. My Daily Driver Terminal Setup (tmux, Vim, Bash, Ansible) — <https://www.youtube.com/watch?v=Q8Fv_BfQuuc>
   (dotfiles zip: <https://learnlinux.link/dotfiles>)

His stack overlaps ours a lot (zsh + tmux + fzf + LazyVim + a "git-centered stateless
workstation" philosophy), so the useful signal is the handful of tools/patterns we **don't**
have yet. Much of the videos is workstation-level (immutable OS, window manager, email
client) and is **out of scope** for a portable shell-dotfiles repo — see the last section.

## TL;DR — what's worth adding

| # | Idea | In videos | Fit | Effort | Priority / status |
| - | ---- | --------- | --- | ------ | ----------------- |
| 1 | **fabric** — AI patterns piped through the CLI | 1, 3 | High | M | **P1 · ✅ done** |
| 2 | **tmux-sessionizer** — fzf-jump to a project as a tmux session | 1, 3 | High | S | **P1 · ✅ done** |
| 3 | **pass** — GPG-encrypted Unix password store | 2, 3 | High | S–M | **P1 · ✅ done** |
| 4 | **Deeper fzf previews** — bat/eza in Ctrl-T / Alt-C / fzf-tab | 3 | High | S | **P1 · ✅ done** |
| 5 | **SSH workflow** — port-forward helpers + `config.local` include | 1, 3 | Med | S | **P2 · ✅ done** |
| 6 | **Alacritty config** — Catppuccin + JetBrainsMono | 1 | Med | M | **P2 · ✅ done** |
| 7 | **NAS sync pattern** — pass-store / backups → Synology NAS | 2 | Med | S | **P2 · ✅ done** |
| 8 | **Notes helper** — Zettelkasten / Johnny-Decimal capture | 1, 2 | Low | S | P3 |
| 9 | **chezmoi** — dotfile manager instead of symlinks | 1 | Low | L | Evaluate → likely decline |

Effort: S ≈ minutes, M ≈ an hour, L ≈ re-architecture.

---

## P1 — ✅ done (high value, in-scope, recurring in the videos)

> Implemented 2026-07-11. Notes below are the original rationale + how each landed
> in the repo; the shipped behavior matches. See `README.md` / `ROADMAP.md`.

### 1. `fabric` — AI patterns from the command line

- **What:** Daniel Miessler's `fabric` runs reusable AI "patterns" (summarize, extract_wisdom,
  write_commit, etc.) as Unix filters. Video 1 pipes its output straight into Neovim; video 3
  lists it as one of the 5 tools. It's the only tool that shows up across **both** relevant videos.
  <https://github.com/danielmiessler/fabric>
- **Maps to us:** a new optional dependency + guarded aliases, exactly like `lazygit`/`neovim`.
  - It's a Go binary not in distro repos → add an `install_fabric_release` GitHub-release helper
    (SHA256-verified, same shape as `install_lazygit_release`) with a `--no-fabric` gate.
  - Guarded aliases in `aliases.zsh` (`command -v fabric` first), e.g. a `fabric` pipe helper and
    a `summarize`/`explain` shortcut.
  - **Secrets:** it needs an API key → that lives in `~/.zshrc.local` (machine-specific), never in
    the repo. Document in `SECURITY.md`.
- **Watch out:** no network at zsh startup (repo rule) — fabric is invoked on demand only, so fine.

### 2. `tmux-sessionizer` — jump to any project as a tmux session

- **What:** the "tmux as a window manager" pattern from videos 1 & 3: one keypress → fzf list of
  project dirs → attach/create a named tmux session for it. Origin ThePrimeagen; Mischa uses a variant.
- **Maps to us:** we already ship `tmux/tmux.conf` **and** `fzf` **and** `fd` — this is the cheapest
  high-value add. A small self-contained `scripts/tmux-sessionizer.sh` (graceful if fzf/fd absent),
  bound in `tmux.conf` (`bind -r f run-shell "tmux neww tmux-sessionizer"`) and optionally a zsh
  `Ctrl-f` binding. `install.sh` symlinks it into `~/.local/bin`.
- **Why it fits:** self-contained, no new heavy deps, matches the existing "keyboard-centered" prompt/tmux setup.

### 3. `pass` — GPG-encrypted password store

- **What:** the standard Unix password manager (GPG-encrypted files in a git repo). Featured in
  videos 2 & 3. <https://www.passwordstore.org/>
- **Maps to us:** `GPG_TTY` is **already exported** in `.zshrc`, so half the groundwork is done.
  - Install via `pkg_install pass` (it's in apt/dnf/pacman/brew) — no release-tarball helper needed.
  - Guarded aliases + an optional fzf "passmenu"-style picker (ties into idea #4).
  - The GPG key + the store repo are per-machine → `~/.zshrc.local` / documented, not committed.
  - **Positioning:** complements, doesn't replace, the existing 1Password/Vault ssh-agent notes in
    `SECURITY.md` — add `pass` as the lightweight, self-hosted option there.

### 4. Deeper fzf previews

- **What:** video 3's fzf deep-dive is mostly about rich previews. We already have Ctrl-R / Ctrl-T /
  Alt-C wired and fd driving fzf, but the **preview** is minimal (fzf-tab `cd` shows plain `ls`).
- **Maps to us:** small edits in `aliases.zsh` / `.zshrc`, all behind existing `command -v` guards:
  - `FZF_CTRL_T_OPTS` → `bat`/`batcat` file preview.
  - `FZF_ALT_C_OPTS` → `eza --tree` directory preview.
  - fzf-tab `cd` preview → `eza`/`bat` instead of bare `ls`.
  - (Optional) reuse the same picker for the `pass` menu in idea #3.
- **Why it fits:** pure polish on tooling we already ship; degrades gracefully.

---

## P2 — nice, but narrower payoff

### 5. SSH workflow helpers — ✅ done (2026-07-13)

- Video 3 spends a chapter on "SSH beyond logging in" + port-forwarding into remote containers.
- **Shipped:** three guarded zsh helpers in `zsh/aliases.zsh` — `fwd` (local `-L`), `rfwd` (remote
  `-R`), `socks` (dynamic `-D` SOCKS proxy) — each foreground with a keep-alive (`ServerAliveInterval=60`)
  and a status line; bad args exit 2. Documented the `Include ~/.ssh/config.local` pattern (host entries
  stay machine-specific, `chmod 600`, never committed — same philosophy as `~/.zshrc.local`). README has a
  guided-tour section; SECURITY.md notes tunnels bind localhost by default (no `GatewayPorts`).

### 6. Alacritty config — ✅ done (2026-07-12)

- Video 1's terminal is Alacritty + zsh + tmux.
- **Shipped:** `alacritty/alacritty.toml` (Catppuccin Mocha + JetBrainsMono Nerd Font to match the
  prompt/tmux/nvim), symlinked to `~/.config/alacritty/`. Installed by default on desktops (brew
  `--cask` on macOS, `pkg_install` elsewhere), skipped by `--minimal`/`--server`/`--no-alacritty`.
  Removes the manual "set your terminal font" step. TOML validated in CI; symlink asserted by the
  `extras` job. Other terminals (e.g. kitty) still work — nothing depends on Alacritty.

### 7. Synology NAS sync pattern — ✅ done (2026-07-13)

- Video 2 syncs the password store / files to a Synology NAS. The user's NAS (192.168.1.211) speaks
  **SMB/CIFS only** — SSH/NFS/rsync-daemon are closed (see the `nas-backup-target` memory), so the path is
  mount-then-rsync-to-the-mount, not rsync-over-ssh.
- **Shipped:** `scripts/nas-sync.sh` (symlinked to `~/.local/bin/nas-sync`) rsyncs `$NAS_SYNC_PATHS`
  (default `~/backup` + `~/.password-store`) to a configurable `$NAS_DEST` — transport-agnostic (a mount
  path OR an ssh target). Additive (no `--delete`), `-n` dry-run, guards on missing rsync/NAS_DEST.
  `zshrc.local.example` documents the CIFS-mount recipe (placeholders); README + SECURITY cover it; CI
  asserts the symlink + guard on ubuntu/fedora/arch. Host/creds stay per-machine (never the repo).

---

## P3 — later / low priority

### 8. Notes capture (Zettelkasten / Johnny-Decimal)

- Both video 1 (Zettelkasten update) and video 2 (Johnny-Decimal file org) cover note systems.
- **Maps to us:** at most a tiny `note`/`zk` capture alias opening a dated markdown file in `$EDITOR`
  (nvim is already the default). Personal-workflow territory — only if the user wants it.
  <https://johnnydecimal.com/>

---

## Evaluate, then most likely **decline**

### 9. `chezmoi` instead of symlinks

- Video 1 manages dotfiles with **chezmoi** (templating, secrets, per-machine diffs).
  <https://www.chezmoi.io/>
- **Reality for us:** the repo's whole model is the **symlink** approach — documented in `CLAUDE.md`,
  covered by CI, with `install.sh`/`uninstall.sh` built around it. Switching to chezmoi is a
  re-architecture, not an add-on, and we'd lose the "edit repo file = edit live shell" property.
- **Recommendation:** don't migrate. If per-machine templating ever becomes painful, revisit — but
  `~/.zshrc.local` + the accent-profile pattern already cover the real cases. Noted for completeness.

---

## Deliberately out of scope (workstation-level, not shell-dotfiles)

These are big parts of the videos but don't belong in a portable zsh-dotfiles repo. Listed so the
decision is explicit, not an oversight:

- **Immutable OS** — Fedora Atomic / rpm-ostree / Cosmic / Sway vs Hyprland (videos 1 & 2).
- **Containerized dev envs** — toolbox, flatpak, Podman, DevPod, devcontainers (videos 1 & 2).
  <https://containers.dev> · <https://devpod.sh>
- **Terminal email** — Aerc (video 1). <https://aerc-mail.org>
- **Self-hosted git** — Forgejo (video 1). <https://forgejo.org>
- Browser choice / privacy (video 1).

If any of these are wanted, they should be their **own** repo/setup, not folded into `console`.

---

## Suggested order if we proceed

1. **#2 tmux-sessionizer** + **#4 fzf previews** — small, self-contained, zero new heavy deps,
   immediate daily payoff.
2. **#3 pass** — groundwork (`GPG_TTY`) already exists; slots into `SECURITY.md`.
3. **#1 fabric** — the biggest new capability; needs a release-installer helper + a `--no-fabric` gate.
4. Then P2 items (SSH, Alacritty, NAS) as appetite allows.

Every item above must keep the repo's hard rules: `command -v` graceful degradation, no network at
startup, secrets/host-specifics only in `~/.zshrc.local`, route installs through `pkg_install` (or a
SHA256-verified release helper), and stay CI-green.

---

## Source 4 — Learn Linux TV (sysadmin Bash/Vim/tmux + Ansible)

Added 2026-07-12 from **Jay LaCroix / Learn Linux TV** — *"My Daily Driver Terminal Setup (tmux, Vim,
Bash, Ansible)"* (<https://www.youtube.com/watch?v=Q8Fv_BfQuuc>); dotfiles zip
<https://learnlinux.link/dotfiles>. His stack is **Bash + Vim** (we're zsh + Neovim/LazyVim), so the
shell/editor specifics don't port — but several sysadmin-grade tmux and shell helpers do, and they
fit this repo's "safe on servers" posture. I read his actual `tmux.conf`, `bashrc`, `bash/aliases`,
`bash/functions`, and `bash/prompt`.

### Worth taking

| Idea | What it is | Fit | Effort | Cross-platform note |
| ---- | ---------- | --- | ------ | ------------------- |
| **tmux `synchronize-panes` toggle** | `prefix y` → type one command into every pane at once | High (multi-server ops) | S | tmux-native, safe everywhere |
| **`extract()`** | one function unpacks tar/gz/xz/zip/7z/rar/… | High | S | uses standard tools; guard each |
| **`mkcd` / `md`** | `mkdir -p` + `cd` in one step | High | S | portable |
| **tmux window mgmt** | Shift-←/→ switch windows · Ctrl-Shift-←/→ swap windows | Med | S | tmux-native |
| **Safety-net aliases** | `cp -iv` `mv -iv` `ln -iv` `mkdir -pv` `rm -I` (prompt before clobber) | Med (privileged boxes) | S | ⚠️ `rm -I` / `--preserve-root` are GNU-only — guard for macOS |
| **Resource one-liners** | `mem10` `cpu10` `dir10` (top RAM / CPU / dirs) | Med | S | ⚠️ `ps auxf` forest + `sort -h` are GNU — guard for macOS |
| **`weather`** | `curl wttr.in` | Low | S | on-demand network only |
| **Ansible fleet deploy** | a playbook/role to roll this repo onto many hosts (his `ansible-pull` model) | Med (fleets) | L | parallel to our symlink model |

### Deliberately skipped (don't fit this repo)

- **Prefix `C-j`/`C-f`** instead of `C-b` — we keep `C-b` on purpose (documented).
- **`cd` auto-runs `ls`** — divisive, and we lean on zoxide + `AUTO_CD`.
- **`tssh` = ssh with host-key checking disabled** — a security anti-pattern that conflicts with our
  production posture.
- **`@continuum-boot`** (auto-start a tmux systemd service on boot) — too invasive to enable by default.
- **Vim / `vimrc` + the Bash prompt** — we use LazyVim + starship, both richer.

### Recommended first picks

`synchronize-panes` (`prefix y`), `extract()`, and `mkcd` — all small, universal, high-utility. Then
the tmux window switch/swap keys. The safety-net and resource aliases are worth it too but need macOS
guards (flagged above), matching the cross-platform bar the P1 / Alacritty work already holds to.
