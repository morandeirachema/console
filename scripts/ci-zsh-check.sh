#!/usr/bin/env bash
# CI helper — prove the interactive shell really works, not just that `zsh -ic exit` returns 0
# (which exits before the first prompt, so zinit's turbo waves never run and nothing is asserted).
# Checks: zinit cloned, the turbo plugins loaded (their widgets exist), the documented bindings
# (Ctrl-T → fzf, Tab → fzf-tab, Ctrl-R → atuin or fzf), starship renders.
# Usage: scripts/ci-zsh-check.sh [--offline]
#   --offline: zinit cannot clone, so only the `compinit -i` fallback path is asserted.
set -uo pipefail
mode="${1:-}"
zsh -ic '
  zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ "$1" == --offline ]]; then
    [[ -e "${zinit_home:h}/.clone-failed" ]] || { echo "::error::offline: expected the .clone-failed marker"; exit 1; }
    (( ${+functions[_main_complete]} ))     || { echo "::error::offline: compinit did not run"; exit 1; }
    echo "zsh OK (offline: plain compinit path, no plugins)"; exit 0
  fi
  [[ -r "$zinit_home/zinit.zsh" ]] || { echo "::error::zinit not cloned"; exit 1; }
  # run the turbo waves now instead of after the first prompt. On a fresh box zinit clones the
  # plugins in background processes and loads each one on a LATER scheduler tick, and CI runners
  # are slow, so keep ticking for up to ~2 minutes and stop as soon as the widgets exist.
  sched_log="$(mktemp)"
  for i in {1..60}; do
    @zinit-scheduler burst >>"$sched_log" 2>&1 || true
    (( ${+widgets[fzf-tab-complete]} && ${+widgets[history-substring-search-up]} && ${+widgets[autosuggest-accept]} )) && { echo "turbo plugins loaded after ~$(( i * 2 ))s"; break; }
    sleep 2
  done
  for w in fzf-tab-complete history-substring-search-up autosuggest-accept; do
    if (( ! ${+widgets[$w]} )); then
      echo "::error::widget $w missing — its plugin did not load"
      echo "--- diagnostics ---"; zinit list 2>&1 | head -20; ls -1 "${zinit_home:h}/plugins" 2>&1
      echo "widgets: ${(k)widgets[(I)*fzf*|*autosuggest*|*substring*]}"
      echo "--- scheduler output ---"; sed "s/\x1b\[[0-9;?]*[A-Za-z]//g" "$sched_log" | grep -v "^\s*$" | tail -40; exit 1
    fi
  done
  for t in starship zoxide fzf; do command -v "$t" >/dev/null || { echo "::error::$t missing"; exit 1; }; done
  bindkey | grep -q "\"^T\" fzf-file-widget"  || { echo "::error::Ctrl-T is not fzf-file-widget"; exit 1; }
  bindkey | grep -q "\"^I\" fzf-tab-complete" || { echo "::error::Tab is not fzf-tab-complete"; exit 1; }
  if command -v atuin >/dev/null; then
    bindkey | grep -q "\"^R\" atuin-search" || { echo "::error::Ctrl-R is not atuin-search"; exit 1; }
  else
    bindkey | grep -q "\"^R\" fzf-history-widget" || { echo "::error::Ctrl-R is not fzf (no atuin)"; exit 1; }
  fi
  starship prompt >/dev/null || { echo "::error::starship cannot render the prompt"; exit 1; }
  echo "zsh OK: zinit + turbo plugins + bindings + starship"
' zsh-check "$mode"
