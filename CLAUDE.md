# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal **zsh dotfiles** repo, cloned onto multiple Linux machines. There is no build, no test
runner, and no application code — the "product" is shell configuration applied via symlinks. The stack
is zinit (plugins) + starship (prompt) + fzf + zoxide + eza/bat.

## Commands

```bash
./install.sh                 # apply config on this machine (idempotent — safe to re-run)
./install.sh --minimal       # zsh + plugins + prompt + fzf/bat/fd/rg; skips eza, the extras block, terminals, nvim, font
./install.sh --no-font       # skip the Nerd Font download
./install.sh --no-chsh       # don't change the default login shell
exec zsh                     # reload the shell after editing config

# Validate before committing (there are no unit tests — syntax-check instead):
zsh  -n zsh/.zshrc
zsh  -n zsh/aliases.zsh
bash -n install.sh
python3 -c "import tomllib; tomllib.load(open('starship/starship.toml','rb'))"   # TOML parses
```

Do **not** run bare `starship config` to validate the prompt — it opens `$EDITOR` and hangs a
non-interactive session. Use the `tomllib` check above, or `starship print-config`.

## How it fits together (the important part)

**Symlink model.** `install.sh` symlinks repo files into `$HOME`, it does not copy them:

- `zsh/.zshrc` → `~/.zshrc`
- `starship/starship.toml` → `~/.config/starship.toml`

Consequence: **after `install.sh` has run once, editing a file in this repo edits the live shell.**
There is no rebuild step — just `exec zsh`. When applying, install.sh moves any pre-existing real
`~/.zshrc` to `~/.zshrc.pre-console.<timestamp>` before linking.

**Self-location.** `zsh/.zshrc` finds its own repo directory at runtime with
`ZDOTREPO="${${(%):-%x}:A:h}"` (resolves the symlink) and sources `aliases.zsh` from there. Because of
this, **`aliases.zsh` must stay in `zsh/` next to `.zshrc`** — moving it breaks the source path.

**Plugins load via zinit TURBO mode (async).** zinit bootstraps by cloning itself into
`~/.local/share/zinit` on first launch, then plugins load *after* the first prompt via
`zinit wait lucid` — startup is instant, but autosuggestions/highlighting activate a few ms
in. Consequences that must be preserved when editing the plugin block:

- `compinit` runs **once**, inside the first turbo wave's `atinit` (`zicompinit; zicdreplay`).
  Do **not** add a synchronous `compinit`/`zinit cdreplay` too, or it runs twice.
  The one exception is the `else` branch taken when zinit is missing (clone failed/offline):
  it runs a plain `compinit -i` so the shell still has completion.
- A keybinding for an async plugin (e.g. history-substring-search's Up/Down/Ctrl-P/N) must be
  set in that plugin's `atload` hook — the widget does not exist until the async load finishes.
  Binding it at top level silently no-ops.
- `fzf-tab` sits in the second wave so it loads after compinit and after the widget-wrapping
  plugins (fast-syntax-highlighting, autosuggestions), per its load-order requirement.

**Graceful degradation is a hard rule.** Every external tool in `.zshrc` and `aliases.zsh` is guarded
with `command -v <tool>` so a fresh box with nothing installed still starts. Keep this pattern for any
new tool. Note `bat` is installed as `batcat` on Debian/Ubuntu — `aliases.zsh` already handles both names.

**Machine-specific config never goes in the repo.** Local paths, secrets, and per-host aliases belong
in `~/.zshrc.local`, which `.zshrc` sources last and `.gitignore` excludes. Don't hardcode host-specific
values into the tracked files.

**install.sh portability.** It detects the package manager (**brew** on macOS, else apt/dnf/pacman/zypper)
via a `pkg_install` wrapper and installs user-local where possible (starship and zoxide into `~/.local/bin`
on Linux, or via brew on macOS). `SUDO` is empty for brew (Homebrew must not run under sudo). New
dependencies should route through `pkg_install` with a graceful `warn` fallback rather than assuming apt.
macOS specifics already handled: font via `--cask font-jetbrains-mono-nerd-font`, neovim via brew (the
`install_neovim_release` Linux-tarball fallback is Linux-only), no `gcc/make` (Xcode CLT provides `cc`),
and the chsh step is skipped when the login shell is already any `*/zsh` (so brew-zsh doesn't fight
system-zsh). Debian's `fdfind`/`batcat` binary names are handled in `aliases.zsh`; brew ships real
`fd`/`bat`, so both paths work.
The terminal install.sh installs is **Ghostty** (`ghostty/config`; brew cask on macOS, `pkg_install` on
Arch/Fedora, a `warn` pointing at ghostty.org/download on Debian/Ubuntu, which have no official package).
Alacritty and kitty configs are shipped and symlinked but never installed. All three presets must keep the
same Catppuccin Mocha hexes and font; the Ghostty one must keep `ssh-terminfo` enabled or `TERM=xterm-ghostty`
breaks on servers.
**atuin owns Ctrl-R.** `.zshrc` runs `atuin init zsh --disable-up-arrow` *after* the fzf block so its
binding wins; fzf keeps Ctrl-T/Alt-C and is the Ctrl-R fallback when atuin is absent. Keep
`enter_accept = false`, `update_check = false` and `auto_sync = false` in `atuin/config.toml` (nothing runs
on Enter, no network at startup). **sesh** is reached only through `scripts/sesh-picker.sh` (symlinked to
`~/.local/bin/sesh-picker`): tmux's `prefix f` and the `proj` function both call it, and it falls back to
`tmux-sessionizer` when sesh is missing, so never bind sesh directly in `tmux.conf`. **superfile**'s config
path differs per OS; use `spf_cfg_dir` in install.sh rather than hardcoding `~/.config/superfile`.
**Config links honour `XDG_CONFIG_HOME`** through `$CFG` in install.sh (snapshot, doctor, uninstall and the
tools themselves already did) — never write a literal `$HOME/.config` in a new `link` line. install.sh also puts
`~/.local/bin` on its own PATH so a release-binary fallback is visible to the same run (and to CI's checks).
**Nerd Font glyphs in config files are easy to lose**: some editors/tools strip private-use characters.
`starship/starship.toml` must contain its pill caps (U+E0B6/U+E0B4) and icons; check with
`python3 -c "t=open('starship/starship.toml',encoding='utf-8').read(); print(len([c for c in t if ord(c)>=0xE000]))"`
(expect ~56). The README prompt sample and MANUAL screenshots depend on them.
**Screenshots** in `docs/screenshots/` are real captures: a headless `tmux -L shots` pane running the repo's
zsh in a throw-away HOME (symlinks to the real `.config`/`.local`, a curated `.zsh_history`, isolated atuin
and zoxide DBs so nothing private leaks), `capture-pane -e` → a small ANSI-to-HTML script → headless Chrome.
Regenerate them the same way rather than pasting terminal screenshots with personal data.
Tools that are often absent from distro repos (lazygit, neovim, atuin, sesh, superfile, carapace, fabric) have
`install_*_release` helpers that fetch the right arch tarball from GitHub into `~/.local/bin` and verify its
SHA256 against the release's checksum file — follow that pattern for similar tools.

**Neovim / LazyVim is vendored, not cloned per machine.** `nvim/` holds the LazyVim *starter* (init.lua +
`lua/config/*` + `lua/plugins/*`); `install.sh` symlinks the whole dir to `~/.config/nvim`. The LazyVim
framework itself and all plugins are pulled from the internet by lazy.nvim on the first `nvim` launch — so
`nvim/` stays tiny. When it runs, lazy.nvim writes `lazy-lock.json` into `~/.config/nvim` (= into this repo,
via the symlink); commit it to pin identical plugin versions across machines. Editor extras go in
`nvim/lua/plugins/`. The whole nvim step is gated behind `--no-nvim` (and skipped by `--minimal`) so a
machine with its own nvim config isn't clobbered. `lazygit/config.yml` is symlinked as a single file (not the
whole dir) so lazygit's runtime `state.yml` stays local and out of the repo.

## Conventions

- Keep shell startup fast: no network calls at startup beyond zinit's one-time self-clone, and never
  link a remote webfont.
- `install.sh` adds one `include.path` entry to `~/.gitconfig` pointing at `git/delta.gitconfig` — the
  **only** state it changes outside `$HOME` dotfile symlinks. It is additive/revertible on purpose (do NOT
  switch back to writing individual global keys — that clobbers an admin's existing pager). The include is
  added only if not already present, so re-runs stay idempotent.
- **Production/security posture (see `ROADMAP.md`).** This is used on servers and privileged boxes, so keep
  these invariants when editing: `compinit` runs with `-i` (never `-C` — `-C` skips the insecure-fpath
  check); `~/.zshrc.local` is sourced only when `-O` (owned by the user); prefer `pkg_install` over
  `curl | sh` (piped installers are a labelled fallback only); the prompt's `username`/`hostname` (SSH/root)
  and `kubernetes`/`aws` segments are safety features — don't remove them. `--server` skips the font and every
  terminal config on headless hosts; WSL (detected via `/proc/version`) does the same automatically and installs
  `windows-terminal/console.json` as a Windows Terminal fragment instead.
- Commits use no Claude author/co-author references.
