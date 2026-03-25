if [[ -r "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi

if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -d /usr/local/Homebrew || -x /usr/local/bin/brew ]]; then
  export HOMEBREW_PREFIX="/usr/local"
fi

export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"

typeset -U path PATH
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  path=(
    "$HOME/.opencode/bin"
    "$HOME/.local/bin"
    "$BUN_INSTALL/bin"
    "$PNPM_HOME"
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/sbin"
    $path
    "$HOME/go/bin"
  )
else
  path=(
    "$HOME/.opencode/bin"
    "$HOME/.local/bin"
    "$BUN_INSTALL/bin"
    "$PNPM_HOME"
    $path
    "$HOME/go/bin"
  )
fi
export PATH
