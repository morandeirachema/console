#!/usr/bin/env bash
# CI helper — assert the non-minimal "extras" installed correctly.
# Run inside a distro container from the repo root, AFTER:
#     ./install.sh --no-nvim --no-font --no-chsh -y
# Usage: scripts/ci-extras-check.sh <distro-name>
#
# NOT `set -e`: we tally every check and report them all, then exit non-zero if
# any hard check failed. fabric is a soft check (its install fetches a GitHub
# release, so a network / API-rate-limit miss must not fail the build).
set -uo pipefail

name="${1:-?}"
fail=0
ok()   { printf '  \xe2\x9c\x93 %s\n' "$1"; }             # green-ish check
bad()  { printf '  \xe2\x9c\x97 %s\n' "$1"; fail=1; }     # cross
note() { printf '  ! %s\n' "$1"; }

bin="$HOME/.local/bin/tmux-sessionizer"

# --- tmux-sessionizer: symlinked, executable, runnable ---
[ -L "$bin" ] && ok "tmux-sessionizer symlinked" || bad "tmux-sessionizer symlink missing"
[ -x "$bin" ] && ok "tmux-sessionizer executable" || bad "tmux-sessionizer not executable"
# nas-sync symlinked + its "no NAS_DEST" guard exits non-zero cleanly (not a crash)
[ -L "$HOME/.local/bin/nas-sync" ] && ok "nas-sync symlinked" || bad "nas-sync symlink missing"
( unset NAS_DEST NAS_SYNC_PATHS; "$HOME/.local/bin/nas-sync" </dev/null >/dev/null 2>&1 ); ec=$?
[ "$ec" -ge 1 ] && [ "$ec" -le 2 ] && ok "nas-sync guard exits $ec without config" || bad "nas-sync misbehaved (exit $ec)"
if [ -x "$bin" ]; then
  "$bin" </dev/null >/dev/null 2>&1; ec=$?
  # 0 = fzf ran but no TTY/selection; 1 = fzf-absent guard. Anything else = crash.
  [ "$ec" -le 1 ] && ok "tmux-sessionizer runs cleanly (exit $ec)" || bad "tmux-sessionizer crashed (exit $ec)"
fi

# --- pass installed ---
command -v pass >/dev/null && ok "pass installed" || bad "pass missing"

# --- fzf preview opts get exported when aliases are sourced (needs fzf) ---
if command -v fzf >/dev/null; then
  if zsh -c 'source zsh/aliases.zsh; [[ -n $FZF_CTRL_T_OPTS && -n $FZF_ALT_C_OPTS && -n $FZF_CTRL_R_OPTS ]]'; then
    ok "fzf preview opts set"
  else
    bad "fzf preview opts not set"
  fi
else
  bad "fzf missing"
fi

# --- interactive zsh loads cleanly with all the new bits ---
zsh -ic 'exit 0' >/dev/null 2>&1 && ok "interactive zsh loads" || bad "interactive zsh failed to load"

# --- consolidated pre-change backup captured the pre-seeded ~/.zshrc ---
# (the extras job writes PRE-INSTALL-MARKER to ~/.zshrc before ./install.sh)
if grep -rqs "PRE-INSTALL-MARKER" "$HOME/backup/zsh/" 2>/dev/null; then
  ok "pre-change backup captured the old ~/.zshrc"
else
  bad "pre-change backup did not capture the old ~/.zshrc"
fi

# --- terminals: configs symlinked (hard); ghostty binary is a soft check (no Debian/Ubuntu package) ---
[ -L "$HOME/.config/ghostty/config" ] && ok "ghostty config symlinked" || bad "ghostty config not symlinked"
[ -L "$HOME/.config/alacritty/alacritty.toml" ] && ok "alacritty.toml symlinked" || bad "alacritty.toml not symlinked"
[ -L "$HOME/.config/kitty/kitty.conf" ] && ok "kitty.conf symlinked" || bad "kitty.conf not symlinked"
command -v ghostty >/dev/null && ok "ghostty installed" || note "ghostty binary not installed (no package on this distro?) — non-fatal"

# --- fabric: hard-verify IF present; warn (don't fail) if the fetch was missed ---
if command -v fabric >/dev/null; then
  if fabric --version </dev/null >/dev/null 2>&1; then
    ok "fabric installed + runs ($(fabric --version 2>/dev/null))"
  else
    bad "fabric present but will not run"
  fi
else
  note "fabric not installed (GitHub API rate-limit / network?) — non-fatal"
fi

if [ "$fail" -eq 0 ]; then
  echo "extras OK on $name"; exit 0
else
  echo "extras FAILED on $name"; exit 1
fi
