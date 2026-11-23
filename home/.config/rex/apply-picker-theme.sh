#!/usr/bin/env bash
# Internal operations for the Rex picker. All scratch files belong to one popup.
set -euo pipefail
export PATH="${HOME}/.opencode/bin:${HOME}/.local/bin:${HOME}/.bun/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:${PATH}"
# The picker passes its sibling's resolved path, even when launched via Stow.
source "$(dirname "$0")/../../../lib/theme.sh"

stage="$2"
themes="${HOME}/.config/themes"
oc="${XDG_CONFIG_HOME:-${HOME}/.config}/opencode"
lg="${HOME}/.config/lazygit/config.yml"
name="${3:-}"
dir="$themes/$name"
case "$1" in
  prepare)
    prepare_theme_session "$stage" "$themes" "$oc"
    apply_pi_theme "$dir"
    ;;
  preview)
    ensure_rex_palette "$dir" "$stage"
    stage_live_selection "$dir" "$oc/cli.json" "$stage"
    activate_live_theme "$dir" "$oc/cli.json" "$stage"
    ;;
  commit)
    # The live apps already show the choice. Only flush the deferred settings.
    if [[ -f "$dir/lazygit.yml" ]]; then
      stage_lazygit_selection "$dir/lazygit.yml" "$lg" "$stage/lazygit.yml"
      cat "$stage/lazygit.yml" > "$lg"
    fi
    refresh_theme_tools
    ;;
  *) printf 'error: unknown picker operation: %s\n' "$1" >&2; exit 1 ;;
esac
