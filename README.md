<div align="center">

# ⌨️ &nbsp;console

<h3>Turn a plain terminal into a fast, friendly, guided workspace — <strong>one clone, every machine.</strong></h3>

[![CI](https://github.com/morandeirachema/zsh/actions/workflows/ci.yml/badge.svg)](https://github.com/morandeirachema/zsh/actions/workflows/ci.yml)
![shell](https://img.shields.io/badge/shell-zsh-1e88e5)
![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-4c566a)
![prompt](https://img.shields.io/badge/prompt-starship-DD0B78)
![theme](https://img.shields.io/badge/theme-Catppuccin%20Mocha-cba6f7)

```console
 󰕈    ~/code/console    main   !2 ?1                              2.4s   14:32:07
❯ ▏
```

*New to all this? Start with the **[2-minute mental model](#-never-used-a-terminal-like-this-2-minute-mental-model)**.*
*Just want it running? **[Quick start](#-quick-start)**.*

**[Mental model](#-never-used-a-terminal-like-this-2-minute-mental-model)** ·
**[Quick start](#-quick-start)** ·
**[Guided tour](#-a-guided-tour)** ·
**[Cheat sheet](#-cheat-sheet)** ·
**[Safety net](#-safety-net-preview-inspect-back-up-restore)** ·
**[Security](#-security--production)**

</div>

---

## 👋 What is this?

A terminal, out of the box, is a black rectangle where you type commands and hope
you remember them. **`console` turns that rectangle into a workspace that helps you
as you type** — it suggests the rest of your commands, colours mistakes red before
you hit Enter, finds files and folders in a couple of keystrokes, shows you exactly
where you are, and keeps your work alive when your connection drops.

It's a **dotfiles** repo: a folder of configuration files you `git clone` once and
apply with a single command. Do that on your laptop, a server, or a fresh cloud VM
and they all look and behave **identically**. It started as one person's desktop
shell and grew into something safe to run on production servers.

> [!NOTE]
> You don't need to know zsh, tmux, git, or Vim to use this — the sections below
> teach each one from scratch. If a word is unfamiliar, keep reading; it's
> explained.

---

## 🧠 Never used a terminal like this? (2-minute mental model)

Three different programs stack on top of each other every time you open a terminal.
Knowing which is which makes everything else click:

```text
your screen
└─ Terminal emulator   (Alacritty)   the app/window that draws text, colours, fonts
   └─ Shell            (zsh)         reads your keystrokes and runs your commands
      └─ Prompt        (starship)    the ❯ line: where you are, git status, the clock
         ❯ git status               ← you type here; the shell runs it
```

- **Terminal emulator** — the *window*. It just displays characters and sends your
  keypresses inward. `console` ships one ([Alacritty](https://alacritty.org)), but
  any terminal works.
- **Shell** — the *program that runs commands*. The default on most systems is
  `bash`; `console` uses **[zsh](https://www.zsh.org)**, which is compatible but far
  more helpful (suggestions, colours, smarter completion).
- **Prompt** — the little line before your cursor. `console` uses
  **[starship](https://starship.rs)** to pack useful context into it (folder, git
  branch, how long the last command took…).
- **Dotfiles** — the config files that shape all of the above. They start with a
  `.` (e.g. `~/.zshrc`), which is why they're "hidden". This repo *is* your dotfiles.

**How it applies (the important trick):** `install.sh` doesn't *copy* files into your
home directory — it **symlinks** them (creates a shortcut) back to this repo. So once
installed, editing a file in `~/code/console` **is** editing your live config. Pull an
update, and every machine gets it. Change your mind, and `./uninstall.sh` removes the
shortcuts and leaves your originals untouched.

> [!TIP]
> A command "in your terminal" is just a word you type and run. When this guide says
> *run `foo`*, it means: type `foo`, press Enter. Press `Ctrl-C` to cancel anything
> that's running or a line you don't want to submit.

---

## 🚀 Quick start

**If you already have `git`** — the installer adds everything else, for your distro,
automatically:

```bash
git clone https://github.com/morandeirachema/zsh.git ~/code/console
cd ~/code/console
./install.sh          # want to look before you leap? ./install.sh --dry-run
exec zsh              # start your new shell (or just open a new terminal)
```

**On a bare box with no `git` yet** — a fresh VM or container can't run the clone
above, and `install.sh` can't help because it lives *inside* the repo. `bootstrap.sh`
breaks that circle: it installs `git` with your package manager, clones, and hands off.
Fetch it, read it, run it:

```bash
curl -fsSLO https://raw.githubusercontent.com/morandeirachema/zsh/main/bootstrap.sh
less bootstrap.sh     # ~135 lines — read before you run, as with any installer
sh bootstrap.sh       # any install.sh flag works here too: sh bootstrap.sh --server
```

<sub>`--dir PATH` clones somewhere other than `~/code/console` · `--repo URL` uses a fork ·
`--no-install` clones without running the installer · `--dry-run` prints the plan and
changes nothing.</sub>

That's it. The installer detects your package manager, installs any missing tools,
**backs up anything it will replace** (see [Safety net](#-safety-net-preview-inspect-back-up-restore)),
then links this repo into place. Your **first** `zsh` launch spends ~10 s installing
plugins once; every launch after is instant. Your first `nvim` launch does the same
for the editor.

> [!TIP]
> **Preview first:** `./install.sh --dry-run` prints everything it *would* do and
> changes nothing. **Already set up?** `./install.sh --doctor` reports what's
> installed, what's linked, and what's missing.

<details>
<summary><b>🍎 macOS notes &nbsp;·&nbsp; 🚩 every install flag</b></summary>

<br>

**macOS:** install [Homebrew](https://brew.sh) first and, for Neovim's syntax
engine, the Xcode command-line tools (`xcode-select --install`). Your login shell is
already zsh, so it isn't changed; the font is installed via `brew --cask`.

| Flag | Effect |
| ---- | ------ |
| `--dry-run` | print every package/symlink/change the run **would** make — touch nothing |
| `--doctor` | health check: report tools, symlinks, font, git config — then exit |
| `--minimal` | zsh + plugins + prompt only (skip the extra CLI tools, nvim, font) |
| `--server` | headless box: skip the Nerd Font **and** Alacritty (both live on your client) |
| `--offline` | air-gapped: no internet fetches — packages come from your mirror |
| `--xdg` | put `.zshrc` under `ZDOTDIR=~/.config/zsh` to keep `$HOME` tidy |
| `--no-nvim` | don't install Neovim/LazyVim or touch `~/.config/nvim` |
| `--no-fabric` | don't install [fabric](https://github.com/danielmiessler/fabric) (the AI-patterns CLI) |
| `--no-alacritty` | don't install [Alacritty](https://alacritty.org) or link its config |
| `--no-kitty` | don't link the [kitty](https://sw.kovidgoyal.net/kitty/) terminal config |
| `--no-font` | skip the Nerd Font download |
| `--no-chsh` | don't change your default login shell |
| `-y`, `--yes` | non-interactive |

</details>

> [!IMPORTANT]
> **Fonts & icons.** The prompt uses special glyphs (folder, git, distro icons) that
> need a **Nerd Font**. The bundled Alacritty **and kitty** configs already set it. On
> any other terminal, set its font to **JetBrainsMono Nerd Font** (e.g. kitty:
> `font_family JetBrainsMono Nerd Font`). Seeing boxes like `□`? That's a missing
> font, not a broken install.

---

## 🧩 The tools at a glance

Everything here is free, open-source, and cross-platform. You'll meet each one in the
[guided tour](#-a-guided-tour) below.

| | Tool | In one line |
| --- | ------ | ------ |
| 🔌 | [zinit](https://github.com/zdharma-continuum/zinit) | plugin manager — loads zsh plugins **async** so startup stays instant |
| 🚀 | [starship](https://starship.rs) | the prompt: puts useful context on your command line |
| 🔍 | [fzf](https://github.com/junegunn/fzf) | **fuzzy finder** — search history, files, and folders by typing a few letters |
| 📁 | [zoxide](https://github.com/ajeetdsouza/zoxide) | a smarter `cd` that learns your habits (`z proj`) |
| 📃 | [eza](https://github.com/eza-community/eza) · [bat](https://github.com/sharkdp/bat) | prettier `ls` / `cat` (colours, icons, git status, line numbers) |
| ⚡ | [fd](https://github.com/sharkdp/fd) · [ripgrep](https://github.com/BurntSushi/ripgrep) | fast, friendly `find` / `grep` |
| 🌈 | [delta](https://github.com/dandavison/delta) | turns `git diff` into a readable, syntax-highlighted view |
| 📖 | [tealdeer](https://github.com/tealdeer-rs/tealdeer) | `tldr` — dead-simple example-first help for any command |
| 🐙 | [lazygit](https://github.com/jesseduffield/lazygit) | a full **visual git** app in your terminal — no flags to memorise |
| ✏️ | [Neovim](https://neovim.io) + [LazyVim](https://www.lazyvim.org) | a modern, batteries-included text editor |
| 🧮 | [jq](https://github.com/jqlang/jq) · [yq](https://github.com/mikefarah/yq) | slice and query JSON / YAML |
| 🌱 | [direnv](https://direnv.net) · [carapace](https://carapace.sh) | per-folder env vars · smart Tab-completion for 1000+ commands |
| 🪟 | [tmux](https://github.com/tmux/tmux) | keep terminals **alive** across disconnects; split the screen |
| 🔑 | [pass](https://www.passwordstore.org) | GPG-encrypted password manager (bring your own key) |
| 🤖 | [fabric](https://github.com/danielmiessler/fabric) | run AI prompts as normal commands (`--no-fabric` to skip) |
| 🖥️ | [Alacritty](https://alacritty.org) | fast GPU terminal, pre-themed to match (`--no-alacritty` to skip) |

---

## 🧭 A guided tour

Read top to bottom the first time, or jump to what you need:
**[zsh](#-zsh-the-shell-that-finishes-your-sentences)** ·
**[prompt](#-the-prompt-reading-your-surroundings)** ·
**[finding things](#-finding-things-fast)** ·
**[tmux](#-tmux-never-lose-your-work)** ·
**[SSH tunnels](#-ssh-tunnels-port-forwarding)** ·
**[git](#-git-without-the-pain)** ·
**[Neovim](#-neovim-modal-editing-gently)** ·
**[AI & passwords](#-ai-and-passwords)**

---

### 🐚 zsh: the shell that finishes your sentences

`zsh` is the program that runs your commands. `console` layers a few plugins on top
that make it feel like it's helping you:

- **Autosuggestions** — as you type, the rest of a command you've run before appears
  in **grey**. Press **`→`** (or `End`) to accept it, `Ctrl-→` to accept one word.
  You'll re-type far less.
- **Syntax highlighting** — a valid command turns **green**, an unknown one **red**,
  *before* you press Enter. Red = typo. Catch mistakes early.
- **Smarter Tab** — press **`Tab`** and instead of a dumb list you get a **fuzzy,
  searchable menu** with file previews ([fzf-tab](https://github.com/Aloxaf/fzf-tab)).
  Start typing to filter it.
- **History that reads your mind** — type the start of an old command and press
  **`↑`** to cycle only through matching history.

> [!TIP]
> **Try it now:** type `cd ~/code` and press Enter, then just type `cd` and press
> `Tab` — fuzzy-pick a subfolder. Type `gi` and watch the colour; type `git` and see
> it go green.

<details>
<summary><b>The plugins doing the work</b> (all loaded asynchronously)</summary>

<br>

| Plugin | What you get |
| ------ | ------------ |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | greys out the rest of a matching past command; `→`/`End` accepts |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | live green/red command colouring |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | replaces the plain `Tab` menu with a fuzzy selector + previews |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | `↑`/`↓` cycles only history matching what you typed |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | a big bundle of extra Tab-completion definitions |
| [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use) | nudges you when a command has an alias you defined |

Plus [**carapace**](https://carapace.sh): value-aware completion for real tools —
`kubectl get pods -n <Tab>` completes your namespaces, `git checkout <Tab>` your
branches, `aws --profile <Tab>` your profiles.

</details>

**The keys worth learning first:**

| Key | Does |
| --- | ---- |
| `→` / `End` | accept the grey autosuggestion (`Ctrl-→` = one word) |
| `Tab` | fuzzy completion menu with previews |
| `Ctrl-R` | fuzzy-search your entire command **history** |
| `Ctrl-T` | fuzzy-pick a **file** into the line (with a preview) |
| `Alt-C` | fuzzy **`cd`** into a subfolder (with a tree preview) |
| `Ctrl-/` | toggle the preview pane in any of the above |
| `↑` / `↓` · `Ctrl-P` / `Ctrl-N` | history matching what you've typed so far |
| `Ctrl-C` · `Ctrl-L` | cancel the current line · clear the screen |

---

### 🎨 The prompt: reading your surroundings

The prompt is the line you type on. `console`'s ([starship](https://starship.rs))
prompt is a row of rounded "pills" — and **empty ones disappear**, so it's never
noisy. Each pill answers a question:

| Pill | Answers | Shows when |
| ---- | ------- | ---------- |
| `user@host` | *which machine am I on?* (root shown in **red**) | you're connected over SSH |
| `󰕈 os` | *which OS / distro?* | always |
| `directory` | *where am I?* — repo root is **bold**, long paths shrink to `…/` | always |
| `git` | *what branch, and is it dirty?* | inside a git repo |
| `language` | *Node / Python / Rust / Go / Java / PHP / C version* | inside a matching project |
| `☸ k8s ·  aws · docker` | *which cluster / cloud account / container?* | when those are set |
| *(far right)* | *how long the last command took* + *the time* | always |

Git status uses tiny glyphs: `!` modified · `?` untracked · `+` staged · `»` renamed
· `✘` deleted · `⇡`/`⇣` ahead/behind the remote. And the `❯` itself turns **red** when
your last command failed — a glance tells you if something went wrong.

> [!TIP]
> That `user@host` badge and the cluster/cloud pills are a **safety feature**: over
> SSH on a production box, you can *see* you're not on your laptop before you run
> something. Scope them to only appear in infra folders via the commented `detect_*`
> filters in [`starship.toml`](starship/starship.toml).

---

### 🔍 Finding things fast

Most terminal time is spent *locating* things — an old command, a file, a folder.
`console` makes all three a couple of keystrokes. The magic word is **fuzzy**: you
don't type the exact name, just a few letters *in order*, and it narrows as you go.

- **`Ctrl-R` — "what was that command?"** Press it, type a fragment (`docker`, `ssh
  prod`…), pick from the list, Enter. Beats scrolling `↑` fifty times.
- **`Ctrl-T` — "insert a file path."** Building a command and need a file? `Ctrl-T`,
  fuzzy-find it, and its path drops into your line — with a `bat` preview of the file.
- **`Alt-C` — "cd somewhere."** Fuzzy-jump into any subfolder, tree preview included.
- **`z` (zoxide) — "take me to that project."** After you've visited a folder once,
  `z proj` jumps straight there from anywhere — it ranks folders by how often/recently
  you use them. `zi` picks interactively.

And the everyday commands are upgraded, too:

| Instead of | You get | Which means |
| ---------- | ------- | ----------- |
| `ls` | [eza](https://github.com/eza-community/eza) | colours, icons, git status, `--tree` |
| `cat` | [bat](https://github.com/sharkdp/bat) | syntax highlighting + line numbers |
| `find` | [fd](https://github.com/sharkdp/fd) | simpler syntax, respects `.gitignore`, fast |
| `grep` | [ripgrep (`rg`)](https://github.com/BurntSushi/ripgrep) | searches whole trees in milliseconds |

> [!TIP]
> Forgot a command's options? Run **`tldr <command>`** (e.g. `tldr tar`) for a handful
> of copy-pasteable examples instead of a wall of `man`.

---

### 🪟 tmux: never lose your work

**The problem it solves:** close the terminal, lose the SSH connection, or reboot —
and everything you had running is gone. **[tmux](https://github.com/tmux/tmux)** ("terminal
multiplexer") keeps your terminals running in the background so you can **detach** and
**re-attach** later, exactly where you left off. It also splits one window into many
panes. It's the single biggest quality-of-life upgrade for anyone who uses SSH.

The mental model — four nested things:

```text
tmux server                       one background process; survives disconnects & logouts
└─ session   "console"            a named workspace, usually one per project
   ├─ window  1: edit             like a browser tab (full screen)
   │  ├─ pane  nvim               a split within the window
   │  └─ pane  a shell
   └─ window  2: logs
```

**The prefix.** tmux commands start with a **prefix key** you press first, then let
go, then press the command key. Here the prefix is **`Ctrl-b`** (the default). So
"`prefix |`" means: press `Ctrl-b`, release, press `|`.

| Key | Does |
| --- | ---- |
| `prefix` `f` | **sessionizer** — fuzzy-pick a project folder → jump to its session |
| `prefix` `\|` / `-` | split the pane **vertically / horizontally** (keeps the folder) |
| `prefix` `h` `j` `k` `l` | move between panes (vim directions) |
| `Alt` + arrow keys | move between panes **without** the prefix |
| `prefix` `H` `J` `K` `L` | resize the current pane (hold to repeat) |
| `prefix` `c` · `prefix` `n`/`p` | new window · next / previous window |
| `prefix` `d` | **detach** (leave it all running; re-attach later with `tmux attach`) |
| `prefix` `[` then `v` / `y` | enter copy-mode, select, copy to the system clipboard |
| `prefix` `r` | reload the tmux config |

> [!TIP]
> **`prefix f` is the killer feature.** One key gives you *one tmux session per
> project*: fuzzy-pick a folder and you're dropped into a session for it (created if
> needed). It searches `~/code ~/projects ~/src ~/work ~/dev` by default — change that
> with `export TMUX_SESSIONIZER_PATHS="$HOME/code $HOME/work"` in `~/.zshrc.local`. The
> script ([`scripts/tmux-sessionizer.sh`](scripts/tmux-sessionizer.sh)) is also on your
> `PATH`, so `tmux-sessionizer` works from any shell.

<!-- -->

> [!IMPORTANT]
> **Sessions survive reboots.** Via [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
>
> - [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum), layouts auto-save
> every 15 min and restore on start (`prefix Ctrl-s` / `prefix Ctrl-r` to do it by
> hand). Pane *contents* are deliberately **not** saved, so scrollback secrets never
> hit disk.

---

### 🔌 SSH tunnels (port forwarding)

`ssh` does more than give you a remote shell — it can **tunnel network traffic**
through the same encrypted connection, letting you reach a service that's otherwise
unreachable (a database bound to a server's localhost, a UI behind a firewall, a port
inside a container). `console` ships three one-word helpers so you never hand-type the
flags:

```text
fwd    (local   -L)  →  pull a remote service to your machine
rfwd   (remote  -R)  →  expose one of your local services on the remote host
socks  (dynamic -D)  →  a SOCKS5 proxy through a host (a mini-VPN for your browser)
```

| Helper | What it does | Example |
| ------ | ------------ | ------- |
| `fwd <host> <port>` | your `localhost:<port>` → the host's `localhost:<port>` | `fwd db01 5432` — reach Postgres on `db01` at your own `localhost:5432` |
| `fwd <host> <lport> <rport>` | same, but a different **local** port | `fwd db01 15432 5432` |
| `fwd <host> <lport> <rhost> <rport>` | forward to a third host reachable **from** `<host>` | `fwd bastion 8080 10.0.0.9 80` |
| `rfwd <host> <rport> [lport]` | the host's `localhost:<rport>` → **your** `localhost:<lport>` | `rfwd server 9000 3000` — share your local dev server |
| `socks <host> [port]` | a SOCKS5 proxy on `localhost:<port>` (default 1080) | `socks jump` — point your browser at `localhost:1080` |

Each runs in the **foreground** with a keep-alive and prints what it's doing; press
**`Ctrl-C`** to close the tunnel. Want to keep using this shell? Open the tunnel in a
**tmux pane** (`prefix |`).

> [!TIP]
> **`<host>` can be a short name** from your `~/.ssh/config` (so `fwd db01 5432` "just
> works"). Keep machine-specific hosts **out of the repo**: add one line to the top of
> `~/.ssh/config` —
>
> ```text
> Include ~/.ssh/config.local
> ```
>
> — and put your `Host` entries in `~/.ssh/config.local` (`chmod 600`), which you
> never commit. Same idea as `~/.zshrc.local`.

---

### 🌿 git without the pain

**In one line:** [git](https://git-scm.com) records snapshots of your project so you
can review changes, undo mistakes, and share work. It's essential — and famously
fiddly on the command line. `console` softens all three sharp edges:

**1. Short aliases** for the commands you type constantly:

| Alias | Runs | Alias | Runs |
| ----- | ---- | ----- | ---- |
| `gs` | `git status -sb` | `gd` | `git diff` |
| `ga` | `git add` | `gco` · `gb` | checkout · branch |
| `gc` · `gca` | commit · commit -a | `gl` | pretty log (last 20) |
| `gp` · `gpl` | push · pull | `gla` | pretty log, all branches |

**2. Readable diffs.** [delta](https://github.com/dandavison/delta) reformats
`git diff` / `git show` into side-by-side, syntax-highlighted, line-numbered output.
It's wired in through a revertible `include` in your `~/.gitconfig` — your existing
git settings are never overwritten.

**3. A visual git app.** Run **`lg`** ([lazygit](https://github.com/jesseduffield/lazygit))
and get a full-screen UI: see your changes, stage individual lines, commit, branch,
and rebase — no flags to memorise. This is the gentlest on-ramp to git there is.

<details open>
<summary><b>lazygit keys</b> (press <code>?</code> inside for the full list)</summary>

<br>

| Key | Does | Key | Does |
| --- | ---- | --- | ---- |
| `Tab` `←` `→` | move between panels | `c` / `A` | commit / amend |
| `Space` | stage / unstage (or the panel's main action) | `p` / `P` / `f` | pull / push / fetch |
| `Enter` | stage individual lines / hunks | `n` `d` `M` `r` | branch: new · delete · merge · rebase |
| `?` | keybinding help | `s` / `x` / `q` | stash / menu / quit |

</details>

---

### ✍ Neovim: modal editing, gently

[Neovim](https://neovim.io) is a fast, modern text editor that lives in your terminal.
It's **modal**, which trips up newcomers but is the whole point once it clicks: instead
of holding modifier keys, you switch between **modes**.

- **Normal mode** (the default) — keys *move and manipulate* text. `h j k l` = left,
  down, up, right. This is where you spend most of your time.
- **Insert mode** — keys *type text*, like a normal editor. Enter it with **`i`**;
  leave it with **`Esc`**.
- **Visual mode** — *select* text. Enter with **`v`**.

The five commands that get you through anything:

| Do this | Keys |
| ------- | ---- |
| Start typing | `i` (then type; `Esc` to stop) |
| Save | `:w` Enter |
| Save & quit | `:wq` Enter *(or `ZZ`)* |
| **Quit without saving** | `:q!` Enter |
| Undo · redo | `u` · `Ctrl-r` |

> [!TIP]
> **Stuck and just want out?** Press `Esc`, then type `:q!` and Enter. That's the
> famous "how do I exit Vim". Now you'll never be trapped.

`console` ships **[LazyVim](https://www.lazyvim.org)** — Neovim pre-configured with
autocompletion, a file explorer, fuzzy finding, git signs, and language support, so
it's useful on day one. Its commands start with a **leader key** = **`Space`**. Tap
`Space` and pause: a **which-key** menu pops up showing every option. You can explore
the whole editor without memorising anything.

<details>
<summary><b>Essential LazyVim keys</b></summary>

<br>

| Key | Does | Key | Does |
| --- | ---- | --- | ---- |
| `<Space>` | which-key popup (discover everything) | `<Space>gg` | open lazygit |
| `<Space><Space>` | find files (fuzzy) | `<S-h>` / `<S-l>` | previous / next buffer |
| `<Space>/` | search text across the project | `gd` · `gr` · `K` | go to definition · references · hover docs |
| `<Space>e` | toggle the file explorer | `<Space>ca` · `<Space>cr` | code action · rename symbol |
| `<Space>,` | switch open buffers | `<Space>l` · `<Space>cm` | plugin manager · install tools |

Themed to match (**Catppuccin Mocha**), with language extras for **Docker ·
Terraform · YAML · JSON · Markdown · Python**. Plugin versions are pinned in
`nvim/lazy-lock.json`; add your own under [`nvim/lua/plugins/`](nvim/lua/plugins/) and
toggle built-ins with `:LazyExtras`.

</details>

> [!NOTE]
> `vi`, `vim`, and `v` all open Neovim here, and it's the default `$EDITOR` — so git
> commit messages and the like open in it too.

---

### 🤖 AI and passwords

Two optional, security-minded extras:

- **[fabric](https://github.com/danielmiessler/fabric)** runs AI "patterns" (reusable
  prompts) as ordinary commands you can pipe into. Set it up once with
  `fabric --setup`, keep your API key in `~/.zshrc.local` (never the repo), then:
  `cat notes.md | fsum` (summarise), `git diff | fexplain` (explain code),
  `ytsum <youtube-url>` (summarise a video). Skip it entirely with `--no-fabric`.
- **[pass](https://www.passwordstore.org)** is a password manager that encrypts each
  secret to **your own GPG key** — nothing ships with a key. Create one
  (`gpg --gen-key`), `pass init <key-id>`, then `pw`/`pwc` store & copy secrets and
  `passf` fuzzy-picks one to the clipboard. `GPG_TTY` is already set so it can prompt
  you in the terminal.

---

### 🖥️ Terminal (Alacritty + kitty)

Two matching terminal presets — both **Catppuccin Mocha** with **JetBrainsMono Nerd
Font** baked in, so the whole stack (terminal → prompt → tmux → editor) is one coherent
look and every glyph renders with zero setup:

- [`alacritty/alacritty.toml`](alacritty/alacritty.toml) — GPU-accelerated; **installed
  and linked** on desktops (`--no-alacritty` to skip).
- [`kitty/kitty.conf`](kitty/kitty.conf) — **linked** whether or not kitty is installed
  (`--no-kitty` to skip); install kitty yourself if you prefer it.

Both are intentionally minimal — **tmux** provides tabs, splits, and sessions. Skipped
on servers (`--server`). Using WezTerm or your OS terminal instead? Just point its font
at *JetBrainsMono Nerd Font*.

---

## 📓 Cheat sheet

The 90% you'll use daily. Print it, screenshot it, forget the rest.

<div align="center">

| Shell | | tmux (prefix `Ctrl-b`) | | git / editor | |
| --- | --- | --- | --- | --- | --- |
| `Ctrl-R` | search history | `prefix f` | project switcher | `gs` | git status |
| `Ctrl-T` | pick a file | `prefix \|` `-` | split panes | `gd` | git diff (pretty) |
| `Alt-C` | cd into a folder | `Alt`+arrows | move panes | `gl` | git log |
| `Tab` | fuzzy complete | `prefix d` | detach (keep alive) | `lg` | **lazygit** (visual git) |
| `→` | accept suggestion | `prefix c` | new window | `v` | Neovim (`:q!` to quit) |
| `z proj` | jump to a folder | `prefix [` | scroll / copy mode | `reload` | restart the shell |

</div>

<details>
<summary><b>Full alias reference</b> — files · git · DevOps · AI/secrets · handy</summary>

<br>

Tool-specific aliases only exist when the tool is installed.

### Files & search

| Alias | Command |
| ----- | ------- |
| `ls` `ll` `la` `lt` | eza: list · long+git · all · tree (2 levels) |
| `cat` | `bat --paging=never` (syntax-highlighted) |
| `fd` | `fdfind` on Debian/Ubuntu (also powers fzf) |
| `rgi` | `rg -i` (case-insensitive ripgrep) |

**Git** (`lg` → lazygit)

| Alias | Command | Alias | Command |
| ----- | ------- | ----- | ------- |
| `g` | `git` | `gd` | `git diff` |
| `gs` | `git status -sb` | `gco` `gb` | checkout · branch |
| `ga` | `git add` | `gl` | pretty log (last 20) |
| `gc` `gca` | commit · commit -a | `gla` | pretty log, all branches |
| `gp` `gpl` | push · pull | | |

**DevOps / sysadmin** *(only if the tool is present)*

| Alias | Command | Alias | Command |
| ----- | ------- | ----- | ------- |
| `k` | `kubectl` | `d` `dps` `dc` | docker · ps · compose |
| `kg` `kd` | get · describe | `tf` | terraform |
| `klo` | `logs -f` | `ap` | ansible-playbook |
| `kx` | switch cluster | `t` `ta` `tls` | tmux · attach · list |
| `kns` | switch namespace | `sc` `scu` | systemctl · --user |
| | | `jc` `jcu` | journalctl · --user |

**AI & secrets** *(only if the tool is present)*

| Alias | Command |
| ----- | ------- |
| `pw` `pwc` | `pass` · `pass -c` (copy a secret to the clipboard) |
| `passf` | fuzzy-pick a `pass` entry and copy it |
| `fab` | `fabric` — run an AI pattern |
| `fsum` `fexplain` | `fabric --pattern summarize` · `explain_code` (pipe in) |
| `ytsum <url>` | summarise a YouTube video's transcript |

### Navigation & handy

| Alias | Command |
| ----- | ------- |
| `..` `...` `....` | up 1 / 2 / 3 folders |
| `path` | print `$PATH`, one entry per line |
| `reload` | `exec zsh` (restart the shell) |
| `zshrc` | edit `~/.zshrc` |
| `please` | re-run the last command with `sudo` |
| `myip` | your public IP |
| `ports` | listening ports (`ss` Linux / `lsof` macOS) |
| `nas-sync [-n]` | rsync backups + `pass` store → your NAS (set `NAS_DEST`; [details](#ship-backups-to-a-nas)) |

**SSH tunnels** *(see [SSH tunnels](#-ssh-tunnels-port-forwarding))*

| Alias | Command |
| ----- | ------- |
| `fwd <host> <port>` | local forward — reach a remote service at your `localhost` |
| `rfwd <host> <rport> [lport]` | remote forward — expose your local service on the host |
| `socks <host> [port]` | dynamic forward — a SOCKS5 proxy through the host |

</details>

---

## ⚙️ Make it yours

- **Per-machine settings** — secrets, a work `PATH`, host-specific aliases → put them
  in **`~/.zshrc.local`**. It's sourced last, only if you own it, and is git-ignored,
  so it never leaves the machine. Start from
  [`zsh/zshrc.local.example`](zsh/zshrc.local.example).
- **The prompt** — [`starship/starship.toml`](starship/starship.toml) (colours, which
  segments show, per-host accents).
- **Aliases & shell options** — [`zsh/aliases.zsh`](zsh/aliases.zsh) and
  [`zsh/.zshrc`](zsh/.zshrc). Because of the symlink model, editing these here changes
  your live shell after `exec zsh`.
- **The editor** — drop plugins in [`nvim/lua/plugins/`](nvim/lua/plugins/).

> [!NOTE]
> Rule of thumb: **anything secret or specific to one machine goes in
> `~/.zshrc.local`; anything you want on every machine goes in the repo.**

---

## 🧯 Safety net (preview, inspect, back up, restore)

`console` assumes you'll want to undo things, and makes that easy.

| Want to… | Do |
| -------- | -- |
| **See what a run would change** | `./install.sh --dry-run` — prints everything, changes nothing |
| **Check an existing setup** | `./install.sh --doctor` — tools, symlinks, font, git config |
| **Undo the install** | `./uninstall.sh` — removes only symlinks into this repo + the git-delta include |
| **Get your old configs back** | restore from the dated backup (below) |

### The pre-change backup

Before a **real** run touches anything, the installer snapshots every config it might
replace — plus `~/.gitconfig` and `~/.zshenv` — into **one dated folder**:

```text
~/backup/zsh/<timestamp>/
```

(`--dry-run` and `--doctor` never back up, because they change nothing.)

**Restoring — one file:** remove the console symlink first (so you don't write
*through* it), then copy your original back.

```bash
b=$(ls -1dt ~/backup/zsh/*/ | head -1)   # newest backup
ls -la "$b"                                                 # see what's saved
rm -f ~/.zshrc && cp -a "$b/.zshrc" ~/.zshrc               # restore just this one
exec zsh
```

**Restoring — everything:** uninstall first (that removes all the symlinks), then copy
the whole backup back over the now-empty paths.

```bash
./uninstall.sh
cp -a "$b/." ~/
exec zsh
```

> [!WARNING]
> Only copy a backup **after** the symlinks are gone (`rm` the single file, or run
> `./uninstall.sh`). Copying onto a live symlink would overwrite the repo file it
> points at.

<!-- -->

> [!NOTE]
> The backup includes `~/.gitconfig` and `~/.zshenv` (the files the installer
> *edits*). Restoring `.gitconfig` removes the delta include; or undo just that with
> `git config --global --unset-all include.path '<repo>/git/delta.gitconfig'`. Every
> run also appends an audit trail to `~/.local/state/console/install-<ts>.log`.

### Ship backups to a NAS

`nas-sync` rsyncs your backup folder (and your `pass` store, if present) to a NAS or
any rsync target — **additive**, it never deletes on the destination. Point it at a
destination once in `~/.zshrc.local`:

```bash
# A Synology NAS usually speaks SMB/CIFS only — mount the share, then sync to the mount:
sudo mount -t cifs //NAS-IP/SHARE /mnt/nas -o credentials=$HOME/.nas-cred,uid=$(id -u),gid=$(id -g),vers=3.0
export NAS_DEST="/mnt/nas/backups/$(hostname)"
# ...or an ssh target if your NAS allows it:  export NAS_DEST="user@NAS-IP:/volume1/backups"
```

```bash
nas-sync         # sync ~/backup (+ ~/.password-store) → NAS_DEST
nas-sync -n      # preview only (rsync --dry-run)
```

> [!TIP]
> Schedule it from cron, and/or override the sources:
> `NAS_SYNC_PATHS="$HOME/backup $HOME/notes" nas-sync`. Your `pass` store is
> GPG-encrypted, so it's safe to keep on the NAS.

---

## 🔄 Updating

Because your configs are symlinks into this repo, updating is a `git pull`:

```bash
cd ~/code/console && git pull && exec zsh   # add ./install.sh if a new tool was added
```

| Update | Command |
| ------ | ------- |
| zsh plugins | `zinit self-update && zinit update --all` |
| LazyVim plugins | open `nvim` → `:Lazy update` (then commit `nvim/lazy-lock.json`) |
| CLI tools | your package manager (`apt upgrade`, `brew upgrade`, …) |
| tldr pages | `tldr --update` |

---

## 🔒 Security & production

Built to run on servers and privileged boxes — full details in
[`SECURITY.md`](SECURITY.md).

<details>
<summary><b>The security model in one screen</b></summary>

<br>

| Concern | How it's handled |
| ------- | ---------------- |
| **Wrong box / cluster** | prompt shows `user@host` (SSH, root in red) + kube/AWS context |
| **Secrets in history** | leading-space commands aren't saved (`HIST_IGNORE_SPACE`) |
| **Secrets in the repo** | machine config lives in git-ignored `~/.zshrc.local` |
| **Completion injection** | `compinit -i` keeps the security check, skips insecure dirs (never `-C`) |
| **Supply chain** | packages first; `curl \| sh` only a labelled fallback; lazygit/neovim/carapace/fabric binaries **SHA256-verified** |
| **Reproducibility** | `nvim/lazy-lock.json`, `ZINIT_PIN`, `--offline`, `scripts/vendor-plugins.sh` |
| **Auditability** | every run logs to `~/.local/state/console/install-<ts>.log` |
| **Reversibility** | one dated pre-change backup + `./uninstall.sh` |
| **External key agents** | point `SSH_AUTH_SOCK` at 1Password / Vault from `~/.zshrc.local` |
| **AI / password secrets** | `pass` uses **your** GPG key; `fabric` keys live in `~/.zshrc.local` |

</details>

> [!CAUTION]
> On air-gapped hosts, `./install.sh --offline` skips every fetch — pre-seed the
> plugins with [`scripts/vendor-plugins.sh`](scripts/vendor-plugins.sh) first.

---

## 🗂️ Repo layout

```text
.
├── install.sh              # idempotent bootstrap (Linux + macOS) — also --dry-run / --doctor
├── uninstall.sh            # reverse the symlinks + git include
├── zsh/
│   ├── .zshrc              # main shell config      ->  ~/.zshrc
│   ├── aliases.zsh         # aliases (sourced by .zshrc)
│   └── zshrc.local.example # template for ~/.zshrc.local
├── starship/starship.toml  # the prompt             ->  ~/.config/starship.toml
├── nvim/                   # LazyVim config          ->  ~/.config/nvim
├── lazygit/config.yml      # lazygit (uses delta)    ->  ~/.config/lazygit/config.yml
├── tmux/tmux.conf          # tmux config             ->  ~/.config/tmux/tmux.conf
├── alacritty/alacritty.toml # terminal preset        ->  ~/.config/alacritty/alacritty.toml
├── kitty/kitty.conf        # terminal preset         ->  ~/.config/kitty/kitty.conf
├── git/delta.gitconfig     # git-delta, included into ~/.gitconfig
├── scripts/
│   ├── tmux-sessionizer.sh # fzf project switcher    ->  ~/.local/bin/tmux-sessionizer
│   ├── vendor-plugins.sh   # pre-seed plugins for offline hosts
│   └── ci-*.sh             # CI: assert installs + uninstall reversibility
├── .github/workflows/ci.yml    # shellcheck + multi-distro install/uninstall smoke tests
├── CLAUDE.md · SECURITY.md · ROADMAP.md
└── README.md
```

---

<div align="center">

**Built to be cloned.** &nbsp;·&nbsp; New here? Re-read the
**[mental model](#-never-used-a-terminal-like-this-2-minute-mental-model)**.
&nbsp;·&nbsp; What's next? See [`ROADMAP.md`](ROADMAP.md).

</div>
