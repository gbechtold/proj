# proj/lib/stars.zsh — Bridge to stars workflow engine
# Part of proj · Project Hub in your Terminal
#
# proj = Controller (what/when) → stars = Executor (how)
# proj sends sparse commands, stars executes recursively

# ─── Check if stars is available ───────────────────────────

_proj_has_stars() {
  command -v stars &>/dev/null
}

# ─── Get project path for stars ────────────────────────────

_proj_stars_path() {
  [[ -z "$_PROJ_CURRENT" ]] && return 1
  local file=$(_proj_file "$_PROJ_CURRENT")
  local p=$(_proj_json_get "$file" path)
  [[ -z "$p" ]] && p=$(_proj_json_get "$file" links claude)
  echo "$p"
}

# ─── Sessions: Claude Code session search ──────────────────

_proj_sessions() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  if ! _proj_has_stars; then
    _proj_ui_error "stars not installed. Install: npm link (in 077-StarsHub)"
    return 1
  fi

  local proj_path=$(_proj_stars_path)
  if [[ -z "$proj_path" ]]; then
    _proj_ui_warn "No project path set"
    _proj_ui_hint "proj path <dir> → set directory"
    return 1
  fi

  # Expand tilde
  proj_path="${proj_path/#\~/$HOME}"

  _proj_ui_header "Claude Sessions: $_PROJ_CURRENT" "$_PC_PURPLE"

  # Call stars and parse JSON response
  local json=$(command stars sessions --project-path "$proj_path" --json --limit 20 2>/dev/null)

  if [[ -z "$json" || "$json" == "[]" ]]; then
    echo "  ${_PC_DIM}No Claude sessions found${_PC_RESET}"
    _proj_ui_hint "proj claude → start a session"
    return
  fi

  # Parse and display
  echo "$json" | python3 -c "
import json, sys
try:
    sessions = json.loads(sys.stdin.read())
    for i, s in enumerate(sessions, 1):
        date = (s.get('modified') or s.get('created', ''))[:10]
        msgs = s.get('messages', 0)
        summary = s.get('summary', '-')[:65]
        match = s.get('matchType', '')
        tag = ' *' if match == 'name' else ''
        print(f'  {i:2}) {date}  {msgs:3}msg  {summary}{tag}')
except:
    print('  Error parsing sessions')
"

  echo ""
  _proj_ui_hint "proj claude → new session  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  * = matched by name"
}

# ─── Sync: push time to Moco ──────────────────────────────

_proj_sync() {
  if ! _proj_has_stars; then
    _proj_ui_error "stars not installed"
    return 1
  fi

  local subcmd="${1:-moco}"
  _proj_ui_header "Sync: $subcmd" "$_PC_CYAN"
  command stars sync "$subcmd" --proj-dir "$PROJ_DIR" 2>&1
}

# ─── Deploy: trigger stars pipeline ───────────────────────

_proj_deploy() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  if ! _proj_has_stars; then
    _proj_ui_error "stars not installed"
    return 1
  fi

  local proj_path=$(_proj_stars_path)
  proj_path="${proj_path/#\~/$HOME}"

  _proj_ui_header "Deploy: $_PROJ_CURRENT" "$_PC_RED"
  command stars deploy --project-path "$proj_path" "$@" 2>&1
}

# ─── Report: generate project/time report ─────────────────

_proj_report() {
  if ! _proj_has_stars; then
    _proj_ui_error "stars not installed"
    return 1
  fi

  _proj_ui_header "Report" "$_PC_BLUE"
  command stars report --proj-dir "$PROJ_DIR" "$@" 2>&1
}
