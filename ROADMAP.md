# Roadmap — hardening for production sysadmin / DevOps / PAM use

This repo started as a personal desktop shell. This file tracks what was done to
make it safe and pleasant on servers and privileged workstations, and what's
still worth doing. Priority: **P1 = do next**, P2 = nice, P3 = later.

## ✅ Done (this pass)

- **compinit `-C` → `-i`** — no longer bypasses the insecure-completion-dir
  security check (completion-injection / privesc risk on shared hosts).
- **`~/.zshrc.local` is only sourced if owned by you** — blocks another account
  from planting a file that runs in your shell.
- **git-delta via `include.path`, not global-key overwrites** — additive and
  revertible; never rewrites an admin's existing `~/.gitconfig`.
- **Prefer signed packages over `curl | sh`** — starship/zoxide install from the
  distro/brew package first; the piped installer is only a labelled fallback.
- **Prompt tells you WHERE you are** — `user@host` shows over SSH (root in red),
  and Kubernetes context + AWS profile/region show when set. Prevents
  "ran it on the wrong box / wrong cluster / wrong account".
- **`--server`** flag skips the Nerd Font on headless boxes.
- **Cross-platform** installer (Linux apt/dnf/pacman/zypper + macOS Homebrew).
- **CI** — GitHub Actions: shellcheck + `bash -n`/`zsh -n` + toml/gitconfig/lua
  validation, and a smoke test that runs `./install.sh --minimal` in
  ubuntu/fedora/arch containers.
- **Supply-chain: verify downloads** — lazygit & neovim release binaries are now
  SHA256-checked against their published checksums before install; refuse on
  mismatch. `ZINIT_PIN` env var pins zinit to a commit/tag for reproducible builds.
- **Fixed** a latent bug (found by CI): `.zshrc` left `$?=1` with no
  `~/.zshrc.local`, which showed a false error on the first prompt.
- **`--offline` mode** — skips every internet fetch (curl installers, release
  binaries, font); packages come from your mirror.
- **Secrets hygiene** — `SECURITY.md` documents history/secret handling; `GPG_TTY`
  is set for signing; `zsh/zshrc.local.example` is a starter template; ssh-agent
  is left to the platform with an opt-in snippet.

## ✅ Done (P2 batch)

- **tmux config** (`tmux/tmux.conf`, symlinked) — mouse, vi copy, cwd-preserving
  splits, Catppuccin status bar matching the prompt.
- **`jq` / `yq`**, **direnv** (hooked in `.zshrc`), **carapace** (guarded
  completion hook) — added to the installer's extras.
- **Air-gapped plugin vendoring** — `scripts/vendor-plugins.sh` pre-seeds zinit +
  all plugins so `--offline` needs zero network on first launch.
- **XDG layout** — opt-in `--xdg` puts `.zshrc` under `ZDOTDIR=~/.config/zsh`.
- **Gate-able prompt** — `kubernetes`/`aws` segments ship with commented
  `detect_*` filters to scope them to infra dirs.

## P1 — last mile

- **Deeper pinning.** A full plugin lockfile (exact commit per plugin) and
  per-distro tool-version pins for byte-reproducible rebuilds. `ZINIT_PIN` +
  `scripts/vendor-plugins.sh` cover the common cases; this is what's left.

## ✅ Done (P3 batch)

- **Audit log** — `install.sh` records every step to
  `~/.local/state/console/install-<ts>.log` for change-management/review.
- **`uninstall.sh`** — reverses only the symlinks that point into this repo and
  the git-delta include; never touches real files or packages.
- **1Password / Vault SSH-agent** — documented in `SECURITY.md` (point
  `SSH_AUTH_SOCK` at the external agent; keys stay in the vault/HSM).
- **Per-host profiles** — `~/.zshrc.local` hook + `zshrc.local.example` show a
  prod-vs-staging prompt-accent pattern.

## ✅ Done (video-ideas P1 batch)

Ideas taken from three Mischa van den Burg videos (see
[`IDEAS-FROM-VIDEOS.md`](IDEAS-FROM-VIDEOS.md)):

- **tmux-sessionizer** — `prefix f` fzf-jumps to a project as a tmux session
  (`scripts/tmux-sessionizer.sh`, on `PATH`; roots via `TMUX_SESSIONIZER_PATHS`).
- **fabric** — AI patterns as Unix filters; SHA256-verified release installer +
  `--no-fabric` gate; keys stay in `~/.zshrc.local` (`fab`/`fsum`/`fexplain`/`ytsum`).
- **pass** — GPG-encrypted password store (`pw`/`pwc`/`passf`); documented in `SECURITY.md`.
- **Deeper fzf previews** — bat for files, eza-tree for dirs in Ctrl-T / Alt-C /
  fzf-tab, `Ctrl-/` toggles the preview. Uses colon preview-window syntax so it
  never errors on old fzf (< 0.28), verified against fzf 0.24 / 0.29 / 0.67.
- **CI now covers the extras path** — a non-minimal `extras` job installs
  pass/fabric/tmux-sessionizer/alacritty on Ubuntu/Fedora/Arch and asserts them via
  `scripts/ci-extras-check.sh` (fabric + alacritty binaries are soft checks).
- **Alacritty** (P2) — `alacritty/alacritty.toml`, Catppuccin Mocha + JetBrainsMono
  Nerd Font, symlinked; installed by default on desktops, skipped by
  `--server`/`--no-alacritty`. Removes the manual "set your terminal font" step.

## ✅ Done (hardening pass)

- **CI now tests reversibility** — the `extras` job runs `./uninstall.sh` and
  asserts (via `scripts/ci-uninstall-check.sh`) that every symlink is gone, on
  Ubuntu/Fedora/Arch. Protects the "reversible" guarantee against regressions.
- **Authenticated GitHub API** — the release-binary version lookups
  (lazygit/carapace/fabric) use `GITHUB_TOKEN`/`GH_TOKEN` when present to avoid the
  anonymous rate limit; CI passes a least-privilege (`contents: read`) token.
- **`--dry-run`** — prints every package/symlink/change a run would make and
  touches nothing (verified: zero filesystem writes in an isolated `$HOME`).
- **`--doctor`** — health check for tools, symlinks (→ repo), Nerd Font, and the
  git-delta include; side-effect-free (routes nvim's state to a throwaway dir).
  Later fixed a `grep -q`/SIGPIPE-under-`pipefail` false-negative in the font check
  (also in the install-decision) — use `grep -c`; and made bat/fd report once
  (Debian names them batcat/fdfind).
- **kitty config** — `kitty/kitty.conf` (Catppuccin Mocha + JetBrainsMono Nerd Font,
  matching Alacritty), linked whether or not kitty is installed; `--no-kitty` to skip.

## ✅ Done (bootstrap pass)

- **`bootstrap.sh`** — closes the chicken-and-egg where `install.sh` installs `git`
  but you need `git` to clone the repo that holds `install.sh`. POSIX `sh` (runs
  before bash is guaranteed), installs git/curl/bash via the detected package
  manager, clones, then hands off. Download-then-run, not `curl | sh`; refuses to
  clobber a non-git directory; `--dry-run`, `--no-install`, `--dir`, `--repo`.
  CI proves it on **git-less** ubuntu/fedora/arch images.

## Future ideas

- Full byte-reproducible plugin lockfile (see *P1 — last mile*).
- Pin release-binary versions (fabric/lazygit/neovim/carapace fetch `latest`) for
  reproducibility, mirroring `ZINIT_PIN`.
- **All video-idea P1/P2 items are done** (see [`IDEAS-FROM-VIDEOS.md`](IDEAS-FROM-VIDEOS.md)):
  fabric · pass · tmux-sessionizer · fzf previews · Alacritty · SSH port-forward
  helpers · **NAS sync** (`nas-sync` rsyncs `~/backup` + the `pass` store to a
  configurable `NAS_DEST`; SMB-mount recipe in `zshrc.local.example`).
