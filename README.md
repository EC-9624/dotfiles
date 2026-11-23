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

Themes: `tokyo-night`, `rose-pine`, `catppuccin`, `gruvbox`, `opencode`. The `opencode` preset selects the TUI's built-in default. Its dark tokens from the [official theme tool](https://opencode.ai/theme/) are stored in `home/.config/themes/opencode/opencode.json` for Neovim, lualine, and Yazi; no `dotfiles-opencode` theme is installed. Rex, Neovim, and OpenCode V2 switch live after one-time setup. Run `./dot theme <name>` to install the named OpenCode palettes, then reopen any OpenCode TUIs that were already running and start Neovim with the updated config. Subsequent switches are live. Use `:DotThemeReload` in Neovim to reapply the selected palette manually.

In Rex, press `Ctrl+Space`, then `Shift+T`, or choose **Switch shared theme** in the command palette. The active preset starts first. Move or type to preview the highlighted theme in Rex, Neovim, and OpenCode. `Enter` keeps it and updates the remaining tools; `Esc` or closing the popup restores the starting preset. Rex’s built-in **Change Theme…** only changes Rex.

Reopen Yazi for the new syntax preview colors and lazygit for its app-specific colors. If you still use Ghostty, reload it with `Cmd+Shift+,`. Theme switching updates tracked OpenCode and lazygit settings, so review the diff.

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
| Pi | `.pi/agent/settings.json`, `models.json`, `mcp.json`, `extensions/cache-footer.ts` |

**How theme switching works:** `dot` runs a full switch. In `home/.config/rex/`, `theme-picker.py` handles highlighting, accepting, and canceling; `apply-picker-theme.sh` prepares once per popup, previews live apps, and updates the remaining tools on commit. Both Bash entry points source `lib/theme.sh`, which owns palette import, config staging, and the timed live handoff.

`scripts/` holds the Yazi theme generator; `tests/` holds the Rex and theme tests.

`packages/bundle` lists Homebrew dependencies. Agents share skills from `home/.agents/skills/`.

Keep credentials, session history, and caches outside Git. Codex and Pi can update managed settings at runtime; review diffs before committing.
