#!/usr/bin/env bash
# CI helper — the install/uninstall lifecycle promises: a second run is idempotent (no duplicate
# git include, no second backup), tmux.conf loads with prefix+f wired, sesh-picker runs,
# uninstall is idempotent and removes the include, and the README restore recipe works.
# Run from the repo root AFTER ./install.sh and scripts/ci-extras-check.sh; it uninstalls at the end.
# Usage: scripts/ci-lifecycle-check.sh <distro-name> [install flags…]
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
name="${1:-?}"; shift || true
flags=("$@"); [ ${#flags[@]} -eq 0 ] && flags=(--no-nvim --no-font --no-chsh -y)
fail=0
ok()  { printf '  \xe2\x9c\x93 %s\n' "$1"; }
bad() { printf '  \xe2\x9c\x97 %s\n' "$1"; fail=1; }

# --- second run: idempotent ---
./install.sh "${flags[@]}" >/dev/null 2>&1 || bad "second install run failed"
n="$(git config --global --get-all include.path 2>/dev/null | grep -c delta.gitconfig)"
[ "$n" -eq 1 ] && ok "git-delta include present exactly once after two runs" || bad "git-delta include count is $n"
# every run snapshots ~/.gitconfig and ~/.zshenv (the files it edits), so a second backup dir is
# expected — but it must not contain a config the first run already turned into a symlink
newest="$(ls -1dt "$HOME"/backup/zsh/*/ 2>/dev/null | head -1)"
if [ -e "$newest/.zshrc" ] || [ -L "$newest/.zshrc" ]; then bad "second run re-backed-up ~/.zshrc (it should be our symlink by then)"
else ok "second run backed up nothing it had already linked"; fi
# --doctor is clean right after an install with the same flags
if ./install.sh --doctor "${flags[@]}" >/dev/null 2>&1; then ok "--doctor exits 0 after install"
else bad "--doctor reports problems after install:"; ./install.sh --doctor "${flags[@]}" 2>/dev/null | grep -E "^\s+(!|✗)" | sed 's/^/      /'; fi

# --- tmux config loads and prefix+f is wired to the picker ---
if command -v tmux >/dev/null; then
  tmux -L ci -f "$HOME/.config/tmux/tmux.conf" new-session -d -s ci 'sleep 2' 2>/dev/null
  if tmux -L ci list-keys 2>/dev/null | grep -q sesh-picker; then ok "tmux.conf loads; prefix+f → sesh-picker"
  else bad "tmux.conf: prefix+f not bound to sesh-picker"; fi
  tmux -L ci kill-server 2>/dev/null
else bad "tmux missing"; fi
# sesh-picker without a TTY must exit cleanly (0 = no selection, 1 = fzf-absent guard)
"$HOME/.local/bin/sesh-picker" </dev/null >/dev/null 2>&1; ec=$?
[ "$ec" -le 1 ] && ok "sesh-picker runs cleanly without a TTY (exit $ec)" || bad "sesh-picker crashed (exit $ec)"

# --- uninstall twice: idempotent, include removed ---
./uninstall.sh >/dev/null 2>&1 || bad "uninstall failed"
./uninstall.sh >/dev/null 2>&1 && ok "uninstall is idempotent (second run exits 0)" || bad "second uninstall failed"
git config --global --get-all include.path 2>/dev/null | grep -q delta.gitconfig && bad "git-delta include still present" || ok "git-delta include removed"
bash scripts/ci-uninstall-check.sh "$name" >/dev/null || bad "ci-uninstall-check failed after uninstall"

# --- README restore recipe: the newest backup that holds a .zshrc, copied back over the now-empty paths ---
latest=""
dirs=("$HOME"/backup/zsh/*/)          # names are timestamps, so lexical order is chronological
for (( i=${#dirs[@]}-1; i>=0; i-- )); do [ -e "${dirs[$i]}/.zshrc" ] && { latest="${dirs[$i]}"; break; }; done
if [ -n "$latest" ] && cp -a "$latest/." "$HOME"/ && grep -q PRE-INSTALL-MARKER "$HOME/.zshrc" 2>/dev/null; then
  ok "restore recipe brings the pre-install ~/.zshrc back"
else bad "restore recipe failed (backup: ${latest:-none})"; fi

if [ "$fail" -eq 0 ]; then echo "lifecycle OK on $name"; exit 0; else echo "lifecycle FAILED on $name"; exit 1; fi
