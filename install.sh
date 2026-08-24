#!/usr/bin/env bash
# ============================================================
#  install.sh — bootstrap chema's zsh console on any Linux or macOS box
#  Usage: ./install.sh [--dry-run] [--doctor] [--minimal] [--server] [--offline] [--no-nvim] [--no-fabric] [--no-alacritty] [--no-font] [--no-chsh] [-y]
#    --dry-run      show every package/symlink/change this run WOULD make — touch nothing
#    --doctor       health check: report installed tools, symlinks, font, git config — then exit
#    --minimal      only zsh + plugins + prompt (skip eza/bat/fd/rg/delta/tldr/lazygit/nvim/font)
#    --server       headless box: skip the Nerd Font + Alacritty (both live on your client)
#    --offline      air-gapped: no internet fetches — packages must come from your mirror,
#                   and skip the curl-installer fallbacks, release binaries, and font download
#    --xdg          XDG layout: put .zshrc under ZDOTDIR=~/.config/zsh (keeps $HOME tidy)
#    --no-nvim      don't install Neovim/LazyVim or touch ~/.config/nvim
#    --no-fabric    don't install fabric (the AI-patterns CLI)
#    --no-alacritty don't install the Alacritty terminal or link its config
#    --no-kitty     don't link the kitty terminal config
#    --no-font      don't download the Nerd Font
#    --no-chsh      don't change the default login shell
#    -y|--yes       non-interactive
# ============================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOGDIR="${XDG_STATE_HOME:-$HOME/.local/state}/console"
LOGFILE="$LOGDIR/install-$STAMP.log"   # audit trail of everything this run changed
BACKUP_DIR="$HOME/backup/zsh/$STAMP"   # consolidated snapshot of configs this run replaces (visible path)
NO_FONT=0; NO_CHSH=0; MINIMAL=0; NO_NVIM=0; NO_FABRIC=0; NO_ALACRITTY=0; NO_KITTY=0; OFFLINE=0; XDG=0; DRY=0; DOCTOR=0

for a in "$@"; do
  case "$a" in
    --dry-run)      DRY=1;;
    --doctor)       DOCTOR=1;;
    --no-font)      NO_FONT=1;;
    --server)       NO_FONT=1; NO_ALACRITTY=1; NO_KITTY=1;;
    --offline)      OFFLINE=1; NO_FONT=1;;
    --xdg)          XDG=1;;
    --no-chsh)      NO_CHSH=1;;
    --no-nvim)      NO_NVIM=1;;
    --no-fabric)    NO_FABRIC=1;;
    --no-alacritty) NO_ALACRITTY=1;;
    --no-kitty)     NO_KITTY=1;;
    --minimal)      MINIMAL=1; NO_FONT=1;;
    -y|--yes)       : ;;
    -h|--help)      grep '^#' "$0" | sed '1d;s/^# \{0,1\}//'; exit 0;;   # 1d drops the shebang
    *) echo "unknown option: $a"; exit 1;;
  esac
done
# Create the audit-log dir only for a real run (dry-run / doctor change nothing).
[ "$DRY" -eq 1 ] || [ "$DOCTOR" -eq 1 ] || mkdir -p "$LOGDIR" 2>/dev/null || true

c()    { printf '\033[%sm' "$1"; }
log()  { [ "$DRY" -eq 1 ] && return 0; printf '%s %s\n' "$STAMP" "$*" >> "$LOGFILE" 2>/dev/null || true; }
info() { printf '%s▶%s %s\n' "$(c '1;36')" "$(c 0)" "$*"; log ">  $*"; }
ok()   { printf '%s✓%s %s\n' "$(c '1;32')" "$(c 0)" "$*"; log "OK $*"; }
warn() { printf '%s!%s %s\n' "$(c '1;33')" "$(c 0)" "$*"; log "!! $*"; }
have() { command -v "$1" >/dev/null 2>&1; }
dry()  { [ "$DRY" -eq 1 ]; }                     # true in --dry-run
# run a mutating command, or (in dry-run) just print what it would do
run()  { if dry; then info "[dry-run] $*"; else "$@"; fi; }
sha256_of() { if have sha256sum; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }
# GitHub API calls, authenticated when a token is present (GITHUB_TOKEN/GH_TOKEN)
# → lifts the 60-req/hour unauthenticated rate limit that bites on shared IPs / CI.
# Only the api.github.com version lookups use this; release downloads don't (the
# token must not follow the cross-host redirect to the CDN).
gh_curl() {
  local tok="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [ -n "$tok" ]; then curl -sSL -H "Authorization: Bearer $tok" "$@"
  else curl -sSL "$@"; fi
}

# --- release-binary fallbacks (used when a tool isn't in the repos) ---
install_lazygit_release() {   # https://github.com/jesseduffield/lazygit
  local arch tmp ver want got
  dry && { info "[dry-run] download + install lazygit (GitHub release)"; return 0; }
  case "$(uname -m)" in
    x86_64)  arch="Linux_x86_64" ;;
    aarch64) arch="Linux_arm64" ;;
    *) return 1 ;;
  esac
  tmp="$(mktemp -d)"
  ver="$(gh_curl https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
         | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || { rm -rf "$tmp"; return 1; }
  curl -sSfL -o "$tmp/lg.tgz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_${arch}.tar.gz" \
    || { rm -rf "$tmp"; return 1; }
  # verify SHA256 against the release's published checksums.txt before trusting it
  if curl -sSfL -o "$tmp/sums" \
       "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/checksums.txt"; then
    want="$(grep -E "  lazygit_${ver}_${arch}\.tar\.gz$" "$tmp/sums" | awk '{print $1}' | head -1)"
    got="$(sha256_of "$tmp/lg.tgz")"
    if [ -n "$want" ] && [ "$want" != "$got" ]; then
      warn "lazygit checksum mismatch — refusing to install"; rm -rf "$tmp"; return 1
    fi
  else
    warn "could not fetch lazygit checksums — installing unverified"
  fi
  tar xzf "$tmp/lg.tgz" -C "$tmp" lazygit || { rm -rf "$tmp"; return 1; }
  mkdir -p "$HOME/.local/bin"; install "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
}

install_carapace_release() {  # https://github.com/carapace-sh/carapace-bin
  local arch tmp ver want got
  dry && { info "[dry-run] download + install carapace (GitHub release)"; return 0; }
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) return 1 ;;
  esac
  tmp="$(mktemp -d)"
  ver="$(gh_curl https://api.github.com/repos/carapace-sh/carapace-bin/releases/latest \
         | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || { rm -rf "$tmp"; return 1; }
  curl -sSfL -o "$tmp/cb.tgz" \
    "https://github.com/carapace-sh/carapace-bin/releases/download/v${ver}/carapace-bin_${ver}_linux_${arch}.tar.gz" \
    || { rm -rf "$tmp"; return 1; }
  if curl -sSfL -o "$tmp/sums" \
       "https://github.com/carapace-sh/carapace-bin/releases/download/v${ver}/carapace-bin_${ver}_checksums.txt"; then
    want="$(grep -F "carapace-bin_${ver}_linux_${arch}.tar.gz" "$tmp/sums" | awk '{print $1}' | head -1)"
    got="$(sha256_of "$tmp/cb.tgz")"
    if [ -n "$want" ] && [ "$want" != "$got" ]; then
      warn "carapace checksum mismatch — refusing to install"; rm -rf "$tmp"; return 1
    fi
  else
    warn "could not fetch carapace checksums — installing unverified"
  fi
  tar xzf "$tmp/cb.tgz" -C "$tmp" carapace || { rm -rf "$tmp"; return 1; }
  mkdir -p "$HOME/.local/bin"; install "$tmp/carapace" "$HOME/.local/bin/carapace"
  rm -rf "$tmp"
}

install_fabric_release() {    # https://github.com/danielmiessler/fabric
  local os arch asset tmp ver want got
  case "$(uname -s)" in
    Linux)  os="Linux" ;;
    Darwin) os="Darwin" ;;
    *) return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) return 1 ;;
  esac
  dry && { info "[dry-run] download + install fabric (GitHub release)"; return 0; }
  asset="fabric_${os}_${arch}.tar.gz"
  tmp="$(mktemp -d)"
  ver="$(gh_curl https://api.github.com/repos/danielmiessler/fabric/releases/latest \
         | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || { rm -rf "$tmp"; return 1; }
  curl -sSfL -o "$tmp/fabric.tgz" \
    "https://github.com/danielmiessler/fabric/releases/download/v${ver}/${asset}" \
    || { rm -rf "$tmp"; return 1; }
  # verify SHA256 against the release's published checksums before trusting it
  if curl -sSfL -o "$tmp/sums" \
       "https://github.com/danielmiessler/fabric/releases/download/v${ver}/fabric_${ver}_checksums.txt"; then
    want="$(grep -F "$asset" "$tmp/sums" | awk '{print $1}' | head -1)"
    got="$(sha256_of "$tmp/fabric.tgz")"
    if [ -n "$want" ] && [ "$want" != "$got" ]; then
      warn "fabric checksum mismatch — refusing to install"; rm -rf "$tmp"; return 1
    fi
  else
    warn "could not fetch fabric checksums — installing unverified"
  fi
  tar xzf "$tmp/fabric.tgz" -C "$tmp" fabric || { rm -rf "$tmp"; return 1; }
  mkdir -p "$HOME/.local/bin"; install "$tmp/fabric" "$HOME/.local/bin/fabric"
  rm -rf "$tmp"
}

install_neovim_release() {    # https://github.com/neovim/neovim/releases
  local asset tmp want got
  dry && { info "[dry-run] download + install Neovim (GitHub release)"; return 0; }
  case "$(uname -m)" in
    x86_64)  asset="nvim-linux-x86_64" ;;
    aarch64) asset="nvim-linux-arm64" ;;
    *) return 1 ;;
  esac
  tmp="$(mktemp -d)"
  if ! curl -sSfL -o "$tmp/nvim.tgz" \
        "https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz"; then
    asset="nvim-linux64"   # legacy asset name (pre-2025 releases)
    curl -sSfL -o "$tmp/nvim.tgz" \
      "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" \
      || { rm -rf "$tmp"; return 1; }
  fi
  # verify SHA256 (neovim publishes <asset>.tar.gz.sha256sum beside the tarball)
  if curl -sSfL -o "$tmp/nvim.sha" \
       "https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz.sha256sum"; then
    want="$(awk '{print $1}' "$tmp/nvim.sha" | head -1)"
    got="$(sha256_of "$tmp/nvim.tgz")"
    if [ -n "$want" ] && [ "$want" != "$got" ]; then
      warn "neovim checksum mismatch — refusing to install"; rm -rf "$tmp"; return 1
    fi
  else
    warn "could not fetch neovim checksum — installing unverified"
  fi
  tar xzf "$tmp/nvim.tgz" -C "$tmp" || { rm -rf "$tmp"; return 1; }
  mkdir -p "$HOME/.local/bin"; rm -rf "$HOME/.local/nvim-dist"
  mv "$tmp/$asset" "$HOME/.local/nvim-dist"
  ln -sf "$HOME/.local/nvim-dist/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
}

install_tree_sitter_release() {  # https://github.com/tree-sitter/tree-sitter/releases
  # nvim-treesitter's `main` branch shells out to the tree-sitter CLI to build
  # parsers; without it :TSInstall can't compile anything.
  local os arch asset tmp ver
  case "$(uname -s)" in
    Linux)  os="linux" ;;
    Darwin) os="macos" ;;
    *) return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64)  arch="x64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) return 1 ;;
  esac
  dry && { info "[dry-run] download + install the tree-sitter CLI (GitHub release)"; return 0; }
  ver="$(gh_curl https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest \
         | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$ver" ] || return 1
  asset="tree-sitter-${os}-${arch}.gz"
  tmp="$(mktemp -d)"
  curl -sSfL -o "$tmp/ts.gz" \
    "https://github.com/tree-sitter/tree-sitter/releases/download/v${ver}/${asset}" \
    || { rm -rf "$tmp"; return 1; }
  # unlike neovim/lazygit/fabric, these release binaries ship no checksum file
  warn "tree-sitter publishes no checksums — installing unverified"
  gunzip -c "$tmp/ts.gz" > "$tmp/tree-sitter" || { rm -rf "$tmp"; return 1; }
  mkdir -p "$HOME/.local/bin"; install "$tmp/tree-sitter" "$HOME/.local/bin/tree-sitter"
  rm -rf "$tmp"
}

nvim_recent() {               # true if an installed nvim is >= 0.11.2 (LazyVim v16)
  have nvim || return 1
  local v; v="$(nvim --version 2>/dev/null | sed -n '1s/.*v\([0-9][0-9.]*\).*/\1/p')"
  [ -n "$v" ] && [ "$(printf '%s\n0.11.2\n' "$v" | sort -V | head -1)" = "0.11.2" ]
}

# --- package manager detection ---
PM=""
if   have brew;    then PM=brew        # macOS (or Linuxbrew)
elif have apt-get; then PM=apt
elif have dnf;     then PM=dnf
elif have pacman;  then PM=pacman
elif have zypper;  then PM=zypper
fi
SUDO=""
# Homebrew must NOT run under sudo; the native package managers need it.
[ "$PM" != brew ] && [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"

pkg_install() {
  dry && { info "[dry-run] install package(s): $*"; return 0; }
  # shellcheck disable=SC2086  # $SUDO is intentionally empty (root/brew) → word-split
  case "$PM" in
    brew)   brew install "$@";;
    apt)    $SUDO apt-get install -y "$@";;
    dnf)    $SUDO dnf install -y "$@";;
    pacman) $SUDO pacman -S --noconfirm "$@";;
    zypper) $SUDO zypper install -y "$@";;
    *) return 1;;
  esac
}

# --- snapshot: before a REAL run, copy the configs we may replace into one dated
#     backup folder, so a bad config / error / change of mind is one restore away.
#     Skips paths that are already OUR symlinks (nothing of yours to save). ---
snapshot() {
  dry && return 0
  local src rel dest tgt any=0
  local paths=(
    "$HOME/.zshrc"
    "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshrc"
    "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
    "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
    "${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
    "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
    "${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml"
    "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
    "$HOME/.local/bin/tmux-sessionizer"
    "$HOME/.gitconfig"                    # edited (delta include)
    "$HOME/.zshenv"                       # edited (--xdg ZDOTDIR)
  )
  for src in "${paths[@]}"; do
    [ -e "$src" ] || [ -L "$src" ] || continue
    if [ -L "$src" ]; then
      tgt="$(readlink "$src")"
      case "$tgt" in "$REPO_DIR"/*) continue ;; esac   # already ours — skip
    fi
    rel="${src#"$HOME"/}"; dest="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    if cp -a "$src" "$dest" 2>/dev/null; then any=1; log "backed up $src -> $dest"
    else warn "could not back up $src"; fi
  done
  if [ "$any" -eq 1 ]; then ok "Backed up your current config → $BACKUP_DIR"
  else info "No existing config to back up (fresh setup)."; fi
}

# --- doctor: report what's installed / linked, then exit (no changes) ---
doctor() {
  local cfg="${XDG_CONFIG_HOME:-$HOME/.config}" issues=0
  local G Y R B Z; G="$(c '1;32')"; Y="$(c '1;33')"; R="$(c '1;31')"; B="$(c '1;36')"; Z="$(c 0)"
  dg() { printf '  %s✓%s %s\n' "$G" "$Z" "$*"; }
  dn() { printf '  %s!%s %s\n' "$Y" "$Z" "$*"; issues=$((issues+1)); }
  dx() { printf '  %s✗%s %s\n' "$R" "$Z" "$*"; issues=$((issues+1)); }
  dh() { printf '\n%s%s%s\n' "$B" "$*" "$Z"; }
  short() { printf '%s' "${1/#$HOME/\~}"; }
  dlink() {   # $1 = path, $2 = repo-relative expected target
    local dst="$1" want="$REPO_DIR/$2" tgt
    if [ -L "$dst" ]; then
      tgt="$(readlink "$dst")"
      if [ "$tgt" = "$want" ]; then dg "$(short "$dst") → repo"
      else dn "$(short "$dst") → $tgt (not this repo)"; fi
    elif [ -e "$dst" ]; then dn "$(short "$dst") is a real file (not linked)"
    else dn "$(short "$dst") not linked"; fi
  }

  printf '%sconsole doctor%s  ·  repo: %s  ·  pkg: %s\n' "$B" "$Z" "$REPO_DIR" "${PM:-none}"

  dh "Core"
  for t in zsh git curl starship; do have "$t" && dg "$t ($(command -v "$t"))" || dx "$t missing"; done
  if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git" ]; then dg "zinit cloned"
  else dn "zinit not cloned yet (installs on first zsh launch)"; fi

  dh "CLI tools"
  for t in fzf zoxide eza rg delta lazygit jq yq direnv carapace tmux pass fabric; do
    have "$t" && dg "$t" || dn "$t missing"
  done
  # Debian/Ubuntu ship bat as `batcat` and fd as `fdfind`; count either as present.
  have bat && dg "bat" || { have batcat && dg "bat (batcat)" || dn "bat missing"; }
  have fd  && dg "fd"  || { have fdfind && dg "fd (fdfind)"  || dn "fd missing"; }

  dh "Editor & terminal"
  if have nvim; then
    # route nvim's state to a throwaway dir so `doctor` never writes to your $HOME
    local nst; nst="$(mktemp -d)"
    dg "nvim ($(XDG_STATE_HOME="$nst" nvim --version 2>/dev/null | sed -n 1p))"
    rm -rf "$nst"
  else dn "nvim missing"; fi
  have tree-sitter && dg "tree-sitter CLI" || dn "tree-sitter CLI missing (nvim can't build parsers)"
  have alacritty && dg "alacritty" || dn "alacritty missing (expected on servers)"
  have kitty && dg "kitty" || dn "kitty not installed (config still linked if you use it)"

  dh "Symlinks → repo"
  if [ -L "$cfg/zsh/.zshrc" ]; then dlink "$cfg/zsh/.zshrc" "zsh/.zshrc"   # --xdg layout
  else dlink "$HOME/.zshrc" "zsh/.zshrc"; fi
  dlink "$cfg/starship.toml"                "starship/starship.toml"
  dlink "$cfg/tmux/tmux.conf"               "tmux/tmux.conf"
  dlink "$HOME/.local/bin/tmux-sessionizer" "scripts/tmux-sessionizer.sh"
  dlink "$cfg/alacritty/alacritty.toml"     "alacritty/alacritty.toml"
  dlink "$cfg/kitty/kitty.conf"             "kitty/kitty.conf"
  dlink "$cfg/lazygit/config.yml"           "lazygit/config.yml"
  dlink "$cfg/nvim"                         "nvim"

  dh "Font & git"
  if have fc-list; then
    # grep -c (reads all input) — NOT grep -q, which exits early and can SIGPIPE
    # fc-list on a big font list under `pipefail`, giving a false "not found".
    if [ "$(fc-list 2>/dev/null | grep -ci 'JetBrainsMono Nerd Font')" -gt 0 ]; then
      dg "JetBrainsMono Nerd Font installed"
    else
      dn "JetBrainsMono Nerd Font not found (set your terminal font, or re-run without --no-font)"
    fi
  else dn "fc-list unavailable — can't verify the Nerd Font (normal on macOS)"; fi
  if git config --global --get-all include.path 2>/dev/null | grep -qxF "$REPO_DIR/git/delta.gitconfig"; then
    dg "git-delta include active"
  else dn "git-delta include not set (delta not installed, or install not run)"; fi

  dh "Local overrides"
  if [ -f "$HOME/.zshrc.local" ]; then
    [ -O "$HOME/.zshrc.local" ] && dg "found ~/.zshrc.local — owned by you" \
      || dx "wrong owner on ~/.zshrc.local → .zshrc will refuse to source it"
  else dn "no ~/.zshrc.local yet (optional; template: zsh/zshrc.local.example)"; fi

  dh "Summary"
  if [ "$issues" -eq 0 ]; then printf '  %sall good — nothing to fix%s\n' "$G" "$Z"
  else printf '  %s%d item(s) worth a look%s — run ./install.sh to fix most\n' "$Y" "$issues" "$Z"; fi
}
if [ "$DOCTOR" -eq 1 ]; then set +e; doctor; exit 0; fi

info "Repo:            $REPO_DIR"
info "Package manager: ${PM:-none detected}"
[ "$OFFLINE" -eq 1 ] && info "Offline mode: no internet fetches (packages assumed from your mirror)."

# Back up whatever is there BEFORE touching anything (real runs only).
snapshot

if [ "$PM" = apt ]; then
  # shellcheck disable=SC2086  # $SUDO may be empty
  if dry; then info "[dry-run] apt-get update"; else $SUDO apt-get update -y || true; fi
fi

# --- core ---
info "Installing core packages…"
if [ "$PM" = brew ]; then
  pkg_install zsh git curl || warn "some core packages failed; continuing"
else
  pkg_install zsh git curl unzip fontconfig || warn "some core packages failed; continuing"
fi

# --- fzf ---
have fzf || { info "Installing fzf…"; pkg_install fzf || warn "fzf failed"; }

# --- bat ---
if ! have bat && ! have batcat; then
  info "Installing bat…"; pkg_install bat || warn "bat failed"
fi

# --- fd (find) — Debian/Ubuntu package is 'fd-find', binary 'fdfind' ---
if ! have fd && ! have fdfind; then
  info "Installing fd…"; pkg_install fd-find || pkg_install fd || warn "fd failed"
fi

# --- ripgrep (rg) — fast grep ---
have rg || { info "Installing ripgrep…"; pkg_install ripgrep || warn "ripgrep failed"; }

# --- extras (skipped by --minimal) ---
if [ "$MINIMAL" -eq 0 ]; then
  # git-delta — syntax-highlighting pager for git diff/log/show
  if ! have delta; then
    info "Installing git-delta…"
    pkg_install git-delta || warn "git-delta not in your repos — see https://github.com/dandavison/delta/releases"
  fi
  # tealdeer (tldr) — simplified, offline command examples
  if ! have tldr; then
    info "Installing tealdeer (tldr)…"
    pkg_install tealdeer || warn "tealdeer failed — see https://github.com/tealdeer-rs/tealdeer"
  fi
  if [ "$OFFLINE" -eq 0 ] && ! dry && have tldr; then tldr --update >/dev/null 2>&1 || true; fi
  # lazygit — terminal UI for git
  if ! have lazygit; then
    info "Installing lazygit…"
    if pkg_install lazygit; then :
    elif [ "$OFFLINE" -eq 1 ]; then warn "offline: install lazygit from your mirror"
    else install_lazygit_release || warn "lazygit failed — see https://github.com/jesseduffield/lazygit/releases"
    fi
  fi
  # jq / yq — JSON & YAML processing (ops staples)
  have jq || { info "Installing jq…"; pkg_install jq || warn "jq failed"; }
  have yq || { info "Installing yq…"; pkg_install yq || warn "yq not packaged — see https://github.com/mikefarah/yq"; }
  # direnv — per-directory env (.envrc, with allowlist)
  have direnv || { info "Installing direnv…"; pkg_install direnv || warn "direnv failed — see https://direnv.net"; }
  # rsync — used by the nas-sync backup helper (usually already present)
  have rsync || { info "Installing rsync…"; pkg_install rsync || warn "rsync failed"; }
  # carapace — unified completions for kubectl/aws/docker/terraform/gh, etc.
  if ! have carapace; then
    info "Installing carapace…"
    if pkg_install carapace; then :
    elif [ "$OFFLINE" -eq 1 ]; then warn "offline: install carapace from your mirror"
    else install_carapace_release || warn "carapace failed — see https://carapace.sh"
    fi
  fi
  # tmux — persistent terminal sessions (essential over SSH)
  have tmux || { info "Installing tmux…"; pkg_install tmux || warn "tmux failed"; }
  # tmux plugins: tpm + resurrect + continuum (session persistence across reboots)
  if have tmux && [ "$OFFLINE" -eq 0 ]; then
    for tp in tmux-plugins/tpm tmux-plugins/tmux-resurrect tmux-plugins/tmux-continuum; do
      dest="$HOME/.tmux/plugins/${tp#*/}"
      if [ -d "$dest" ]; then :
      elif dry; then info "[dry-run] clone tmux plugin ${tp#*/}"
      else info "Cloning tmux plugin ${tp#*/}…"
        git clone --depth 1 "https://github.com/$tp" "$dest" >/dev/null 2>&1 \
          || warn "tmux plugin ${tp#*/} clone failed"
      fi
    done
  fi
  # pass — GPG-encrypted Unix password store (needs your own GPG key; see SECURITY.md)
  if ! have pass; then
    info "Installing pass…"
    pkg_install pass || pkg_install password-store || warn "pass failed — see https://www.passwordstore.org"
  fi
  # fabric — run AI "patterns" as Unix filters (skip with --no-fabric; add an API
  # key afterwards via `fabric --setup`, kept in ~/.zshrc.local — never the repo)
  if [ "$NO_FABRIC" -eq 0 ] && ! have fabric; then
    info "Installing fabric…"
    if [ "$OFFLINE" -eq 1 ]; then warn "offline: install fabric from your mirror"
    else install_fabric_release || warn "fabric failed — see https://github.com/danielmiessler/fabric/releases"
    fi
  fi
  # alacritty — GPU-accelerated terminal (client-side; skipped by --server/--no-alacritty)
  if [ "$NO_ALACRITTY" -eq 0 ] && ! have alacritty; then
    info "Installing alacritty…"
    if [ "$PM" = brew ]; then
      run brew install --cask alacritty || warn "alacritty cask failed — see https://alacritty.org"
    else
      pkg_install alacritty || warn "alacritty not packaged here — see https://alacritty.org"
    fi
  fi
fi

# --- Neovim + LazyVim (skipped by --minimal / --no-nvim) ---
if [ "$MINIMAL" -eq 0 ] && [ "$NO_NVIM" -eq 0 ]; then
  info "Setting up Neovim + LazyVim…"
  if dry; then
    # don't call nvim_recent here — invoking nvim would create ~/.local/state/nvim
    info "[dry-run] install build tools + ensure Neovim >= 0.11.2 (LazyVim) + the tree-sitter CLI"
  elif [ "$PM" = brew ]; then
    have cc || warn "run 'xcode-select --install' for a C compiler (nvim treesitter/telescope)"
    nvim_recent || pkg_install neovim || warn "neovim install failed — try: brew install neovim"
  else
    pkg_install gcc make || warn "build tools (gcc/make) failed — some nvim plugins need them"
    if ! nvim_recent; then
      if [ "$OFFLINE" -eq 1 ]; then
        pkg_install neovim || warn "offline: install neovim (>= 0.11.2) from your mirror"
      else
        info "Installing a recent Neovim (LazyVim needs >= 0.11.2)…"
        install_neovim_release || warn "neovim install failed — see https://github.com/neovim/neovim/releases"
      fi
    fi
  fi
  # nvim-treesitter's `main` branch (LazyVim v16) builds parsers with this CLI
  if ! dry && ! have tree-sitter; then
    info "Installing the tree-sitter CLI…"
    pkg_install tree-sitter-cli || {
      if [ "$OFFLINE" -eq 1 ]; then
        warn "offline: install the tree-sitter CLI from your mirror"
      else
        install_tree_sitter_release \
          || warn "tree-sitter CLI failed — nvim can't build parsers; see https://github.com/tree-sitter/tree-sitter/releases"
      fi
    }
  fi
fi

# --- eza (skip in --minimal) ---
if [ "$MINIMAL" -eq 0 ] && ! have eza; then
  info "Installing eza…"
  pkg_install eza || warn "eza not in your repos — see https://github.com/eza-community/eza"
fi

# --- starship — prefer a signed distro/brew package; fall back to the
#     official installer only when it isn't packaged.  https://starship.rs
if ! have starship; then
  info "Installing starship…"
  pkg_install starship || {
    if [ "$OFFLINE" -eq 1 ]; then
      warn "offline: install starship from your mirror"
    else
      warn "starship not packaged here — using the official installer (curl | sh)"
      curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" \
        || warn "starship install failed"
    fi
  }
fi

# --- zoxide — prefer a packaged version; official installer as fallback.
#     https://github.com/ajeetdsouza/zoxide
if ! have zoxide; then
  info "Installing zoxide…"
  pkg_install zoxide || {
    if [ "$OFFLINE" -eq 1 ]; then
      warn "offline: install zoxide from your mirror"
    else
      warn "zoxide not packaged here — using the official installer (curl | sh)"
      curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh \
        || warn "zoxide install failed"
    fi
  }
fi

# --- Nerd Font — https://github.com/ryanoasis/nerd-fonts ---
if [ "$NO_FONT" -eq 0 ]; then
  if dry; then info "[dry-run] install JetBrainsMono Nerd Font"
  elif [ "$PM" = brew ]; then
    info "Installing JetBrainsMono Nerd Font (cask)…"
    brew install --cask font-jetbrains-mono-nerd-font \
      && ok "Font installed — set your terminal font to 'JetBrainsMono Nerd Font'." \
      || warn "font cask failed; rerun with --no-font to skip"
  elif [ "$(fc-list 2>/dev/null | grep -ci 'JetBrainsMono Nerd Font')" -eq 0 ]; then
    info "Installing JetBrainsMono Nerd Font…"
    FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    mkdir -p "$FONT_DIR"; tmp="$(mktemp -d)"
    if curl -sSfL -o "$tmp/JBM.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
      unzip -oq "$tmp/JBM.zip" -d "$FONT_DIR"
      fc-cache -f >/dev/null 2>&1 || true
      ok "Font installed — set your terminal font to 'JetBrainsMono Nerd Font'."
    else
      warn "font download failed; rerun with --no-font to skip"
    fi
    rm -rf "$tmp"
  else
    ok "Nerd Font already present"
  fi
fi

# --- symlinks. Existing real files were already saved by snapshot() into the
#     consolidated backup, so we can replace them; if a snapshot is somehow
#     missing, fall back to an in-place rename rather than lose data. ---
link() {
  local src="$1" dst="$2" rel bak
  dry && { info "[dry-run] link $dst → $src"; return 0; }
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm -f "$dst"                                  # a symlink — nothing of yours to preserve
  elif [ -e "$dst" ]; then
    rel="${dst#"$HOME"/}"; bak="$BACKUP_DIR/$rel"
    if [ -e "$bak" ] || [ -L "$bak" ]; then
      rm -rf "$dst"                               # already in the backup → safe to replace
    else
      warn "no snapshot for $dst — keeping an in-place copy at $dst.pre-console.$STAMP"
      mv "$dst" "$dst.pre-console.$STAMP"
    fi
  fi
  ln -s "$src" "$dst"; ok "linked $dst"
}

info "Linking config…"
if [ "$XDG" -eq 1 ]; then
  ZDOTDIR_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
  if dry; then
    info "[dry-run] mkdir $ZDOTDIR_PATH; ensure 'export ZDOTDIR' in ~/.zshenv"
  else
    mkdir -p "$ZDOTDIR_PATH"
    # ~/.zshenv points zsh at the XDG location; append only if not already set.
    grep -qs 'ZDOTDIR=' "$HOME/.zshenv" 2>/dev/null \
      || printf '\nexport ZDOTDIR="%s"\n' "$ZDOTDIR_PATH" >> "$HOME/.zshenv"
  fi
  link "$REPO_DIR/zsh/.zshrc"            "$ZDOTDIR_PATH/.zshrc"
else
  link "$REPO_DIR/zsh/.zshrc"            "$HOME/.zshrc"
fi
link "$REPO_DIR/starship/starship.toml"  "$HOME/.config/starship.toml"

# lazygit config (symlink the file only, so lazygit's own state.yml stays local)
[ "$MINIMAL" -eq 0 ] && link "$REPO_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
# tmux config
[ "$MINIMAL" -eq 0 ] && link "$REPO_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
# tmux-sessionizer helper on PATH (bound to prefix+f in tmux.conf)
[ "$MINIMAL" -eq 0 ] && { dry || mkdir -p "$HOME/.local/bin"; \
  link "$REPO_DIR/scripts/tmux-sessionizer.sh" "$HOME/.local/bin/tmux-sessionizer"; }
# nas-sync helper on PATH (rsync backups/pass → a NAS; set NAS_DEST in ~/.zshrc.local)
[ "$MINIMAL" -eq 0 ] && link "$REPO_DIR/scripts/nas-sync.sh" "$HOME/.local/bin/nas-sync"
# alacritty config (client-side terminal; skipped by --minimal/--server/--no-alacritty)
[ "$MINIMAL" -eq 0 ] && [ "$NO_ALACRITTY" -eq 0 ] && \
  link "$REPO_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
# kitty config (linked whether or not kitty is installed; skipped by --minimal/--server/--no-kitty)
[ "$MINIMAL" -eq 0 ] && [ "$NO_KITTY" -eq 0 ] && \
  link "$REPO_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# Neovim / LazyVim config (whole dir; lazy-lock.json lands in the repo for version pinning)
if [ "$MINIMAL" -eq 0 ] && [ "$NO_NVIM" -eq 0 ]; then
  link "$REPO_DIR/nvim" "$HOME/.config/nvim"
fi

# --- point git at delta via an include (non-destructive & revertible: your
#     existing ~/.gitconfig keys are untouched; drop the include to undo) ---
if have delta; then
  frag="$REPO_DIR/git/delta.gitconfig"
  if git config --global --get-all include.path 2>/dev/null | grep -qxF "$frag"; then
    ok "git-delta include already active"
  elif dry; then
    info "[dry-run] add git-delta include to ~/.gitconfig"
  else
    info "Configuring git to use delta…"
    git config --global --add include.path "$frag"
    ok "git uses delta (undo: git config --global --unset-all include.path '$frag')"
  fi
fi

# --- default shell (skip if the login shell is already some zsh) ---
if [ "$NO_CHSH" -eq 0 ]; then
  ZSH_BIN="$(command -v zsh || true)"
  case "${SHELL:-}" in
    */zsh) : ;;   # already a zsh — don't force a different one (brew vs system)
    *)
      if [ -n "$ZSH_BIN" ]; then
        if dry; then info "[dry-run] chsh -s $ZSH_BIN  (set default login shell)"
        else
          info "Setting default shell to $ZSH_BIN…"
          chsh -s "$ZSH_BIN" || warn "chsh failed — run manually: chsh -s $ZSH_BIN"
        fi
      fi
      ;;
  esac
fi

echo
if dry; then
  ok   "Dry run complete — nothing was installed, linked, or changed."
  info "Re-run without --dry-run to apply, or './install.sh --doctor' to inspect the current state."
else
  ok   "Done!  Start your new shell with:  exec zsh"
  info "First zsh launch auto-installs zinit + plugins (one-time, ~10s)."
  [ "$MINIMAL" -eq 0 ] && [ "$NO_NVIM" -eq 0 ] && \
    info "First 'nvim' launch bootstraps LazyVim + its plugins (one-time)."
  [ -d "$BACKUP_DIR" ] && info "Previous config backed up in: $BACKUP_DIR"
  info "Audit log: $LOGFILE"
fi

# Failures above are non-fatal (they only `warn`); exit success so callers/CI
# don't trip over a trailing conditional's exit status.
exit 0
