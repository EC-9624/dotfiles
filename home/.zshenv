if [[ -r "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi

if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -d /usr/local/Homebrew || -x /usr/local/bin/brew ]]; then
  export HOMEBREW_PREFIX="/usr/local"
fi

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  typeset -U path PATH
  path=(
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/sbin"
    $path
  )
  export PATH
fi
