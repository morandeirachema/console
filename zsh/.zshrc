# ============================================================
#  ~/.zshrc  —  chema's zsh console
#  Managed as dotfiles; symlinked here from the repo.
#  Stack: zinit (plugins) + starship (prompt) + fzf + zoxide
# ============================================================

# --- Resolve the repo dir this file really lives in (follows the symlink) ---
ZDOTREPO="${${(%):-%x}:A:h}"

# --- PATH ---
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# --- Editor ---
export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"

# --- gpg / ssh agents ---
export GPG_TTY=$TTY    # let gpg prompt in this terminal (e.g. git commit signing)
# ssh-agent is left to your platform (keyring / systemd / 1Password / Vault).
# To auto-start a plain agent when none exists, see zsh/zshrc.local.example.

# ------------------------------------------------------------
#  History
# ------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # share history across sessions
setopt INC_APPEND_HISTORY     # write immediately, not on exit
setopt EXTENDED_HISTORY       # record timestamps
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicate entries
setopt HIST_IGNORE_SPACE      # ignore commands starting with a space
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # let me edit a !history expansion before running

# ------------------------------------------------------------
#  Sensible shell options
# ------------------------------------------------------------
setopt AUTO_CD                # `foo/` == `cd foo/`
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS   # allow # comments in interactive shell
setopt GLOB_DOTS              # include dotfiles in globs
setopt NO_BEEP
setopt COMPLETE_IN_WORD ALWAYS_TO_END

bindkey -e                    # emacs keybindings

# ------------------------------------------------------------
#  zinit — plugin manager (auto-installs on first run)
#  https://github.com/zdharma-continuum/zinit
# ------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
# For reproducible / air-gapped installs, pin zinit to a commit or tag by
# exporting ZINIT_PIN before the shell starts (e.g. in ~/.zshenv). Empty = latest.
: "${ZINIT_PIN:=}"
# A failed clone (offline / air-gapped box) drops this marker so later shells
# don't retry the network on every startup. `rm` it to try again.
ZINIT_FAILED="${ZINIT_HOME:h}/.clone-failed"
if [[ ! -d "$ZINIT_HOME" && ! -e "$ZINIT_FAILED" ]]; then
  print -P "%F{cyan}▓▒░ Installing zinit (one time)…%f"
  command mkdir -p "${ZINIT_HOME:h}"
  if command git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"; then
    print -P "%F{green}▓▒░ zinit installed.%f"
    [[ -n "$ZINIT_PIN" ]] && command git -C "$ZINIT_HOME" checkout -q "$ZINIT_PIN" 2>/dev/null
  else
    print -P "%F{red}▓▒░ zinit clone failed — plugins off. Retry: rm $ZINIT_FAILED%f"
    command rm -rf "$ZINIT_HOME"; : >| "$ZINIT_FAILED"
  fi
fi

if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"

  # ------------------------------------------------------------
  #  Plugins — zinit TURBO mode (loaded async, right after the
  #  prompt appears → instant startup).
  #  https://github.com/zdharma-continuum/zinit#turbo-mode-zsh--53
  # ------------------------------------------------------------
  # First wave: highlighting + completions + autosuggestions.
  # compinit runs ONCE here via zicompinit (inside atinit), then the
  # completion cache is replayed with zicdreplay — do not also call
  # compinit synchronously elsewhere.
  # COMPINIT_OPTS=-i keeps compinit's security check but silently skips
  # insecure (world/group-writable) fpath dirs instead of loading them or
  # prompting. Do NOT use -C here: it bypasses the check entirely, which on a
  # shared/hardened host is a completion-injection (privesc) risk.
  zinit wait lucid light-mode for \
    atinit"ZINIT[COMPINIT_OPTS]=-i; zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    blockf \
        zsh-users/zsh-completions \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions

  # Second wave: fzf-tab (must load after compinit), you-should-use
  # (nudges you when a typed command has an alias you defined), and
  # history-substring-search. Its keys are bound in atload because in
  # turbo mode the widget does not exist until the plugin is sourced.
  YSU_MESSAGE_POSITION="after"
  zinit wait lucid light-mode for \
    Aloxaf/fzf-tab \
    MichaelAquilina/zsh-you-should-use \
    atload'bindkey "^[[A" history-substring-search-up; bindkey "^[[B" history-substring-search-down; bindkey "^P" history-substring-search-up; bindkey "^N" history-substring-search-down' \
        zsh-users/zsh-history-substring-search
else
  # No zinit (clone failed / offline): still give the shell working completion.
  # Same -i security posture as the turbo path above — never -C.
  autoload -Uz compinit && compinit -i
fi

# ------------------------------------------------------------
#  Completion styling (zstyles are read lazily at completion time)
# ------------------------------------------------------------

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
# fzf-tab previews (eza tree if present, else plain ls — both degrade gracefully)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=auto "$realpath" 2>/dev/null || ls -1 --color=always "$realpath"'

# ------------------------------------------------------------
#  fzf — fuzzy finder (Ctrl-R history, Ctrl-T files, Alt-C cd)
#  https://github.com/junegunn/fzf
# ------------------------------------------------------------
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)                       # fzf >= 0.48
  else
    # older fzf: source the distro's copies. Debian/Ubuntu → doc/examples,
    # Arch → /usr/share/fzf, Fedora/RHEL (EPEL) → /usr/share/fzf/shell (Fedora
    # ships completion as _fzf in site-functions, so compinit picks it up).
    for _f in {/usr/share/doc/fzf/examples,/usr/share/fzf,/usr/share/fzf/shell}/{key-bindings,completion}.zsh; do
      [[ -f $_f ]] && source "$_f"
    done
    unset _f
  fi
fi

# history-substring-search keys (Up/Down + Ctrl-P/N) are bound in the
# plugin's atload hook above — in turbo mode the widget only exists
# once the plugin has finished loading asynchronously.

# ------------------------------------------------------------
#  zoxide — smarter cd (`z foo`, `zi` interactive)
#  https://github.com/ajeetdsouza/zoxide
# ------------------------------------------------------------
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ------------------------------------------------------------
#  starship — the prompt.  https://starship.rs
# ------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

# ------------------------------------------------------------
#  direnv — per-directory env from .envrc (allowlisted with `direnv allow`)
#  https://direnv.net
# ------------------------------------------------------------
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ------------------------------------------------------------
#  carapace — unified completions (kubectl/aws/docker/terraform/gh…). Optional.
#  https://carapace.sh
# ------------------------------------------------------------
if command -v carapace >/dev/null; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  source <(carapace _carapace zsh) 2>/dev/null
fi

# ------------------------------------------------------------
#  Aliases + per-machine overrides
# ------------------------------------------------------------
[[ -f "$ZDOTREPO/aliases.zsh" ]] && source "$ZDOTREPO/aliases.zsh"
# Machine-specific, NOT committed to the repo (secrets, local paths).
# Only sourced if owned by the current user (guards against another account
# planting a ~/.zshrc.local that would run in your shell).
[[ -f "$HOME/.zshrc.local" && -O "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Leave a fresh shell at $?=0 so the first prompt isn't a false error.
true
