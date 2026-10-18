#!/usr/bin/env bash
# sesh-picker — one fuzzy list of tmux sessions + zoxide directories + sesh.toml
# sessions; pick one and jump to it (created on the fly if needed).
#
# install.sh symlinks this to ~/.local/bin/sesh-picker; tmux/tmux.conf binds it to
# `prefix + f`, and aliases.zsh exposes it as `proj` ( `proj <name>` connects directly).
# Degrades gracefully: without sesh it hands over to the bundled tmux-sessionizer.
#
#   ^a all   ^t tmux sessions   ^g configured   ^x zoxide dirs   ^d kill session
set -euo pipefail
# tmux run-shell inherits the server's PATH, which may predate this shell — make ~/.local/bin visible
export PATH="$HOME/.local/bin:$PATH"

if ! command -v sesh >/dev/null 2>&1; then
  fallback="$HOME/.local/bin/tmux-sessionizer"
  [ -x "$fallback" ] || fallback="$(dirname "$(readlink -f "$0")")/tmux-sessionizer.sh"
  if [ -t 0 ]; then exec "$fallback" "$@"; else exec tmux neww "$fallback"; fi
fi

# direct connect: proj <name>
[ "$#" -ge 1 ] && exec sesh connect "$*"

if ! command -v fzf >/dev/null 2>&1; then
  msg="sesh-picker: fzf is required (./install.sh installs it)"
  if [ -n "${TMUX:-}" ]; then tmux display-message "$msg"; else echo "$msg" >&2; fi
  exit 1
fi
# inside tmux without a TTY (run-shell from the keybinding) → a popup: fzf-tmux if present,
# else re-run ourselves inside display-popup, which hands us a TTY; from a shell → plain fzf.
if [ -n "${TMUX:-}" ] && [ ! -t 0 ]; then
  if command -v fzf-tmux >/dev/null 2>&1; then
    # shellcheck disable=SC2054  # the comma is fzf-tmux's own width,height syntax
    fzf=(fzf-tmux -p 80%,70%)
  else
    exec tmux display-popup -E -w 80% -h 70% "$0" "$@"
  fi
else
  fzf=(fzf --height=70% --reverse)
fi

selected="$(sesh list --icons | "${fzf[@]}" \
  --no-sort --ansi --border-label ' sesh ' --prompt 'sesh> ' \
  --header '  ^a all  ^t tmux  ^g configs  ^x zoxide  ^d kill' \
  --bind 'tab:down,btab:up' \
  --bind 'ctrl-a:change-prompt(sesh> )+reload(sesh list --icons)' \
  --bind 'ctrl-t:change-prompt(tmux> )+reload(sesh list -t --icons)' \
  --bind 'ctrl-g:change-prompt(config> )+reload(sesh list -c --icons)' \
  --bind 'ctrl-x:change-prompt(zoxide> )+reload(sesh list -z --icons)' \
  --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(sesh> )+reload(sesh list --icons)' \
  --preview-window 'right:50%' --preview 'sesh preview {}' || true)"

[ -n "$selected" ] && exec sesh connect "$selected"
exit 0
