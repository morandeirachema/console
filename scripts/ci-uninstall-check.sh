#!/usr/bin/env bash
# CI helper — assert ./uninstall.sh removed every symlink install.sh created.
# Run inside a container from the repo root, AFTER: install → ./uninstall.sh.
# Usage: scripts/ci-uninstall-check.sh <distro-name>
#
# Matches a non-minimal `--no-nvim` install (what the extras job runs), so the
# nvim symlink is intentionally absent and not checked here.
set -uo pipefail

name="${1:-?}"
fail=0
ok()  { printf '  \xe2\x9c\x93 %s\n' "$1"; }
bad() { printf '  \xe2\x9c\x97 %s\n' "$1"; fail=1; }
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"

for p in \
  "$HOME/.zshrc" \
  "$cfg/starship.toml" \
  "$cfg/tmux/tmux.conf" \
  "$HOME/.local/bin/tmux-sessionizer" \
  "$HOME/.local/bin/nas-sync" \
  "$cfg/ghostty/config" \
  "$cfg/alacritty/alacritty.toml" \
  "$cfg/kitty/kitty.conf" \
  "$cfg/lazygit/config.yml"; do
  # -L catches a leftover (even dangling) symlink; -e catches any leftover file.
  if [ -L "$p" ] || [ -e "$p" ]; then bad "still present after uninstall: $p"
  else ok "removed: ${p#"$HOME"/}"; fi
done

if [ "$fail" -eq 0 ]; then
  echo "uninstall clean on $name"; exit 0
else
  echo "uninstall INCOMPLETE on $name"; exit 1
fi
