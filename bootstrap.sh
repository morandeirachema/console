#!/bin/sh
# ============================================================
#  bootstrap.sh — get console onto a bare box that has no git yet
#
#  install.sh installs git for you, but you need git to clone the repo that
#  holds install.sh. This closes that gap: it installs git (plus curl and bash,
#  which install.sh needs moments later) with your system's package manager,
#  clones the repo, and hands off to install.sh.
#
#  Fetch it, read it, then run it:
#    curl -fsSLO https://raw.githubusercontent.com/morandeirachema/console/main/bootstrap.sh
#    less bootstrap.sh
#    sh bootstrap.sh [options] [install.sh flags...]
#
#    --dir PATH     where to clone (default: ~/code/console, or $CONSOLE_DIR)
#    --repo URL     clone from somewhere else — a fork, or a local path
#    --no-install   clone only; don't run install.sh afterwards
#    --dry-run      print what this would do and touch nothing
#    -h|--help      this text
#
#  Any other flag is passed straight through to install.sh (--minimal, --server,
#  --no-font, …). Note that --dry-run above is bootstrap's own: to preview
#  install.sh itself, use --no-install and then run `<dir>/install.sh --dry-run`.
#
#  POSIX sh on purpose — it has to run before we can assume bash exists.
# ============================================================
set -eu

REPO_URL="https://github.com/morandeirachema/console.git"
DEST="${CONSOLE_DIR:-$HOME/code/console}"
DRY=0; NO_INSTALL=0
REST=""   # flags forwarded to install.sh

c()    { printf '\033[%sm' "$1"; }
info() { printf '%s▶%s %s\n' "$(c '1;36')" "$(c 0)" "$*"; }
ok()   { printf '%s✓%s %s\n' "$(c '1;32')" "$(c 0)" "$*"; }
warn() { printf '%s!%s %s\n' "$(c '1;33')" "$(c 0)" "$*"; }
die()  { printf '%s✗%s %s\n' "$(c '1;31')" "$(c 0)" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
dry()  { [ "$DRY" -eq 1 ]; }
# run a mutating command, or (in --dry-run) just print what it would do
run()  { if dry; then info "[dry-run] $*"; else "$@"; fi; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)        [ $# -ge 2 ] || die "--dir needs a path";  DEST="$2";     shift;;
    --dir=*)      DEST="${1#*=}";;
    --repo)       [ $# -ge 2 ] || die "--repo needs a URL";  REPO_URL="$2"; shift;;
    --repo=*)     REPO_URL="${1#*=}";;
    --no-install) NO_INSTALL=1;;
    --dry-run)    DRY=1;;
    -h|--help)    grep '^#' "$0" | sed '1d;s/^# \{0,1\}//'; exit 0;;   # 1d drops the shebang
    # everything else belongs to install.sh; its flags are all plain --words,
    # so accumulating them in a string loses nothing
    *)            REST="$REST $1";;
  esac
  shift
done

# --- package manager detection (same rules as install.sh) ---
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
    apt)    $SUDO apt-get update -y || true; $SUDO apt-get install -y "$@";;
    dnf)    $SUDO dnf install -y "$@";;
    pacman) $SUDO pacman -Syu --needed --noconfirm "$@";;
    zypper) $SUDO zypper install -y "$@";;
    *) return 1;;
  esac
}

# --- 1. the three tools install.sh can't bootstrap for itself ---
missing=""
have git  || missing="$missing git"
have curl || missing="$missing curl"
have bash || missing="$missing bash"

if [ -n "$missing" ]; then
  if [ -z "$PM" ]; then
    [ "$(uname -s)" = Darwin ] &&
      die "no Homebrew — run 'xcode-select --install' (that gives you git), or install https://brew.sh, then re-run"
    die "no supported package manager (apt/dnf/pacman/zypper/brew) — install$missing yourself, then re-run"
  fi
  info "Installing:$missing"
  # shellcheck disable=SC2086  # deliberate word-split: $missing is a list of package names
  pkg_install $missing || warn "package install reported an error — checking what landed anyway"
else
  ok "git, curl and bash already present"
fi
dry || have git || die "git still isn't available — install it by hand, then re-run"

# --- 2. clone, or fast-forward an existing clone ---
if [ -e "$DEST" ]; then
  [ -d "$DEST/.git" ] || die "$DEST exists and is not a git clone — move it aside, or pass --dir <path>"
  info "$DEST already exists — updating it"
  run git -C "$DEST" pull --ff-only || warn "not fast-forwardable — keeping what's on disk"
else
  info "Cloning $REPO_URL → $DEST"
  run mkdir -p "$(dirname "$DEST")"
  run git clone "$REPO_URL" "$DEST"
fi

# --- 3. hand off to install.sh ---
if dry; then
  if [ "$NO_INSTALL" -eq 1 ]; then info "[dry-run] would stop here (--no-install)"
  else                             info "[dry-run] would run: $DEST/install.sh$REST"; fi
  ok "dry run — nothing changed"
  exit 0
fi

[ -f "$DEST/install.sh" ] || die "no install.sh in $DEST — is that really the console repo?"

if [ "$NO_INSTALL" -eq 1 ]; then
  ok "Cloned to $DEST"
  info "Next: $DEST/install.sh   (preview it first with --dry-run)"
  exit 0
fi

ok "Cloned to $DEST — handing off to install.sh"
# shellcheck disable=SC2086  # deliberate word-split: $REST is a list of plain --word flags
if [ -x "$DEST/install.sh" ]; then exec "$DEST/install.sh" $REST
else                               exec bash "$DEST/install.sh" $REST; fi
