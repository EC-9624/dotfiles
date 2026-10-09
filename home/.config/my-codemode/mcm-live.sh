#!/bin/sh
set -eu

bun="$HOME/.bun/bin/bun"
entrypoint="$HOME/Code/personal/my-codemode/bin/mcm.ts"
config="$HOME/.config/my-codemode/codex-live.json"

if [ ! -x "$bun" ] || [ ! -f "$entrypoint" ]; then
  printf '%s\n' 'My CodeMode requires Bun in ~/.bun/bin and a checkout at ~/Code/personal/my-codemode. See the dotfiles README.' >&2
  exit 1
fi

MCM_GITHUB_CLIENT_ID="Ov23lijrFXwA3lhQMXCy"
export MCM_GITHUB_CLIENT_ID

if ! MCM_GITHUB_CLIENT_SECRET="$(/usr/bin/security find-generic-password \
  -a EC-9624 \
  -s "my-codemode.github-oauth.$MCM_GITHUB_CLIENT_ID" \
  -w)"; then
  printf '%s\n' 'Cannot load My CodeMode GitHub OAuth client secret from macOS Keychain. Provision the client secret or unlock the login keychain, then retry.' >&2
  exit 1
fi
export MCM_GITHUB_CLIENT_SECRET

if [ "$#" -eq 0 ]; then
  set -- serve
fi

exec "$bun" run "$entrypoint" "$@" --config "$config"
