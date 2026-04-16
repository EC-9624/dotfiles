export EDITOR="nvim"
export VISUAL="nvim"

export HOMEBREW_PREFIX="/opt/homebrew"

export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"

typeset -U path PATH
path=(
  "$HOME/.opencode/bin"
  "$HOME/.local/bin"
  "$BUN_INSTALL/bin"
  "$HOMEBREW_PREFIX/bin"
  "$HOMEBREW_PREFIX/sbin"
  "$PNPM_HOME"
  "$HOME/.cargo/bin"
  $path
  "$HOME/go/bin"
)

export PATH
