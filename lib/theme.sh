# Shared Bash operations. Callers own PATH, shell options and their stage directory.

rex_theme_names() {
  defaults export com.superlogical.rex - 2>/dev/null \
    | plutil -extract 'Workspace\.customThemes' raw -o - - 2>/dev/null \
    | base64 -D 2>/dev/null | jq -r '.[].name'
}

rex_theme_clients() {
  command -v defaults >/dev/null 2>&1 || return 0
  command -v rex >/dev/null 2>&1 || return 0

  rex --autostart=false client ls --json 2>/dev/null \
    | jq -r '.clients[] | select(.info.kind == "app" and .principal.transport == "unix") | .client_id'
}

ensure_rex_palette() {
  local dir="$1" stage="$2" name clients
  [[ -s "$dir/rex.theme" && -s "$stage/clients" ]] || return 0
  name="$(<"$dir/rex.theme")"
  if [[ -f "$dir/rex/$name" ]] && ! grep -Fxq -- "$name" "$stage/palettes"; then
    clients="$(<"$stage/clients")"
    rex --autostart=false -C "${clients%%$'\n'*}" do client.theme.import "path=$dir/rex/$name" >/dev/null || return 1
    printf '%s\n' "$name" >> "$stage/palettes"
  fi
}

apply_rex_theme() {
  local rex_name="$1"
  local client_list="$2"
  local client

  while IFS= read -r client; do
    [[ -n "$client" ]] || continue
    if rex --autostart=false -C "$client" do client.theme.change "name=${rex_name}" >/dev/null 2>&1; then
      printf 'rex: %s\n' "$rex_name"
    else
      printf '%s\n' "rex: could not change theme (enable Remote Control in Rex Settings > General)"
    fi
  done <<<"$client_list"
}

opencode_theme_name() {
  if [[ "$1" == opencode ]]; then
    printf 'opencode\n'
  else
    printf 'dotfiles-%s\n' "$1"
  fi
}

install_opencode_themes() {
  local themes_dir="$1"
  local output_dir="$2"
  local source preset target

  mkdir -p "$output_dir"
  for source in "$themes_dir"/*/opencode.json; do
    [[ -f "$source" ]] || continue
    preset="${source%/*}"
    preset="${preset##*/}"
    # The default's JSON is a token source for other apps, not a custom TUI theme.
    [[ "$preset" != opencode ]] || continue
    target="${output_dir}/dotfiles-${preset}.json"
    if ! cmp -s "$source" "$target"; then
      cp "$source" "$target"
    fi
  done
}

prepare_theme_session() {
  local stage="$1" themes="$2" opencode_dir="$3"
  install_opencode_themes "$themes" "$opencode_dir/themes"
  # A popup can preview many presets. Discover clients and palettes once.
  rex_theme_clients > "$stage/clients" || : > "$stage/clients"
  if [[ -s "$stage/clients" ]]; then
    rex_theme_names > "$stage/palettes" || : > "$stage/palettes"
  fi
}

stage_live_selection() {
  local dir="$1" cli="$2" stage="$3"
  # Cancel restores the original preset, not a stale copy of the user's other settings.
  if [[ -f "$cli" ]]; then
    cat "$cli"
  else
    printf '%s\n' '{}'
  fi | jq -es --arg name "$(opencode_theme_name "${dir##*/}")" '
    if length == 1 and (.[0] | type == "object")
    then .[0] | .theme.name = $name | .theme.mode //= "system"
    else error("expected one OpenCode CLI config object")
    end' > "$stage/cli.json" || return 1
  ln -nsf "$dir" "$stage/next"
}

stage_lazygit_selection() {
  local theme="$1" config="$2" output="$3"
  if [[ ! -f "$config" ]]; then
    printf 'error: missing lazygit config: %s\n' "$config" >&2
    return 1
  fi
  if ! yq -e 'type == "!!map"' "$theme" >/dev/null; then
    printf 'error: invalid lazygit theme YAML: %s\n' "$theme" >&2
    return 1
  fi
  THEME_FILE="$theme" yq '.gui.theme = load(strenv(THEME_FILE))' "$config" > "$output"
}

activate_live_theme() {
  local dir="$1" cli="$2" stage="$3" rex_pid=""
  if [[ -s "$dir/rex.theme" && -s "$stage/clients" ]]; then
    apply_rex_theme "$(<"$dir/rex.theme")" "$(<"$stage/clients")" &
    rex_pid=$!
    # Measured RPC head start: waiting for Rex's reply makes the panes stagger.
    sleep 0.020
  fi
  # Replace the selection atomically for Neovim's watcher. Write through
  # cli.json instead of replacing it so OpenCode's Stow symlink survives.
  /bin/mv -fh "$stage/next" "${HOME}/.config/current-theme"
  cat "$stage/cli.json" > "$cli"
  chmod 600 "$cli"
  if [[ -n "$rex_pid" ]]; then
    wait "$rex_pid"
  fi
}

refresh_theme_tools() {
  if [[ -d "${HOME}/.config/tmux-palette" ]]; then
    printf '%s\n' '{' '  "name": "terminal"' '}' > "${HOME}/.config/tmux-palette/theme.json"
  fi
  if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "${HOME}/.config/tmux/tmux.conf"
  fi
  if pgrep -x btop >/dev/null 2>&1; then
    pkill -SIGUSR2 btop
  fi
}
