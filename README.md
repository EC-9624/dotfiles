# Dotfiles

Personal configuration for Apple Silicon macOS, managed with GNU Stow.

## Setup

Install [Homebrew](https://brew.sh/) and Xcode command-line tools (`xcode-select --install`), then:

```bash
git clone <your-repo-url> ~/Code/dotfiles
cd ~/Code/dotfiles
./dot init
brew install --cask ghostty font-jetbrains-mono-nerd-font
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
./dot doctor
```

Skip the TPM clone if already installed. In tmux, press `Ctrl+Space`, then `Shift+I` to install plugins.

`./dot init` installs the Homebrew bundle, Bun, OpenCode, and Oh My Zsh, then links `home/` into `$HOME`. Install Codex, Claude Code, [Pi](https://pi.dev/), and Rex separately. Back up and reconcile existing config files if Stow reports conflicts.

## Commands

| Command | Purpose |
| --- | --- |
| `./dot init` | Bootstrap this machine |
| `./dot stow` | Refresh config symlinks |
| `./dot doctor` | Check commands, config paths, and Stow conflicts |
| `./dot theme <name>` | Switch the shared theme |

## Configuration

Edit files under `home/`; Stow links them to the matching paths in `$HOME`.

| Tool | Config under `home/` |
| --- | --- |
| Shell | `.zshenv`, `.zprofile`, `.zshrc` |
| Ghostty | `.config/ghostty/config` |
| tmux | `.config/tmux/tmux.conf` |
| Rex | `.config/rex/` (`keys.lua`, `navigation.lua`, `popups.lua`, `floating.lua`) |
| Neovim | `.config/nvim/` |
| OpenCode (`oc`) | `.config/opencode/opencode.json`, `cli.json` |
| Codex | `.codex/config.toml` |
| Claude Code (`cc`) | `.claude/settings.json` |
| Pi | `.pi/agent/settings.json`, `models.json`, `mcp.json` |

`scripts/` holds the Yazi theme generator; `tests/` holds the Rex and theme tests.

`packages/bundle` lists Homebrew dependencies. Agents share skills from `home/.agents/skills/`.

Keep credentials, session history, and caches outside Git. Codex and Pi can update managed settings at runtime; review diffs before committing.
