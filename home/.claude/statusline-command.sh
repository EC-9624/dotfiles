#!/usr/bin/env zsh
# Claude Code status line — mirrors Starship Rose Pine prompt layout

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')

# Rose Pine palette (ANSI 24-bit)
foam="\033[38;2;156;207;216m"       # directory
gold="\033[38;2;246;193;119m"       # git branch text
surface_bg="\033[48;2;31;29;46m"    # git branch bg
subtle="\033[38;2;144;140;170m"     # git remote symbol / counts
rose="\033[38;2;235;188;186m"       # modified
foam_fg="\033[38;2;156;207;216m"    # staged
love="\033[38;2;235;111;146m"       # deleted / conflicted
pine="\033[38;2;49;116;143m"        # renamed
iris="\033[38;2;196;167;231m"       # model / context
muted="\033[38;2;110;106;134m"      # dim info
reset="\033[0m"
bold="\033[1m"

# --- directory ---
dir_display="${cwd/#$HOME/~}"
printf "${foam}[ %s ]${reset}" "$dir_display"

# --- git info (run from cwd) ---
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # remote symbol
  git_remote=$(git -C "$cwd" ls-remote --get-url 2>/dev/null)
  if [[ "$git_remote" =~ "github" ]]; then
    remote_sym=" "
  elif [[ "$git_remote" =~ "gitlab" ]]; then
    remote_sym=" "
  elif [[ "$git_remote" =~ "bitbucket" ]]; then
    remote_sym=" "
  elif [[ "$git_remote" =~ "git" ]]; then
    remote_sym=" "
  else
    remote_sym=" "
  fi
  printf "${subtle}%s${reset}" "$remote_sym"

  # branch
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  printf "${surface_bg} ${reset}${surface_bg}${gold} %s${reset}${surface_bg} ${reset}" "$branch"

  # worktree indicator
  common_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  git_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null)
  if [ -n "$common_dir" ] && [ "$common_dir" != "$git_dir" ]; then
    printf " ${bold}⛓${reset}"
  fi

  # git status counts
  staged=0; modified=0; deleted=0; untracked=0; renamed=0
  while IFS= read -r line; do
    x="${line:0:1}"; y="${line:1:1}"
    [[ "$x" == "?" && "$y" == "?" ]] && (( untracked++ )) && continue
    [[ "$x" =~ [MARC] ]] && (( staged++ ))
    [[ "$y" == "M" ]] && (( modified++ ))
    [[ "$y" == "D" || "$x" == "D" ]] && (( deleted++ ))
    [[ "$x" == "R" ]] && (( renamed++ ))
  done < <(git -C "$cwd" status --porcelain 2>/dev/null)

  status_str=""
  (( untracked > 0 )) && status_str+="${gold}?${untracked} ${reset}"
  (( staged    > 0 )) && status_str+="${foam_fg}+${staged} ${reset}"
  (( modified  > 0 )) && status_str+="${rose}!${modified} ${reset}"
  (( renamed   > 0 )) && status_str+="${pine}»${renamed} ${reset}"
  (( deleted   > 0 )) && status_str+="${love}-${deleted} ${reset}"

  # ahead / behind
  ab=$(git -C "$cwd" rev-list --left-right --count @{u}...HEAD 2>/dev/null)
  if [ -n "$ab" ]; then
    behind=$(echo "$ab" | awk '{print $1}')
    ahead=$(echo "$ab"  | awk '{print $2}')
    (( ahead  > 0 )) && status_str+="${subtle}⇡${ahead} ${reset}"
    (( behind > 0 )) && status_str+="${subtle}⇣${behind} ${reset}"
  fi

  [ -n "$status_str" ] && printf " %b" "$status_str"
fi

# --- model & context ---
model=$(echo "$input" | jq -r '.model.display_name // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

printf " ${muted}|${reset}"
[ -n "$model" ] && printf " ${iris}%s${reset}" "$model"
if [ -n "$remaining" ]; then
  if (( $(printf '%.0f' "$remaining") < 20 )); then
    ctx_color="${love}"
  else
    ctx_color="${muted}"
  fi
  printf " ${ctx_color}ctx:$(printf '%.0f' "$remaining")%%${reset}"
fi

# --- vim mode ---
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
if [ -n "$vim_mode" ]; then
  if [ "$vim_mode" = "NORMAL" ]; then
    printf " ${gold}[N]${reset}"
  else
    printf " ${foam}[I]${reset}"
  fi
fi

printf "\n"
