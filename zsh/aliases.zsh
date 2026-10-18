# ============================================================
#  aliases.zsh  —  sourced by .zshrc
#  Everything degrades gracefully if the tool isn't installed.
# ============================================================

# --- ls -> eza (https://github.com/eza-community/eza) ---
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias la='eza -a  --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ll='ls -lah'
  alias la='ls -A'
  alias lt='ls -R'
fi

# --- cat -> bat (called 'batcat' on Debian/Ubuntu) ---
if command -v bat >/dev/null; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null; then
  alias bat='batcat'
  alias cat='batcat --paging=never'
fi

# --- fd (find) — binary is 'fdfind' on Debian/Ubuntu; also drives fzf ---
if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
  alias fd='fdfind'; _FD_BIN='fdfind'
elif command -v fd >/dev/null; then
  _FD_BIN='fd'
fi
if [[ -n "${_FD_BIN:-}" ]]; then
  # let fzf's Ctrl-T / Alt-C use fd (respects .gitignore, includes dotfiles)
  export FZF_DEFAULT_COMMAND="$_FD_BIN --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="$_FD_BIN --type d --hidden --follow --exclude .git"
fi
unset _FD_BIN

# --- fzf previews: bat for files, eza-tree for dirs (all guarded) ---
# Ctrl-T previews the file, Alt-C previews the directory, Ctrl-R shows the full
# command (fzf's Ctrl-R is the fallback when atuin isn't installed). Toggle any
# preview with Ctrl-/.  Read lazily by fzf at invoke time.
if command -v fzf >/dev/null; then
  # Use $commands (real executables only) — not `command -v`, which would match the
  # `bat` alias we set above and break the preview under fzf's plain `sh -c`.
  if   (( ${+commands[bat]} ));    then _fzcat='bat --color=always --style=numbers --line-range=:200 {}'
  elif (( ${+commands[batcat]} )); then _fzcat='batcat --color=always --style=numbers --line-range=:200 {}'
  else _fzcat='cat {}'; fi
  # no --icons in the preview tree → works on any eza version (icons need >=0.18)
  if (( ${+commands[eza]} )); then _fztree='eza --tree --level=2 --color=always {}'
  else _fztree='ls -1 {}'; fi
  # NB: colon preview-window syntax (right:60%) — the comma form + `border-left`
  # need fzf >= 0.28 and error out on older builds (e.g. RHEL/EPEL). Colon works
  # on fzf 0.17 → current, so previews never break the picker on an old box.
  export FZF_CTRL_T_OPTS="--preview '[ -d {} ] && $_fztree || $_fzcat' --preview-window=right:60% --bind ctrl-/:toggle-preview"
  export FZF_ALT_C_OPTS="--preview '$_fztree' --preview-window=right:50% --bind ctrl-/:toggle-preview"
  export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap --bind ctrl-/:toggle-preview"
  unset _fzcat _fztree
fi

# --- atuin — history database (Ctrl-R is bound in .zshrc) ---
if command -v atuin >/dev/null; then
  alias h='atuin search -i'            # the same picker, from the command line
  alias hstats='atuin stats'           # most-used commands
fi

# --- rg (ripgrep) — fast recursive grep ---
command -v rg >/dev/null && alias rgi='rg -i'

# --- lazygit — terminal UI for git ---
command -v lazygit >/dev/null && alias lg='lazygit'

# --- pass — GPG-encrypted password store (https://www.passwordstore.org) ---
if command -v pass >/dev/null; then
  alias pw='pass'
  alias pwc='pass -c'                      # copy a secret to the clipboard
  # passf: fuzzy-pick an entry and copy it to the clipboard (needs fzf)
  if command -v fzf >/dev/null; then
    passf() {
      local store="${PASSWORD_STORE_DIR:-$HOME/.password-store}" entry
      entry="$(command find "$store" -name '*.gpg' 2>/dev/null \
        | sed -e "s|$store/||" -e 's|\.gpg$||' | fzf --prompt='pass> ')" || return
      [[ -n "$entry" ]] && pass -c "$entry"
    }
  fi
fi

# --- fabric — run AI "patterns" as Unix filters (https://github.com/danielmiessler/fabric) ---
if command -v fabric >/dev/null; then
  alias fab='fabric'
  alias fsum='fabric --pattern summarize'          # e.g.  cat notes.md | fsum
  alias fexplain='fabric --pattern explain_code'   # e.g.  git diff | fexplain
  ytsum() { fabric -y "$1" --pattern summarize; }  # summarize a YouTube URL
  # First run: `fabric --setup`. Keep provider API keys in ~/.zshrc.local, not the repo.
fi

# --- superfile (spf) — TUI file manager; the wrapper makes `cd_on_quit` work ---
# https://superfile.dev  ·  `?` inside for keys  ·  `fm` is the same thing
if command -v spf >/dev/null; then
  spf() {
    emulate -L zsh
    local last
    case "$(uname -s)" in
      Darwin) last="$HOME/Library/Application Support/superfile/lastdir" ;;
      *)      last="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir" ;;
    esac
    SPF_LAST_DIR="$last" command spf "$@"
    [[ -f "$last" ]] && { builtin source "$last"; command rm -f -- "$last"; }
  }
  alias fm='spf'
fi

# --- neovim as the default editor ---
if command -v nvim >/dev/null; then
  alias vi='nvim'
  alias vim='nvim'
  alias v='nvim'
  export EDITOR='nvim'
  export VISUAL='nvim'
fi

# --- devops / sysadmin shortcuts (defined only if the tool is installed) ---
if command -v kubectl >/dev/null; then
  alias k='kubectl'
  alias kg='kubectl get'
  alias kd='kubectl describe'
  alias klo='kubectl logs -f'
  alias kx='kubectl config use-context'                        # switch cluster
  alias kns='kubectl config set-context --current --namespace' # switch namespace
fi
if command -v docker >/dev/null; then
  alias d='docker'
  alias dps='docker ps'
  alias dc='docker compose'
fi
command -v terraform  >/dev/null && alias tf='terraform'
command -v ansible    >/dev/null && alias ap='ansible-playbook'
command -v tmux       >/dev/null && { alias t='tmux'; alias ta='tmux attach'; alias tls='tmux ls'; }
# proj — the prefix+f project picker from the shell; `proj <name>` connects straight to it.
# sesh-picker degrades to tmux-sessionizer when sesh isn't installed.
if command -v sesh-picker >/dev/null; then
  proj() { sesh-picker "$@"; }
  command -v sesh >/dev/null && alias sl='sesh list --icons'
fi
if command -v systemctl >/dev/null; then
  alias sc='systemctl'
  alias scu='systemctl --user'
  alias jc='journalctl'
  alias jcu='journalctl --user'
fi

# --- WSL: bridge to the Windows side (defined only inside WSL; one tiny /proc read) ---
if [[ -r /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  command -v explorer.exe >/dev/null && open() { explorer.exe "$(wslpath -w "${1:-.}")"; }   # open in Explorer
  command -v clip.exe     >/dev/null && alias pbcopy='clip.exe'                                 # pipe → Windows clipboard
  command -v powershell.exe >/dev/null && alias pbpaste='powershell.exe -NoProfile -Command Get-Clipboard | tr -d "\r"'
  winhome() { cd "$(wslpath -u "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"; }   # cd to C:\Users\<you>
fi

# --- grep colors ---
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'

# --- navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias path='echo $PATH | tr ":" "\n"'

# --- git ---
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'

# --- handy ---
alias reload='exec zsh'                 # reload shell after config changes
alias zshrc='${EDITOR:-nano} ${ZDOTDIR:-$HOME}/.zshrc'   # follows --xdg
alias please='sudo $(fc -ln -1)'        # re-run last command with sudo
alias myip='curl -s https://ifconfig.me; echo'   # https://ifconfig.me
# listening ports — ss on Linux, lsof on macOS
if command -v ss >/dev/null; then
  alias ports='ss -tulpn'
else
  alias ports='lsof -nP -iTCP -sTCP:LISTEN'
fi

# --- ssh port-forwarding helpers (tunnels) ---------------------------------
# https://www.ssh.com/academy/ssh/tunneling
# All run in the foreground with a keep-alive; press Ctrl-C to close the tunnel
# (open it in a tmux pane if you want to keep using this shell). Put host
# entries in ~/.ssh/config so <host> can be a short alias — see the README.
if command -v ssh >/dev/null; then
  # fwd — LOCAL forward: reach a remote service at your OWN localhost.
  #   fwd <host> <port>                     localhost:<port>  -> host:localhost:<port>
  #   fwd <host> <lport> <rport>            localhost:<lport> -> host:localhost:<rport>
  #   fwd <host> <lport> <rhost> <rport>    localhost:<lport> -> <rhost>:<rport> (via host)
  fwd() {
    emulate -L zsh
    local host="$1" lport="$2" rhost="localhost" rport
    [[ -z "$host" || -z "$lport" ]] && { print -u2 "usage: fwd <host> <lport> [rport] | <lport> <rhost> <rport>"; return 2; }
    if [[ -n "$4" ]]; then rhost="$3"; rport="$4"
    elif [[ -n "$3" ]]; then rport="$3"
    else rport="$lport"; fi
    print -P "%F{cyan}→%f localhost:$lport  ⇒  $rhost:$rport  (via $host) — Ctrl-C to stop"
    ssh -N -o ServerAliveInterval=60 -L "${lport}:${rhost}:${rport}" "$host"
  }
  # rfwd — REMOTE forward: expose YOUR local service on the remote host.
  #   rfwd <host> <rport> [lport]           host:<rport> -> your localhost:<lport|rport>
  rfwd() {
    emulate -L zsh
    local host="$1" rport="$2" lport="${3:-$2}"
    [[ -z "$host" || -z "$rport" ]] && { print -u2 "usage: rfwd <host> <rport> [lport]"; return 2; }
    print -P "%F{cyan}→%f $host:$rport  ⇒  your localhost:$lport — Ctrl-C to stop"
    ssh -N -o ServerAliveInterval=60 -R "${rport}:localhost:${lport}" "$host"
  }
  # socks — DYNAMIC forward: a SOCKS5 proxy through <host> (point apps at localhost:<port>).
  #   socks <host> [port=1080]
  socks() {
    emulate -L zsh
    local host="$1" port="${2:-1080}"
    [[ -z "$host" ]] && { print -u2 "usage: socks <host> [socks-port=1080]"; return 2; }
    print -P "%F{cyan}→%f SOCKS5 proxy on localhost:$port  (via $host) — Ctrl-C to stop"
    ssh -N -o ServerAliveInterval=60 -D "${port}" "$host"
  }
fi
