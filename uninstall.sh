#!/usr/bin/env bash
# uninstall.sh — reverse what install.sh did: remove the symlinks it created and
# the git-delta include. Your ~/.zshrc.pre-console.<ts> backups are left in place.
# Does NOT uninstall packages (they may be used by other things).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
c()    { printf '\033[%sm' "$1"; }
info() { printf '%s▶%s %s\n' "$(c '1;36')" "$(c 0)" "$*"; }
ok()   { printf '%s✓%s %s\n' "$(c '1;32')" "$(c 0)" "$*"; }
warn() { printf '%s!%s %s\n' "$(c '1;33')" "$(c 0)" "$*"; }

# Remove a symlink only if it points inside THIS repo (never touch real files).
unlink_if_ours() {
  local dst="$1" tgt
  if [ -L "$dst" ]; then
    tgt="$(readlink -f "$dst" 2>/dev/null || true)"
    case "$tgt" in
      "$REPO_DIR"/*) rm -f "$dst"; ok "removed symlink $dst" ;;
      *) warn "left $dst (points outside this repo)" ;;
    esac
  elif [ -e "$dst" ]; then
    warn "left $dst (a real file, not our symlink)"
  fi
}

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
info "Removing console symlinks…"
unlink_if_ours "$HOME/.zshrc"
unlink_if_ours "$CONFIG/zsh/.zshrc"            # --xdg layout
unlink_if_ours "$CONFIG/starship.toml"
unlink_if_ours "$CONFIG/lazygit/config.yml"
unlink_if_ours "$CONFIG/tmux/tmux.conf"
unlink_if_ours "$HOME/.local/bin/tmux-sessionizer"
unlink_if_ours "$HOME/.local/bin/nas-sync"
unlink_if_ours "$CONFIG/ghostty/config"
unlink_if_ours "$CONFIG/atuin/config.toml"
unlink_if_ours "$CONFIG/sesh/sesh.toml"
unlink_if_ours "$CONFIG/superfile/config.toml"
unlink_if_ours "$HOME/Library/Application Support/superfile/config.toml"
unlink_if_ours "$HOME/.local/bin/sesh-picker"
unlink_if_ours "$CONFIG/alacritty/alacritty.toml"
unlink_if_ours "$CONFIG/kitty/kitty.conf"
unlink_if_ours "$CONFIG/nvim"

# Remove the git-delta include (leave the rest of ~/.gitconfig untouched).
frag="$REPO_DIR/git/delta.gitconfig"
if git config --global --get-all include.path 2>/dev/null | grep -qxF "$frag"; then
  git config --global --unset-all include.path "$frag" 2>/dev/null \
    && ok "removed git-delta include" \
    || warn "could not auto-remove the include — edit ~/.gitconfig by hand"
fi

echo
ok "Uninstalled. Packages and plugins were left in place."
info "Restore your previous config from the newest console backup, if any:"
BACKUPS="$HOME/backup/zsh"
if [ -d "$BACKUPS" ]; then
  # shellcheck disable=SC2012  # newest backup dir; ls -t is fine for a hint
  latest="$(ls -1dt "$BACKUPS"/*/ 2>/dev/null | head -1)"
  if [ -n "$latest" ]; then
    info "  newest: $latest"
    info "  e.g.:   cp -a \"${latest}.zshrc\" ~/.zshrc   # plus anything else under it"
  else info "  (none found under $BACKUPS)"; fi
else info "  (none found under $BACKUPS)"; fi
# Legacy in-place backups from older installs, if present.
# shellcheck disable=SC2012
ls -d "$HOME"/.zshrc.pre-console.* >/dev/null 2>&1 && \
  info "  legacy: $HOME/.zshrc.pre-console.*  (mv one back to ~/.zshrc)"
info "Then reload:  exec zsh   (or restart your terminal)"
exit 0
