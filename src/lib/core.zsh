# proj/lib/core.zsh — Core project operations
# Part of proj · Project Hub in your Terminal

# ─── Config ──────────────────────────────────────────────────
typeset -g PROJ_PAGE_SIZE=10

# iTerm2 color presets (name -> R G B)
typeset -gA PROJ_COLORS
PROJ_COLORS=(
  green   "40 180 80"
  blue    "50 100 200"
  cyan    "0 180 180"
  red     "200 60 60"
  orange  "220 140 30"
  yellow  "200 180 30"
  purple  "140 60 200"
  pink    "200 80 140"
  gray    "120 120 120"
)

# Dark background variants (~10% brightness)
typeset -gA PROJ_COLORS_BG
PROJ_COLORS_BG=(
  green   "8 25 12"
  blue    "10 15 30"
  cyan    "5 20 20"
  red     "28 10 10"
  orange  "25 18 8"
  yellow  "25 22 8"
  purple  "18 10 28"
  pink    "25 12 18"
  gray    "18 18 18"
)

# ─── Project Templates ──────────────────────────────────────
typeset -gA PROJ_TEMPLATES
PROJ_TEMPLATES=(
  webdev    "cyan|Site launch|live,staging,dev,github,cloudways,ssh,clickup,moco-kunde,moco-auftrag,1password"
  saas      "blue|MVP sprint|live,dev,github,claude,analytics,1password"
  marketing "orange|Campaign launch|live,google-ads,facebook-ads,analytics,clickup,moco-kunde,moco-auftrag"
  freelance "green|Project kickoff|live,github,gmail,moco-kunde,moco-auftrag,1password"
)
typeset -gA PROJ_TEMPLATE_DESC
PROJ_TEMPLATE_DESC=(
  webdev    "Hosting, deploy, PM, billing"
  saas      "Dev-focused with analytics"
  marketing "Ads, analytics, PM, billing"
  freelance "Minimal with billing"
)

# Terminal detection
_proj_is_iterm2() {
  [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]
}
typeset -g _PROJ_ITERM_WARNED=0

# Current session state
typeset -g _PROJ_CURRENT=""

# ─── JSON Helpers ────────────────────────────────────────────

_proj_py() {
  python3 "$PROJ_PY" "$@"
}

_proj_json_get() {
  _proj_py "$1" get "${@:2}"
}

_proj_json_set() {
  _proj_py "$1" set "${@:2}"
}

# ─── Path Helpers ───────────────────────────────────────────

_proj_file() {
  local name="$1"
  local safe=$(echo "$name" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
  echo "$PROJ_DIR/$safe.json"
}

_proj_expand_path() {
  echo "${1/#\~/$HOME}"
}

# ─── Color Mapping ──────────────────────────────────────────

_proj_color_code() {
  case "$1" in
    green)  echo "$_PC_GREEN" ;;
    blue)   echo "$_PC_BLUE" ;;
    cyan)   echo "$_PC_CYAN" ;;
    red)    echo "$_PC_RED" ;;
    orange) echo "$_PC_ORANGE" ;;
    yellow) echo "$_PC_YELLOW" ;;
    purple) echo "$_PC_PURPLE" ;;
    pink)   echo "$_PC_PINK" ;;
    gray)   echo "$_PC_GRAY" ;;
    *)      echo "$_PC_WHITE" ;;
  esac
}

# ─── iTerm2 Integration ─────────────────────────────────────

_proj_iterm_color() {
  _proj_is_iterm2 || return 0
  local r g b
  read r g b <<< "$1"
  printf "\033]6;1;bg;red;brightness;%d\a" "$r"
  printf "\033]6;1;bg;green;brightness;%d\a" "$g"
  printf "\033]6;1;bg;blue;brightness;%d\a" "$b"
}

_proj_iterm_clear_color() {
  _proj_is_iterm2 || return 0
  printf "\033]6;1;bg;*;default\a"
}

_proj_iterm_title() {
  _proj_is_iterm2 || return 0
  printf "\033]1;%s\a" "$1"
}

_proj_iterm_badge() {
  _proj_is_iterm2 || return 0
  local encoded
  encoded=$(printf "%s" "$1" | base64)
  printf "\033]1337;SetBadgeFormat=%s\a" "$encoded"
}

_proj_iterm_bg_color() {
  _proj_is_iterm2 || return 0
  local r g b
  read r g b <<< "$1"
  printf "\033]1337;SetColors=bg=%02x%02x%02x\a" "$r" "$g" "$b"
}

_proj_iterm_reset_bg() {
  _proj_is_iterm2 || return 0
  printf "\033]1337;SetColors=bg=000000\a"
}

# ─── Refresh iTerm2 State ───────────────────────────────────

_proj_refresh() {
  [[ -z "$_PROJ_CURRENT" ]] && return

  local file=$(_proj_file "$_PROJ_CURRENT")
  [[ ! -f "$file" ]] && return

  # One-time notice for non-iTerm2 terminals
  if ! _proj_is_iterm2 && (( _PROJ_ITERM_WARNED == 0 )); then
    _PROJ_ITERM_WARNED=1
    _proj_ui_info "Tab colors/badges require iTerm2 ${_PC_DIM}(${TERM_PROGRAM:-unknown})${_PC_RESET}"
  fi

  local color=$(_proj_json_get "$file" color)
  local task=$(_proj_py "$file" task-doing)
  local name=$(_proj_json_get "$file" name)

  # Set tab color
  if [[ -n "$color" && -n "${PROJ_COLORS[$color]}" ]]; then
    _proj_iterm_color "${PROJ_COLORS[$color]}"
  fi

  # Set background color (dark variant)
  if [[ -n "$color" && -n "${PROJ_COLORS_BG[$color]}" ]]; then
    _proj_iterm_bg_color "${PROJ_COLORS_BG[$color]}"
  fi

  # Build title
  local title="$name"
  [[ -n "$task" ]] && title="$name │ $task"
  _proj_iterm_title "$title"

  # Badge
  local badge="$name"
  [[ -n "$task" ]] && badge="$badge\n$task"
  _proj_iterm_badge "$badge"
}

# ─── Project Use (Activate) ─────────────────────────────────

_proj_use() {
  local name="" color="" template=""

  # Parse arguments: proj use <name> [color] [-t template]
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--template) template="$2"; shift 2 ;;
      --template=*)  template="${1#*=}"; shift ;;
      *)
        if [[ -z "$name" ]]; then
          name="$1"
        elif [[ -z "$color" ]]; then
          color="$1"
        fi
        shift ;;
    esac
  done

  [[ -z "$name" ]] && _proj_ui_error "Usage: proj use <name> [color] [-t template]" && return 1

  local file=$(_proj_file "$name")

  if [[ ! -f "$file" ]]; then
    if [[ -n "$template" ]]; then
      local tpl_data="${PROJ_TEMPLATES[$template]}"
      if [[ -z "$tpl_data" ]]; then
        _proj_ui_error "Unknown template: $template"
        _proj_ui_hint "proj templates ${_PU_ARROW} list available"
        return 1
      fi
      local tpl_color="${tpl_data%%|*}"
      local rest="${tpl_data#*|}"
      local tpl_task="${rest%%|*}"
      local tpl_links="${rest#*|}"
      [[ -z "$color" ]] && color="$tpl_color"
      _proj_py "$file" init "$name" "$color" >/dev/null
      _proj_py "$file" task-add "$tpl_task" >/dev/null
      _proj_py "$file" task-update 0 doing >/dev/null
      local -a link_arr
      link_arr=("${(@s:,:)tpl_links}")
      for lt in "${link_arr[@]}"; do
        _proj_py "$file" set-nested links "$lt" "" >/dev/null
      done
      _proj_ui_success "New project ${_PC_WHITE}${_PC_BOLD}$name${_PC_RESET} ${_PC_DIM}(template: $template)${_PC_RESET}"
    else
      if [[ -n "$color" ]]; then
        _proj_py "$file" init "$name" "$color" >/dev/null
      else
        _proj_py "$file" init "$name" >/dev/null
      fi
      _proj_ui_success "New project ${_PC_WHITE}${_PC_BOLD}$name${_PC_RESET} created"
    fi
  elif [[ -n "$color" ]]; then
    _proj_json_set "$file" color "$color"
  fi

  _PROJ_CURRENT="$name"
  _proj_refresh

  local proj_path=$(_proj_json_get "$file" path)
  if [[ -n "$proj_path" ]]; then
    _proj_ui_info "Active: ${_PC_WHITE}${_PC_BOLD}$name${_PC_RESET} ${_PC_DIM}${_PU_DOT} $proj_path${_PC_RESET}"
  else
    _proj_ui_info "Active: ${_PC_WHITE}${_PC_BOLD}$name${_PC_RESET}"
  fi
  _proj_ui_hint "proj cd ${_PU_ARROW} dir  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj open ${_PU_ARROW} links  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj time start ${_PU_ARROW} timer"
}

# ─── Templates ───────────────────────────────────────────────

_proj_templates() {
  _proj_ui_header "Project Templates"
  for tpl_name in ${(ko)PROJ_TEMPLATES}; do
    local tpl_data="${PROJ_TEMPLATES[$tpl_name]}"
    local tpl_color="${tpl_data%%|*}"
    local desc="${PROJ_TEMPLATE_DESC[$tpl_name]}"
    local cc=$(_proj_color_code "$tpl_color")
    printf "  ${cc}${_PC_BOLD}%-12s${_PC_RESET} ${_PC_DIM}%s${_PC_RESET}\n" "$tpl_name" "$desc"
  done
  echo ""
  _proj_ui_hint "proj use <name> -t <template> ${_PU_ARROW} create from template"
}

# ─── Project Path & cd ──────────────────────────────────────

_proj_path() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")

  local new_path="$1"
  if [[ -z "$new_path" ]]; then
    local current=$(_proj_json_get "$file" path)
    if [[ -n "$current" ]]; then
      _proj_ui_info "Path: ${_PC_BOLD}$current${_PC_RESET}"
    else
      _proj_ui_warn "No path set"
      _proj_ui_hint "proj path <dir> ${_PU_ARROW} set project directory"
    fi
    return
  fi

  new_path=$(_proj_expand_path "$new_path")

  if [[ ! -d "$new_path" ]]; then
    _proj_ui_error "Directory not found: $new_path"
    return 1
  fi

  _proj_json_set "$file" path "$new_path"
  _proj_ui_success "Path: ${_PC_BOLD}$new_path${_PC_RESET}"
  _proj_ui_hint "proj cd ${_PU_ARROW} jump there"
}

_proj_cd() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  local proj_path=$(_proj_json_get "$file" path)

  if [[ -z "$proj_path" ]]; then
    _proj_ui_warn "No path set for $_PROJ_CURRENT"
    _proj_ui_hint "proj path <dir> ${_PU_ARROW} set project directory"
    return 1
  fi

  proj_path=$(_proj_expand_path "$proj_path")

  if [[ ! -d "$proj_path" ]]; then
    _proj_ui_error "Directory not found: $proj_path"
    return 1
  fi

  cd "$proj_path"
  _proj_ui_info "${_PU_FOLDER} ${_PC_BOLD}$proj_path${_PC_RESET}"
}

# ─── Project Tasks (Multi-Task) ─────────────────────────────

_proj_task() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  local subcmd="$1"

  case "$subcmd" in
    add|a)    shift; _proj_task_add "$@" ;;
    done|d)   shift; _proj_task_done "$@" ;;
    do|doing) shift; _proj_task_doing "$@" ;;
    rm|r)     shift; _proj_task_rm "$@" ;;
    list|ls|l|"") _proj_task_list ;;
    *)        _proj_task_add "$@" ;;  # bare text = add
  esac
}

_proj_task_list() {
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_ui_header "Tasks: $_PROJ_CURRENT"

  local task_output=$(_proj_py "$file" task-list)
  if [[ -z "$task_output" ]]; then
    echo "  ${_PC_DIM}No tasks yet${_PC_RESET}"
    _proj_ui_hint "proj task <text> ${_PU_ARROW} add task"
    return
  fi

  local marker num tc
  while IFS='|' read -r idx text tstate created; do
    case "$tstate" in
      todo)  marker="${_PC_DIM}[ ]${_PC_RESET}" ;;
      doing) marker="[${_PC_YELLOW}>${_PC_RESET}]" ;;
      done)  marker="[${_PC_GREEN}${_PU_CHECK}${_PC_RESET}]" ;;
      *)     marker="${_PC_DIM}[ ]${_PC_RESET}" ;;
    esac
    num=$((idx + 1))
    tc="$_PC_WHITE"
    [[ "$tstate" == "done" ]] && tc="$_PC_DIM"
    printf "  ${_PC_DIM}%2d)${_PC_RESET} %b ${tc}%s${_PC_RESET}\n" "$num" "$marker" "$text"
  done <<< "$task_output"

  echo ""
  _proj_ui_hint "add <text>  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  do <#>  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  done <#>  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  rm <#>"
}

_proj_task_add() {
  local text="$*"
  [[ -z "$text" ]] && _proj_ui_error "Usage: proj task <text>" && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" task-add "$text" >/dev/null
  _proj_ui_success "Task added: ${_PC_WHITE}$text${_PC_RESET}"
}

_proj_task_done() {
  local num="$1"
  [[ -z "$num" || ! "$num" =~ ^[0-9]+$ ]] && _proj_ui_error "Usage: proj task done <#>" && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" task-update $((num - 1)) done >/dev/null
  _proj_refresh
  _proj_ui_success "Task #$num done"
}

_proj_task_doing() {
  local num="$1"
  [[ -z "$num" || ! "$num" =~ ^[0-9]+$ ]] && _proj_ui_error "Usage: proj task do <#>" && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" task-update $((num - 1)) doing >/dev/null
  _proj_refresh
  _proj_ui_success "Task #$num active"
}

_proj_task_rm() {
  local num="$1"
  [[ -z "$num" || ! "$num" =~ ^[0-9]+$ ]] && _proj_ui_error "Usage: proj task rm <#>" && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" task-rm $((num - 1)) >/dev/null
  _proj_refresh
  _proj_ui_success "Task #$num removed"
}

# ─── Project Notes ───────────────────────────────────────────

_proj_note_dispatch() {
  local subcmd="$1"
  case "$subcmd" in
    rm|remove) shift; _proj_note_rm "$@" ;;
    edit)      shift; _proj_note_edit "$@" ;;
    *)         _proj_note "$@" ;;
  esac
}

_proj_note() {
  local note_text="$*"
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  [[ -z "$note_text" ]] && _proj_notes && return

  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" append-note "$note_text" >/dev/null
  _proj_ui_success "Note added"
}

_proj_note_rm() {
  local idx="$1"
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  [[ -z "$idx" ]] && _proj_ui_error "Usage: proj note rm <#>" && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" pop-list notes $(( idx - 1 )) >/dev/null
  _proj_ui_success "Note #$idx removed"
}

_proj_note_edit() {
  local idx="$1"
  shift
  local new_text="$*"
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  [[ -z "$idx" || -z "$new_text" ]] && _proj_ui_error "Usage: proj note edit <#> <text>" && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" set-list notes $(( idx - 1 )) "$new_text" >/dev/null
  _proj_ui_success "Note #$idx updated"
}

_proj_notes() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")

  _proj_ui_header "Notes: $_PROJ_CURRENT"

  local notes=$(_proj_json_get "$file" notes)
  if [[ "$notes" == "[]" || -z "$notes" ]]; then
    echo "  ${_PC_DIM}No notes yet${_PC_RESET}"
  else
    echo "$notes" | python3 -c "
import json, sys
notes = json.loads(sys.stdin.read())
for i, n in enumerate(notes, 1):
    if isinstance(n, dict):
        text = n.get('text', '')
        ts = n.get('created', '')[:10]
        print(f'  \033[2m{i})\033[0m \033[38;5;255m{text}\033[0m  \033[2m{ts}\033[0m')
    else:
        print(f'  \033[2m{i})\033[0m \033[38;5;255m{n}\033[0m')
"
  fi
  echo ""
  _proj_ui_hint "note <text> ${_PU_ARROW} add  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  note rm <#>  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  note edit <#> <text>"
}

_proj_notes_clear() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_json_set "$file" notes "[]"
  _proj_ui_success "Notes cleared"
}

# ─── Project Color ───────────────────────────────────────────

_proj_color() {
  local color="$1"
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  if [[ -z "$color" ]]; then
    echo "  Available: ${_PC_GREEN}green${_PC_RESET} ${_PC_BLUE}blue${_PC_RESET} ${_PC_CYAN}cyan${_PC_RESET} ${_PC_RED}red${_PC_RESET} ${_PC_ORANGE}orange${_PC_RESET} ${_PC_YELLOW}yellow${_PC_RESET} ${_PC_PURPLE}purple${_PC_RESET} ${_PC_PINK}pink${_PC_RESET} ${_PC_GRAY}gray${_PC_RESET}"
    return 0
  fi

  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_json_set "$file" color "$color"
  _proj_refresh
  _proj_ui_success "Color: $color"
}

# ─── Project Info ────────────────────────────────────────────

_proj_info() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")

  local name=$(_proj_json_get "$file" name)
  local color=$(_proj_json_get "$file" color)
  local created=$(_proj_json_get "$file" created)
  local updated=$(_proj_json_get "$file" updated)

  # Batch call: note_count|link_count|time_count|task_count|timer_status
  local batch=$(_proj_py "$file" info-batch)
  local note_count="${batch%%|*}";  batch="${batch#*|}"
  local link_count="${batch%%|*}";  batch="${batch#*|}"
  local time_count="${batch%%|*}";  batch="${batch#*|}"
  local task_count="${batch%%|*}"
  local timer_status="${batch#*|}"

  _proj_ui_header "$name"

  local proj_path=$(_proj_json_get "$file" path)
  local doing_task=$(_proj_py "$file" task-doing)

  echo "  ${_PC_DIM}Color:${_PC_RESET}    ${_PC_WHITE}$color${_PC_RESET}"
  [[ -n "$proj_path" ]] && echo "  ${_PC_DIM}Path:${_PC_RESET}     ${_PC_WHITE}${_PC_BOLD}$proj_path${_PC_RESET}"

  if [[ -n "$doing_task" ]]; then
    echo "  ${_PC_DIM}Task:${_PC_RESET}     ${_PC_YELLOW}${_PU_PLAY}${_PC_RESET} ${_PC_WHITE}${doing_task}${_PC_RESET} ${_PC_DIM}(${task_count} total)${_PC_RESET}"
  elif (( task_count > 0 )); then
    echo "  ${_PC_DIM}Tasks:${_PC_RESET}    ${_PC_WHITE}${task_count}${_PC_RESET}"
  else
    echo "  ${_PC_DIM}Task:${_PC_RESET}     ${_PC_DIM}—${_PC_RESET}"
  fi

  echo "  ${_PC_DIM}Notes:${_PC_RESET}    ${_PC_WHITE}$note_count${_PC_RESET}"
  echo "  ${_PC_DIM}Links:${_PC_RESET}    ${_PC_WHITE}$link_count${_PC_RESET}"
  echo "  ${_PC_DIM}Time:${_PC_RESET}     ${_PC_WHITE}$time_count entries${_PC_RESET}"
  echo "  ${_PC_DIM}Created:${_PC_RESET}  ${_PC_WHITE}${created%T*}${_PC_RESET}"
  echo "  ${_PC_DIM}Updated:${_PC_RESET}  ${_PC_WHITE}${updated%T*}${_PC_RESET}"

  if [[ "$timer_status" == running:* ]]; then
    local elapsed="${timer_status##*:}"
    echo ""
    echo "  ${_PC_RED}${_PU_TIMER} Timer running: ${_PC_WHITE}${_PC_BOLD}${elapsed}${_PC_RESET}"
  fi

  _proj_ui_hint "o ${_PU_ARROW} links  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  task ${_PU_ARROW} tasks  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  time start ${_PU_ARROW} timer"
}

# ─── Project List (non-interactive) ─────────────────────────

_proj_list() {
  _proj_ui_header "All Projects"

  local -a files
  files=("$PROJ_DIR"/*.json(NOm))

  if (( ${#files} == 0 )); then
    echo "  ${_PC_DIM}No projects yet${_PC_RESET}"
    _proj_ui_hint "proj use <name> ${_PU_ARROW} create  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj demo ${_PU_ARROW} demo data"
    return
  fi

  local idx=0
  for f in "${files[@]}"; do
    idx=$((idx + 1))
    local pname=$(_proj_json_get "$f" name)
    local pcolor=$(_proj_json_get "$f" color)
    local ptask=$(_proj_json_get "$f" task)
    local active=""
    local timer=""
    [[ "$pname" == "$_PROJ_CURRENT" ]] && active="yes"
    local tstatus=$(_proj_py "$f" time-status)
    [[ "$tstatus" == running:* ]] && timer="yes"
    _proj_ui_project_line "$idx" "$pname" "$pcolor" "$ptask" "$active" "$timer"
  done
  echo ""
}

# ─── Project Clear ───────────────────────────────────────────

_proj_clear() {
  _PROJ_CURRENT=""
  _proj_iterm_clear_color
  _proj_iterm_reset_bg
  _proj_iterm_title ""
  _proj_iterm_badge ""
  _proj_ui_success "Tab reset"
}

# ─── Project Remove ──────────────────────────────────────────

_proj_rm() {
  local name="$1"
  [[ -z "$name" ]] && _proj_ui_error "Usage: proj rm <name>" && return 1

  local file=$(_proj_file "$name")
  if [[ -f "$file" ]]; then
    local confirm
    read "confirm?  Delete '${name}'? ${_PC_DIM}[y/N]${_PC_RESET} "
    [[ "$confirm" != [yY] ]] && _proj_ui_info "Cancelled" && return
    rm "$file"
    _proj_ui_success "Project '$name' deleted"
  else
    _proj_ui_error "Project '$name' not found"
  fi
  [[ "$_PROJ_CURRENT" == "$name" ]] && _proj_clear
}
