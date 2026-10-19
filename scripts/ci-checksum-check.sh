#!/usr/bin/env bash
# CI helper — offline unit test: every install_*_release helper must REFUSE a download whose
# SHA256 does not match the published checksum, and install nothing. curl/uname are stubbed, so
# this runs in ~1 s with no network. Run from anywhere: scripts/ci-checksum-check.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
HOME="$(mktemp -d)"; export HOME
fail=0; BAD="$(printf '0%.0s' {1..64})"
# pull only the helpers (and the two functions they call) out of install.sh
eval "$(sed -n '/^sha256_of()/p; /^gh_curl() {/,/^}/p; /^install_[a-z_]*_release() {/,/^}/p' install.sh)"
dry()  { return 1; }
info() { :; }
warn() { :; }
have() { command -v "$1" >/dev/null 2>&1; }
uname() { case "${1:-}" in -m) echo x86_64;; -s) echo Linux;; *) command uname "$@";; esac; }
# a fake GitHub: version lookups succeed, every checksum file lists a wrong hash, downloads are junk
curl() {
  local out="" url=""
  while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift;; -H) shift;; -*) ;; *) url="$1";; esac; shift; done
  {
    case "$url" in
      *api.github.com*) printf '{"tag_name": "v9.9.9", "assets": [{"name": "tree-sitter-linux-x64.gz", "digest": "sha256:%s"}]}' "$BAD";;
      *checksums*|*SHA-256.txt|*.sha256|*.sha256sum)
        for a in lazygit_9.9.9_Linux_x86_64.tar.gz sesh_Linux_x86_64.tar.gz superfile-linux-v9.9.9-amd64.tar.gz \
                 carapace-bin_9.9.9_linux_amd64.tar.gz fabric_Linux_x86_64.tar.gz nvim-linux-x86_64.tar.gz \
                 atuin-x86_64-unknown-linux-gnu.tar.gz JetBrainsMono.zip; do printf '%s  %s\n' "$BAD" "$a"; done;;
      *) printf 'junk';;
    esac
  } | if [ -n "$out" ]; then cat >"$out"; else cat; fi
}
for t in lazygit atuin sesh superfile carapace fabric neovim tree_sitter; do
  if ! declare -F "install_${t}_release" >/dev/null; then echo "  ✗ install_${t}_release missing"; fail=1; continue; fi
  "install_${t}_release" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 1 ] && [ -z "$(ls -A "$HOME/.local/bin" 2>/dev/null)" ]; then echo "  ✓ $t refused the bad checksum"
  else echo "  ✗ $t: rc=$rc, installed: $(ls -A "$HOME/.local/bin" 2>/dev/null | tr '\n' ' ')"; fail=1; fi
  rm -rf "$HOME/.local"
done
rm -rf "$HOME"
[ "$fail" -eq 0 ] && echo "checksum refusal OK" || echo "checksum refusal FAILED"
exit "$fail"
