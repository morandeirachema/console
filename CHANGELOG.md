# Changelog

All notable changes to **console**. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
there are no version numbers because the repo is applied by `git pull`, so entries are grouped by the day
they landed on `main`. Newest first.

## 2026-10-19

### Added

- **WSL support**: install.sh detects WSL, skips the Linux font download and the terminal presets, and
  installs a Windows Terminal fragment (`windows-terminal/console.json`) with the Catppuccin scheme and a
  "console (WSL)" profile using the Nerd Font. WSL-only `open`, `pbcopy`, `pbpaste` and `winhome` helpers.
  README and MANUAL gained a Windows section.
- `Ctrl-→` / `Ctrl-←` move by word (and accept one word of an autosuggestion); `Alt-F`/`Alt-B` already did.

- **Ghostty** is the terminal `install.sh` installs on desktops (`ghostty/config`, Catppuccin Mocha +
  JetBrainsMono Nerd Font, `ssh-terminfo` so `TERM=xterm-ghostty` works on servers). `--no-ghostty` skips it.
- **atuin** replaces fzf for `Ctrl-R`: history in a SQLite database, fuzzy search, secrets filter, leading-space
  commands never recorded, `Enter` edits instead of running. `atuin/config.toml`; no network at startup; sync is opt-in.
  Existing zsh history is imported once by the installer. `h` opens the same search from the command line.
- **sesh** behind `prefix f` (and `proj` from the shell): one fuzzy list of running tmux sessions, zoxide
  directories and `sesh/sesh.toml` sessions, in a tmux popup. `scripts/sesh-picker.sh` falls back to the
  bundled `tmux-sessionizer` where sesh is absent. `prefix S` flips to the previous session.
- **superfile** (`spf` / `fm`): TUI file manager themed to match, `bat` previews, zoxide jumps, cd-on-quit.
  `superfile/config.toml` is linked to the XDG dir on Linux and `~/Library/Application Support` on macOS.
- `MANUAL.md`: the full reference with real screenshots (`docs/screenshots/`), and this `CHANGELOG.md`.
- Release-binary fallbacks with SHA256 verification for atuin, sesh and superfile, following the lazygit pattern.
- CI validates the new TOML files, lints `ghostty/config` as `key = value`, runs `ghostty +validate-config`
  where the binary exists, and parses every script under `scripts/`.

### Changed

- The GitHub repo was renamed from `zsh` to **`console`**; clone, bootstrap and badge URLs updated
  (old URLs redirect).
- **Alacritty is link-only** now, like kitty: its preset is still shipped and symlinked, but the installer no
  longer installs it. `--no-alacritty` means "don't link".
- `--doctor` reports ghostty, atuin, sesh and spf; the pre-install snapshot, `uninstall.sh` and the CI
  uninstall check cover every new symlink.
- Upgraded the stack on the maintainer's machine (starship 1.27, fzf 0.74, bat 0.26, ripgrep 15.2,
  delta 0.20, Neovim 0.12.6, tmux 3.8) and refreshed `nvim/lazy-lock.json`.

### Fixed

- Two independent review passes after the terminal work: install.sh now puts `~/.local/bin` on its own
  PATH (release-binary fallbacks were invisible to the same run and to the CI checks); the one-time history
  import uses `atuin import zsh` (the installer runs from bash, so `auto` imported the wrong shell); atuin's
  init runs with `--disable-ai` so `?` stays a plain key; every config symlink honours `XDG_CONFIG_HOME`;
  `uninstall.sh` removes the `--xdg` ZDOTDIR line from `~/.zshenv`; the Nerd Font zip is SHA256-verified;
  Arch installs use `pacman -Syu --needed` (no partial upgrades); `prefix f` shows a message instead of
  "returned 127" when the picker is missing; sesh-picker explains a missing fzf and works without fzf-tmux;
  `fzf --zsh` is executed once at startup instead of twice; `zshrc` alias follows `--xdg`.
- Docs corrected: `--minimal` keeps fzf/bat/fd/rg; `--server` skips all terminal configs; superfile's real
  key bindings; atuin `Tab` behaviour; `ZINIT_PIN` belongs in `~/.zshenv`; resurrect callout markdown; stale
  ROADMAP/IDEAS statements; a NAS address removed from the docs.
- **The prompt never showed its icons.** Every Basic-Multilingual-Plane Nerd Font glyph in
  `starship/starship.toml` (pill caps, folder, branch, OS, language, docker, aws, clock, hourglass icons)
  had been stripped since the first commit, leaving empty strings; only the two supplementary-plane
  glyphs survived. Restored all 56. The README's prompt sample had the same problem.
- Inside a git repo starship renders `repo_root_format` instead of `format`, and it had never been given the
  pill caps or the folder icon, so the directory pill was bare exactly where it is seen most. Now set explicitly.
- CI's Ghostty validation used `--config-file <path>` (unsupported); the flag only accepts `--config-file=<path>`.
- `lazygit/config.yml` migrated by lazygit itself from `git.paging` to the new `git.diffRenderers` schema
  (lazygit rewrites the file on launch; committing it keeps every machine on the current schema).

## 2026-09-29

### Added

- `--doctor` lists optional items (kitty, alacritty, `~/.zshrc.local`, fc-list on macOS) without counting them
  as problems.
- SHA256 verification for the tree-sitter CLI download.
- A macOS CI job (brew path, zero-write dry-run/doctor check, real `--minimal` install) and markdownlint
  enforcement on the docs.

### Fixed

- fzf key bindings are found on Fedora/RHEL and Arch, not only Debian/Ubuntu.
- The shell degrades gracefully when the zinit clone fails: plain `compinit -i`, a `.clone-failed` marker
  stops retries, `--doctor` reports it with the retry command.
- `--help` prints only the usage header.
- The `nas-sync` link is covered by the snapshot and `--doctor`.

## 2026-08-24

### Added

- `bootstrap.sh`: install git, clone, hand off to `install.sh` on a bare box.
- tree-sitter CLI install; Neovim floor raised to 0.11.2.
- markdownlint configuration (MD013 at 120, tables and code exempt).

### Changed

- LazyVim upgraded v14.14 → v16.0.0; nvim-treesitter pinned to `master`; `lazy-lock.json` refreshed.
- `actions/checkout` v4 → v7; CI smoke assertions can actually fail.

### Fixed

- Every markdownlint diagnostic, including two real README mistakes.
- `--doctor` checks the kitty config symlink.

## 2026-07-13

### Added

- kitty terminal preset (`kitty/kitty.conf`), linked whether or not kitty is installed.
- `nas-sync`: rsync `~/backup` and the `pass` store to a NAS or any rsync target; SMB mount recipe.
- SSH port-forwarding helpers `fwd`, `rfwd`, `socks`.
- The README rewritten as a beginner-first guide.

### Changed

- The consolidated pre-change backup moved to `~/backup/zsh/<timestamp>`.

### Fixed

- A false-negative font check caused by `grep -q` SIGPIPE under `pipefail`.

## 2026-07-12

### Added

- `--dry-run` (preview, zero writes) and `--doctor` (health check).
- A consolidated pre-change backup before every real run.
- Alacritty terminal preset (Catppuccin Mocha + Nerd Font).
- CI tests uninstall reversibility and authenticates GitHub API lookups.

## 2026-07-11

### Added

- fabric (AI patterns CLI), pass (GPG password store), tmux-sessionizer, richer fzf previews.
- tmux session persistence via tpm + resurrect + continuum (pane contents off for safety); system-clipboard
  copy over OSC 52; repeatable resize; Alt-arrow pane switching.
- `--offline` air-gapped mode; `--xdg` layout; `scripts/vendor-plugins.sh` for air-gapped plugin seeding.
- jq, yq, direnv, carapace; tmux config with a Catppuccin status bar; LazyVim infra language extras.
- `uninstall.sh`, an install audit log, notes on external ssh agents (1Password, Vault).
- carapace release fallback, checksum-verified.
- CI: non-minimal "extras" job (pass, fabric, tmux-sessionizer); shellcheck for every script.

### Changed

- README restructured: hero, badges, callouts, collapsible deep-dives.

### Fixed

- Portability for old fzf releases and macOS bash 3.2.

## 2026-07-10

### Added

- First release: zinit (turbo mode) + starship + fzf + zoxide + eza + bat, one-command `install.sh`.
- fd, ripgrep, git-delta, tealdeer, zsh-you-should-use, lazygit, Neovim/LazyVim (vendored config).
- Native macOS/Homebrew support (brew packages, font cask, OS-aware `ports` and `chsh`).
- Production hardening (`SECURITY.md`, `zshrc.local.example`, `GPG_TTY`, `compinit -i`, `ZINIT_PIN`,
  checksum-verified neovim/lazygit binaries).
- GitHub Actions: shellcheck, lint, multi-distro smoke test.
- Prompt: rounded pill segments, Catppuccin Mocha palette, right-aligned command duration and clock,
  auto-hiding empty segments.
- `CLAUDE.md` with the repo's working rules.

### Fixed

- `$?` was 1 on a fresh shell (false first-prompt error); exit code of `install.sh --minimal`.
