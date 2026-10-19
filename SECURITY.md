# Security posture

Notes for running this config on servers and privileged workstations. This is a
personal dotfiles repo, not a security product — but it tries not to make you
less safe. See [`ROADMAP.md`](ROADMAP.md) for what's still planned.

## Secrets & shell history

- **Keep secrets out of history:** commands typed with a **leading space** are
  never written to `~/.zsh_history` (`HIST_IGNORE_SPACE`) **or to atuin's database**
  (`history_filter = ["^\\s"]`). Prefix any command that contains a token/password
  with a space.
- **atuin** (`Ctrl-R`) keeps every command, its directory, exit code and duration in a
  local SQLite file under `~/.local/share/atuin/`. Its `secrets_filter` drops lines that
  look like AWS keys, GitHub/Slack tokens and similar; `auto_sync` and `update_check`
  are **off**, so nothing leaves the machine unless you `atuin login` and turn sync on.
  `Enter` in the picker edits the line, it never runs it (`enter_accept = false`), and
  atuin's hosted-AI key binding is disabled (`--disable-ai`).
- **superfile** has `auto_check_update = false`; **sesh** makes no network calls.
- **Imported history is not filtered.** The installer's one-time `atuin import` copies your
  existing `~/.zsh_history` as-is, then runs `atuin history prune` so entries matching the
  secrets/leading-space filters are deleted again; filters otherwise apply only at record time.
- **tmux-resurrect** saves window layouts every 15 min. Pane *contents* are off, and the
  save strategy is `pane_current_command`, so only the program name (`nvim`, `ssh`) is written to
  `~/.tmux/resurrect/`, never its arguments (which can carry passwords or tokens).
- **Clipboard over SSH:** tmux has `set-clipboard on`, so programs inside a pane (nvim, a remote
  shell) can write your local clipboard through OSC 52 — that is what makes yank-over-SSH work,
  and it also means a hostile file `cat`ed on a server could replace what you are about to paste.
  On boxes where that matters, set `set -g set-clipboard external` in `~/.tmux.conf.local` or the
  repo file: tmux's own copy-mode still reaches the clipboard, applications no longer can.
- **`~/.zshrc.local` is sourced only if you own it *and* it is not group/world-writable**;
  the same expectation applies to the repo clone and `~/.local/bin` (first on `PATH`): keep them
  `755`, owned by you.
- **Never commit secrets.** Machine-specific values (tokens, private paths, work
  aliases) go in `~/.zshrc.local`, which is git-ignored and sourced **only if you
  own it** (guards against another account planting one). Start from
  [`zsh/zshrc.local.example`](zsh/zshrc.local.example).
- The prompt never prints secrets; it only shows `user@host`, git, and the
  Kubernetes/AWS *context names* (not credentials).

## Supply chain

- Tools install from your **distro/Homebrew package manager first**; the piped
  `curl | sh` installers (starship, zoxide) are a labelled fallback only.
- **`bootstrap.sh` is download-then-run, never `curl | sh`.** It exists only to
  install `git` on a box that has none (you cannot clone this repo without it), and
  it does that through your package manager like everything else. The README tells
  you to fetch it, read it, then run it — so the same posture applies to this repo's
  own front door. It refuses to overwrite a non-git directory, and `--dry-run`
  prints every step without touching the disk.
- **Release binaries are checksum-verified and fail closed**: lazygit, neovim, carapace,
  fabric, atuin, sesh, superfile, the tree-sitter CLI and the Nerd Font zip are SHA256-checked
  against their published checksums and refused on mismatch — and also refused when the
  checksum file cannot be fetched or does not list the asset (no silent "unverified" path).
  CI unit-tests the refusal offline (`scripts/ci-checksum-check.sh`). Version lookups hit the GitHub API and use `GITHUB_TOKEN`/`GH_TOKEN`
  when set (only to lift the anonymous rate limit; the token is never sent to the
  download CDN).
- **Pin zinit** for reproducible/air-gapped builds by exporting `ZINIT_PIN=<sha>`
  before the shell starts (in `~/.zshenv`, not `~/.zshrc.local`). The pin is fetched
  explicitly into the shallow clone; a pin that cannot be fetched is reported, not ignored.
  The zinit *plugins*, tpm and its plugins still track their default branches — pinning them
  is on the roadmap.
- **Arch note:** `pkg_install` runs `pacman -Syu --needed`, i.e. a full system upgrade
  alongside the requested packages, because `-Sy` + `-S` partial upgrades are unsupported on Arch.
- **Air-gapped:** run `./install.sh --offline` to skip every internet fetch
  (packages then come from your internal mirror). The remaining network steps happen
  on first *launch*, not install: zinit cloning itself + plugins on the first shell, and
  lazy.nvim cloning LazyVim + plugins on the first `nvim` (lazy's update checker also
  polls GitHub periodically). Pre-seed `~/.local/share/zinit` (`scripts/vendor-plugins.sh`)
  and `~/.local/share/nvim` on locked-down hosts, or keep nvim off them (`--no-nvim`).
- **CI** checks out with `persist-credentials: false` and pins actions by commit SHA, so the
  read-only token never lands in the `.git/config` that is bind-mounted into the test containers.

## Completions & PATH

- `compinit` runs with `-i`: it keeps the security check and **skips** insecure
  (world/group-writable) completion directories instead of loading them — closing
  a completion-injection / privilege-escalation vector on shared hosts. It never
  runs with `-C` (which would bypass the check entirely).

## Git

- git-delta is wired in via an **`include.path`** into `~/.gitconfig` — additive
  and reversible; your existing git config is never rewritten. Undo with:
  `git config --global --unset-all include.path '<repo>/git/delta.gitconfig'`.

## Key agents (SSH / GPG)

- `GPG_TTY` is exported so `gpg` can prompt in your terminal (commit signing).
- **ssh-agent is left to your platform** (gnome-keyring, systemd, 1Password,
  Vault, etc.) to avoid spawning a conflicting one. To auto-start a plain agent
  when none is present, opt in via `~/.zshrc.local` — see the example file.
- **External agents (1Password / HashiCorp Vault / gpg-agent):** point
  `SSH_AUTH_SOCK` at the agent's socket from `~/.zshrc.local` — e.g. 1Password
  `export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"`. This keeps private keys in
  the vault/HSM (never on disk) — the PAM-friendly setup.
- **Port-forward helpers (`fwd`/`rfwd`/`socks`)** just wrap `ssh -N -L/-R/-D`; they
  add no keys or trust changes and bind to **localhost** by default (a tunnel is only
  reachable from the machine that opened it — no `GatewayPorts`). Host aliases belong
  in `~/.ssh/config.local` (`chmod 600`, git-ignored, pulled in via an `Include` line),
  never in the repo — same rule as `~/.zshrc.local`.

## Passwords & AI keys

- **`pass`** encrypts every secret to **your own GPG key** — nothing is installed
  with a key, and the store (`~/.password-store`) is yours to keep local or push to
  a **private** git remote. It complements the external SSH-agent setup above; use
  whichever fits the host. `GPG_TTY` is exported so `pass` can prompt for your
  passphrase in the terminal.
- **`fabric`** needs a provider API key. Run `fabric --setup` (it writes to
  `~/.config/fabric`, not the repo) and keep the key in `~/.zshrc.local`
  (git-ignored). Prefix any one-off `KEY=… fabric …` invocation with a leading
  space so it never lands in `~/.zsh_history` (`HIST_IGNORE_SPACE`). The binary is
  installed from a **SHA256-verified** GitHub release, same as lazygit/neovim.

## NAS backup (nas-sync)

- `nas-sync` only ever runs `rsync` (additive — no `--delete`); it doesn't store or
  transmit credentials itself. The destination (`NAS_DEST`) and any SMB credentials
  live **per-machine** in `~/.zshrc.local` / `~/.nas-cred` (`chmod 600`), never the
  repo. Your `pass` store is GPG-encrypted, so it stays encrypted at rest on the NAS.

## Undo

Before a real run touches anything, `install.sh` copies every config it may replace
(plus `~/.gitconfig` and `~/.zshenv`) into one dated folder
`~/backup/zsh/<ts>/` — so a bad config, an error mid-run, or a
change of mind is a single `cp -a` away. `--dry-run` and `--doctor` never back up
(they change nothing). `./uninstall.sh` then removes only the symlinks that point
into this repo and the git-delta include; it never deletes real files or packages,
and it prints the newest backup to restore from. `install.sh` also writes an audit
trail of everything it changed to `~/.local/state/console/install-<ts>.log`.

## Reporting

This repo has no formal disclosure process; open an issue on
<https://github.com/morandeirachema/console> for anything security-relevant.
