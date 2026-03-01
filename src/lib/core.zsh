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

# ─── File Path ───────────────────────────────────────────────

_proj_file() {
  local name="$1"
  local safe=$(echo "$name" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
  echo "$PROJ_DIR/$safe.json"
}

# ─── iTerm2 Integration ─────────────────────────────────────

_proj_iterm_color() {
  local r g b
  read r g b <<< "$1"
  printf "\033]6;1;bg;red;brightness;%d\a" "$r"
  printf "\033]6;1;bg;green;brightness;%d\a" "$g"
  printf "\033]6;1;bg;blue;brightness;%d\a" "$b"
}

_proj_iterm_clear_color() {
  printf "\033]6;1;bg;*;default\a"
}

_proj_iterm_title() {
  printf "\033]1;%s\a" "$1"
}

_proj_iterm_badge() {
  local encoded
  encoded=$(printf "%s" "$1" | base64)
  printf "\033]1337;SetBadgeFormat=%s\a" "$encoded"
}

_proj_iterm_bg_color() {
  local r g b
  read r g b <<< "$1"
  printf "\033]1337;SetColors=bg=%02x%02x%02x\a" "$r" "$g" "$b"
}

_proj_iterm_reset_bg() {
  printf "\033]1337;SetColors=bg=000000\a"
}

# ─── Refresh iTerm2 State ───────────────────────────────────

_proj_refresh() {
  [[ -z "$_PROJ_CURRENT" ]] && return

  local file=$(_proj_file "$_PROJ_CURRENT")
  [[ ! -f "$file" ]] && return

  local color=$(_proj_json_get "$file" color)
  local task=$(_proj_json_get "$file" task)
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
  local name="$1"
  local color="$2"
  [[ -z "$name" ]] && _proj_ui_error "Usage: proj use <name> [color]" && return 1

  local file=$(_proj_file "$name")

  if [[ ! -f "$file" ]]; then
    # Create new project
    if [[ -n "$color" ]]; then
      _proj_py "$file" init "$name" "$color"
    else
      _proj_py "$file" init "$name"
    fi
    _proj_ui_success "New project ${_PC_BOLD}$name${_PC_RESET} created"
  elif [[ -n "$color" ]]; then
    _proj_json_set "$file" color "$color"
  fi

  _PROJ_CURRENT="$name"
  _proj_refresh

  # Show path if set
  local proj_path=$(_proj_json_get "$file" path)
  if [[ -n "$proj_path" ]]; then
    _proj_ui_info "Active: ${_PC_WHITE}${_PC_BOLD}$name${_PC_RESET} ${_PC_DIM}${_PU_DOT} $proj_path${_PC_RESET}"
  else
    _proj_ui_info "Active: ${_PC_WHITE}${_PC_BOLD}$name${_PC_RESET}"
  fi
  _proj_ui_hint "proj cd ${_PU_ARROW} dir  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj open ${_PU_ARROW} links  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj time start ${_PU_ARROW} timer"
}

# ─── Project Path & cd ──────────────────────────────────────

_proj_path() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")

  local new_path="$1"
  if [[ -z "$new_path" ]]; then
    # Show current path
    local current=$(_proj_json_get "$file" path)
    if [[ -n "$current" ]]; then
      _proj_ui_info "Path: ${_PC_BOLD}$current${_PC_RESET}"
    else
      _proj_ui_warn "No path set"
      _proj_ui_hint "proj path <dir> ${_PU_ARROW} set project directory"
    fi
    return
  fi

  # Expand ~ and resolve
  new_path="${new_path/#\~/$HOME}"

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

  proj_path="${proj_path/#\~/$HOME}"

  if [[ ! -d "$proj_path" ]]; then
    _proj_ui_error "Directory not found: $proj_path"
    return 1
  fi

  cd "$proj_path"
  _proj_ui_info "📂 ${_PC_BOLD}$proj_path${_PC_RESET}"
}

# ─── Project Task ────────────────────────────────────────────

_proj_task() {
  local task_text="$*"
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project. Run: proj use <name>" && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_json_set "$file" task "$task_text"
  _proj_refresh
  _proj_ui_success "Task: $task_text"
}

# ─── Project Notes ───────────────────────────────────────────

_proj_note() {
  local note_text="$*"
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" append notes "\"$note_text\""
  _proj_refresh
  _proj_ui_success "Note added"
}

_proj_notes() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")

  _proj_ui_header "Notes: $_PROJ_CURRENT" "$_PC_YELLOW"

  local notes=$(_proj_json_get "$file" notes)
  if [[ "$notes" == "[]" || -z "$notes" ]]; then
    echo "  ${_PC_DIM}No notes yet${_PC_RESET}"
  else
    echo "$notes" | python3 -c "
import json, sys
notes = json.loads(sys.stdin.read())
for i, n in enumerate(notes, 1):
    print(f'  {i}) {n}')
"
  fi
  _proj_ui_hint "proj note <text> ${_PU_ARROW} add note"
}

_proj_notes_clear() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_json_set "$file" notes "[]"
  _proj_refresh
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
  local task=$(_proj_json_get "$file" task)
  local created=$(_proj_json_get "$file" created)
  local updated=$(_proj_json_get "$file" updated)
  local note_count=$(_proj_py "$file" count notes)
  local link_count=$(_proj_py "$file" count links)
  local time_count=$(_proj_py "$file" count time)
  local timer_status=$(_proj_py "$file" time-status)

  _proj_ui_header "$name" "$_PC_CYAN"

  local proj_path=$(_proj_json_get "$file" path)

  echo "  ${_PC_DIM}Color:${_PC_RESET}    ${_PC_WHITE}$color${_PC_RESET}"
  [[ -n "$proj_path" ]] && echo "  ${_PC_DIM}Path:${_PC_RESET}     ${_PC_WHITE}${_PC_BOLD}$proj_path${_PC_RESET}"
  echo "  ${_PC_DIM}Task:${_PC_RESET}     ${_PC_WHITE}${task:-—}${_PC_RESET}"
  echo "  ${_PC_DIM}Notes:${_PC_RESET}    ${_PC_WHITE}$note_count${_PC_RESET}"
  echo "  ${_PC_DIM}Links:${_PC_RESET}    ${_PC_WHITE}$link_count${_PC_RESET}"
  echo "  ${_PC_DIM}Time:${_PC_RESET}     ${_PC_WHITE}$time_count entries${_PC_RESET}"
  echo "  ${_PC_DIM}Created:${_PC_RESET}  ${_PC_WHITE}${created%T*}${_PC_RESET}"
  echo "  ${_PC_DIM}Updated:${_PC_RESET}  ${_PC_WHITE}${updated%T*}${_PC_RESET}"

  if [[ "$timer_status" == running:* ]]; then
    local elapsed="${timer_status##*:}"
    echo ""
    echo "  ${_PC_RED}${_PU_TIMER} Timer running: ${elapsed}${_PC_RESET}"
  fi

  _proj_ui_hint "o ${_PU_ARROW} links  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  t start ${_PU_ARROW} timer  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  claude ${_PU_ARROW} AI"
}

# ─── Project List (non-interactive) ─────────────────────────

_proj_list() {
  _proj_ui_header "All Projects" "$_PC_BLUE"

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
    rm "$file"
    _proj_ui_success "Project '$name' deleted"
  else
    _proj_ui_error "Project '$name' not found"
  fi
  [[ "$_PROJ_CURRENT" == "$name" ]] && _proj_clear
}
