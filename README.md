# Dotfiles

Personal dotfiles managed with GNU Stow.

## Layout

- `home/`: files stowed into `$HOME`
- `packages/bundle`: Homebrew bundle for tools this config expects
- `dot`: helper for setup, Oh My Zsh bootstrap, restow, and basic checks
- `home/.zshenv`: minimal PATH and environment shared across zsh contexts

## Bootstrap

This setup targets Apple Silicon macOS (`/opt/homebrew`). Before running init, install [Homebrew](https://brew.sh/) and compiler tools with `xcode-select --install`.

```bash
git clone <your-repo-url> ~/Code/dotfiles
cd ~/Code/dotfiles
./dot init
```

`./dot init` installs the Homebrew bundle, Bun, OpenCode 2, clones `~/.oh-my-zsh` when missing, and stows `home/` into `$HOME`. Install Codex CLI and Claude Code separately.

Ghostty, the configured font, and tmux's plugin manager are separate prerequisites:

```bash
brew install --cask ghostty font-jetbrains-mono-nerd-font
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Skip the clone if TPM is already installed. Start tmux and press `Ctrl+Space`, then `Shift+I` to install the configured plugins. Run `./dot doctor` afterwards to check core commands, config paths, and Stow conflicts. It does not check versions, fonts, or tmux plugins.

## OpenCode

OpenCode 2 runs as `opencode` from `~/.opencode/bin`; `oc` is the shell alias. `opencode2` is a legacy compatibility wrapper. It uses its built-in managed background service:

```bash
opencode service status
opencode api get /api/info
opencode pair
```

The service listens on localhost by default. For remote access on a trusted network, run `opencode service set hostname 0.0.0.0`, then use `opencode pair` to authenticate remote clients.

## Shared agent setup

OpenCode, Codex, and Claude Code share instructions from `home/.agents/AGENTS.md`, linked into each tool's global instruction path. Edit that source file to change the common guidance. Skills live in `home/.agents/skills/`: Codex discovers `~/.agents/skills` directly, and Claude Code's `~/.claude/skills` links there. Cloud-synced skills under `skills/synced/` are local runtime content and ignored by git.

| Tool | Launch | Managed settings |
| --- | --- | --- |
| OpenCode | `oc` | `home/.config/opencode/opencode.json`, `cli.json` |
| Codex CLI | `cx` | `home/.codex/dotfiles.config.toml` |
| Claude Code | `cc` or `claude` | `home/.claude/settings.json`, `statusline-command.sh` |

`cx` runs `codex --profile dotfiles --add-dir "$HOME/Code/agent-vault"`. The profile requires Codex 0.134.0+ and overlays portable preferences on your existing `~/.codex/config.toml`, with a 1,050,000-token context window matching OpenCode. Plain `codex` and the desktop app keep using their local settings; all launches receive the shared global instructions and skills. Change the profile's model if it is unavailable on your account.

The shared vault is expected at `~/Code/agent-vault/`. Claude Code includes it through `permissions.additionalDirectories`; Codex's `cx` shortcut adds it as a writable directory. Launch plain `codex --profile dotfiles` if the vault is not installed.

`./dot stow` creates real `~/.codex` and `~/.claude` directories before linking individual managed files, so session history and credentials stay local. On an existing machine, Stow reports conflicting files instead of overwriting them: back up and reconcile your settings before replacing them with the managed versions. Authentication, Codex's base config, and `~/.claude.json` stay outside git.

### MCP

OpenCode uses its direct servers from `opencode.json`. Codex and Claude Code use `my_codemode`, with registrations stored in their local configuration.

Configure MCP registrations manually. Backend credentials and OAuth sign-in are managed by `my-codemode` separately. Sign in to Codex and Claude Code interactively on a new machine.

## Themes

Tokyo Night, Rose Pine, and Catppuccin Macchiato are available through a shared terminal-native theme setup. Ghostty, Neovim, Yazi syntax, and OpenCode load theme-specific files through `~/.config/current-theme`; tmux, Starship, lazygit, btop, tmux-palette, and the Yazi interface use the terminal ANSI palette.

```bash
./dot theme tokyo-night
./dot theme rose-pine
./dot theme catppuccin
```

After switching, reload Ghostty with `Cmd+Shift+,` and restart open Neovim, Yazi, and OpenCode sessions.

Theme switching checks OpenCode JSON before changing the active theme. `./dot init` and `./dot stow` regenerate missing OpenCode theme files without changing the selected theme.

Each theme's `opencode.json` is the source for code colors. Neovim reads its dark-mode syntax tokens and applies them to Vim, Tree-sitter, and LSP highlights after the colorscheme loads. Yazi's syntax previews are generated from the same tokens. The editor presets use dark variants: Rosé Pine main, Tokyo Night night, and Catppuccin Macchiato.

OpenCode's main background is transparent so Ghostty applies window opacity once. Yazi's preview background uses the concrete `hue.neutral.800` palette color.

After changing tokens, regenerate Yazi previews and verify the Neovim mappings:

```bash
nvim --headless -u NONE -l scripts/sync-theme-syntax.lua
nvim --headless -u NONE -l scripts/sync-theme-syntax.lua --check
nvim --headless -u NONE -l tests/theme-syntax.lua
```

## Neovim

The Neovim configuration requires Neovim 0.12 or newer. Treesitter parser installation requires tree-sitter CLI 0.26.1 or newer (included in the Homebrew bundle), a C compiler, `tar`, and `curl`. On macOS, install the compiler with `xcode-select --install` if needed. Run `./dot doctor` to check command availability. Configured formatters include Prettier, Prettierd, Stylua, and Zigfmt.

Oil handles directory editing, while Neo-tree provides a persistent project tree. FFF provides indexed project file and content search; its native binary is downloaded during plugin installation and can fall back to a local Rust toolchain. Snacks provides buffers, help, recent files, LSP and TODO pickers alongside its dashboard, notification, Git, scratch, and toggle features.

Oil uses its native LSP file-operation support to update references when files are renamed. Any buffers changed by those edits must be saved separately. `<leader>e` toggles Neo-tree and reveals the current file when opening it.

Oxfmt and `tsgo` are optional project-local tools. When present, Oxfmt takes priority over Prettier for supported files, and `tsc.nvim` finds `node_modules/.bin/tsgo` automatically.

`home/.vimrc` is a plugin-free keybinding starter for minimal Vim or Neovim installations. Neovim does not load it automatically; source it from an `init.vim` or copy the mappings when bootstrapping a separate setup.

### CSS Modules

CSS Modules Kit runs through `ts_ls` for completion, navigation, references, and cross-file rename in TypeScript/JavaScript and `.module.css` files. Install its TypeScript plugin for the Node version used by Neovim:

```bash
npm install -g @css-modules-kit/ts-plugin
```

The configuration resolves its location using `npm root -g`. When switching Node versions with fnm, install the plugin in that version too.

Enable CSS Modules Kit in each project's `tsconfig.json`:

```json
{
  "cmkOptions": {
    "enabled": true
  }
}
```

Ensure the project's `include` patterns cover `.module.css` files (for example, `"src/**/*"`, rather than only `"src/**/*.ts"`). Restart Neovim after setup. Use `:LspBuf` in a `.tsx` file and its `.module.css` file to confirm `ts_ls` is attached; `cssls` also provides normal CSS support.

For matching command-line type checking with `tsc` or `tsgo`, set up the separate code generator following the [upstream guide](https://github.com/mizdra/css-modules-kit/blob/main/docs/get-started.md).

## Commands

```bash
./dot init
./dot stow
./dot theme tokyo-night
./dot doctor
```
