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
| Codex CLI / desktop | `codex` or `cx` | `home/.codex/config.toml`, `dotfiles.config.toml` |
| Claude Code | `cc` or `claude` | `home/.claude/settings.json`, `statusline-command.sh` |

Codex's portable `~/.codex/config.toml` and Claude Code's `~/.claude/settings.json` are managed directly by Stow. Codex project trust, authentication, plugin marketplace caches, and app-installed MCP integrations are machine/runtime state and are not tracked. Edit the managed config in `home/`; no config-patching step is required.

`cx` runs `codex --profile dotfiles --add-dir "$HOME/Code/agent-vault"`. The optional profile requires Codex 0.134.0+ and overlays preferences on the managed base config, with a 1,050,000-token context window matching OpenCode. Plain `codex` and the desktop app use the managed base config. All launches receive the shared global instructions and skills.

The shared vault is expected at `~/Code/agent-vault/`. Claude Code includes it through `permissions.additionalDirectories`; Codex's `cx` shortcut adds it as a writable directory. Launch plain `codex --profile dotfiles` if the vault is not installed.

`./dot stow` creates real `~/.codex`, `~/.claude`, `~/.local/bin`, and `~/.config/codemode-mcp-gateway` directories before linking individual managed files, so session history, installed packages, and credentials stay local. On an existing machine, Stow reports conflicting files instead of overwriting them: back up and reconcile your settings before replacing them with the managed versions. Authentication stays outside git. Claude's mixed `~/.claude.json` file also stays local because it contains account metadata, project state, MCP registrations, and caches.

### MCP

OpenCode keeps its direct servers from `opencode.json` unchanged. Codex and Claude Code launch **codemode-mcp-gateway**, whose CLI is **`gw`**, over stdio. Each client owns its own gateway process; there is no shared HTTP daemon.

```bash
./dot stow
```

Install Bun 1.4.3, then run `bun run install:local` in `~/Code/personal/mcm` (the codemode-mcp-gateway repository). This builds and verifies private local tarballs, installs them under `~/.local/share/codemode-mcp-gateway/installs/`, and activates a `current` symlink. It does not publish packages or run from the source checkout. Builds are explicit; script-disable policy is preserved. Re-run the command for an explicit local update; earlier installs remain available for rollback.

Codex's MCP registration is managed in `config.toml`. Claude's user-scoped registration lives in local `~/.claude.json`; on a new machine register the launcher once:

```bash
claude mcp add --scope user --transport stdio codemode-mcp-gateway -- \
  /bin/sh -c 'exec "$HOME/.local/bin/gw"'
```

Managed files:

- `home/.local/bin/gw`: portable Bun launcher for the installed CLI.
- `home/.config/codemode-mcp-gateway/config.json`: New Relic, Metabase, Notion, and Jira upstreams.

There is **no gateway tool allowlist**. New Relic and Metabase retain their requested read/query OAuth scopes; provider-side grants govern actual permissions. Notion uses its consent flow. The `jira` connection uses Atlassian MCP and may advertise other Atlassian tools too. GitHub is not configured. Never put credentials in the tracked JSON.

#### Explicit provider login

Sign in sequentially, then check connections. These commands open an explicit browser authorization flow; MCP serving never prompts for login:

```bash
gw check --json
gw login --server newrelic
gw login --server metabase
gw login --server notion
gw login --server jira
gw doctor --json
```

The new gateway stores credentials in the OS secret store. Old My CodeMode credentials, Keychain entries, and source repository are not deleted or silently migrated. Missing authorization leaves that upstream in `needs-auth`; the stdio gateway stays available and other authorized upstreams remain usable. Restart Codex/Claude after changing their MCP registration; existing gateway processes adopt new authorization automatically.

Edit the managed gateway JSON here and restow it; commands that atomically replace it can replace its Stow symlink. Config edits require restarting the client-owned gateway. Codex may update its config at runtime, so review changes before committing. Sign in to Codex and Claude Code interactively on a new machine.

## Themes

Tokyo Night, Rose Pine, Catppuccin Macchiato, and Gruvbox are available through a shared terminal-native theme setup. Ghostty, Neovim, Yazi syntax, OpenCode, and lazygit load theme-specific files through `~/.config/current-theme`; tmux, Starship, btop, tmux-palette, and the Yazi interface use the terminal ANSI palette.

```bash
./dot theme tokyo-night
./dot theme rose-pine
./dot theme catppuccin
./dot theme gruvbox
```

After switching, reload Ghostty with `Cmd+Shift+,` and restart open Neovim, Yazi, and OpenCode sessions.

Theme switching checks OpenCode JSON before changing the active theme. `./dot init` and `./dot stow` regenerate missing OpenCode theme files without changing the selected theme. Switching also rewrites the `gui.theme` block in `~/.config/lazygit/config.yml` from the selected theme's `lazygit.yml`, writing through Stow's symlink; that block tracks the active theme, so review its diff before committing.

Each theme's `opencode.json` is the source for code colors. Neovim reads its dark-mode syntax tokens and applies them to Vim, Tree-sitter, and LSP highlights after the colorscheme loads. Yazi's syntax previews are generated from the same tokens. The editor presets use dark variants: Rosé Pine main, Tokyo Night night, Catppuccin Macchiato, and Gruvbox dark (medium background). Gruvbox colors follow the theme bundled with OpenCode itself.

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

TypeScript LSP selection uses the nearest workspace installation: `effect_tsgo` for `@effect/tsgo`, native `tsc` for TypeScript 7+, and `ts_ls` otherwise. Native servers use project dependencies rather than Mason. Add a `.ts_ls` file at the project root to force `ts_ls` (for example, for CSS Modules Kit); with TypeScript 7 this uses the language server's bundled older TypeScript. Restart Neovim after changing dependencies or the override, and use `:LspBuf` to check the selected client.

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
