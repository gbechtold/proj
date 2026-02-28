# proj/lib/ai.zsh — AI integration (Claude Code, Codex)
# Part of proj · Project Hub in your Terminal

_proj_ai() {
  local ai_type="${1:-claude}"
  shift 2>/dev/null

  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  case "$ai_type" in
    claude) _proj_ai_claude "$@" ;;
    codex)  _proj_ai_codex "$@" ;;
    *)      _proj_ui_error "Unknown AI: $ai_type (supported: claude, codex)" ;;
  esac
}

# ─── Claude Code Integration ────────────────────────────────

_proj_ai_claude() {
  local file=$(_proj_file "$_PROJ_CURRENT")
  local proj_path=$(_proj_json_get "$file" links claude)
  local name=$(_proj_json_get "$file" name)
  local task=$(_proj_json_get "$file" task)

  # Check if path is set
  if [[ -z "$proj_path" ]]; then
    echo ""
    _proj_ui_subheader "Claude Code: $name"
    echo ""
    _proj_ui_warn "No project path set for Claude Code"
    read "proj_path?  ${_PC_CYAN}Project path:${_PC_RESET} "
    [[ -z "$proj_path" ]] && return

    # Expand ~ to $HOME
    proj_path="${proj_path/#\~/$HOME}"
    _proj_py "$file" set-nested links claude "$proj_path"
    _proj_ui_success "Path saved: $proj_path"
  fi

  # Expand ~ to $HOME
  proj_path="${proj_path/#\~/$HOME}"

  # Check path exists
  if [[ ! -d "$proj_path" ]]; then
    _proj_ui_error "Path not found: $proj_path"
    return 1
  fi

  # Write context file for Claude to pick up
  _proj_write_context "$file" "$proj_path"

  # Build prompt with project context
  local prompt="Project: $name"
  [[ -n "$task" ]] && prompt="$prompt | Task: $task"

  local notes=$(_proj_json_get "$file" notes)
  if [[ "$notes" != "[]" && -n "$notes" ]]; then
    local notes_flat=$(echo "$notes" | python3 -c "import json,sys; print('; '.join(json.loads(sys.stdin.read())))" 2>/dev/null)
    [[ -n "$notes_flat" ]] && prompt="$prompt | Notes: $notes_flat"
  fi

  echo ""
  _proj_ui_header "Claude Code: $name" "$_PC_PURPLE"
  echo "  ${_PC_DIM}Path:${_PC_RESET}    $proj_path"
  echo "  ${_PC_DIM}Context:${_PC_RESET} .proj-context.json written"
  [[ -n "$task" ]] && echo "  ${_PC_DIM}Task:${_PC_RESET}    $task"
  echo ""

  local open_mode="${1:-ask}"

  if [[ "$open_mode" == "here" ]]; then
    # Start in current tab
    echo "  ${_PC_DIM}Starting Claude Code...${_PC_RESET}"
    (cd "$proj_path" && claude --prompt "$prompt")
  else
    # Ask what to do
    echo "  ${_PC_BOLD}[1]${_PC_RESET} Open in new iTerm2 tab"
    echo "  ${_PC_BOLD}[2]${_PC_RESET} Start here"
    echo "  ${_PC_BOLD}[q]${_PC_RESET} Cancel"
    echo ""
    read "choice?  ${_PC_CYAN}>${_PC_RESET} "

    case "$choice" in
      1) _proj_ai_new_tab "claude" "$proj_path" "$prompt" "$name" ;;
      2)
        echo "  ${_PC_DIM}Starting Claude Code...${_PC_RESET}"
        (cd "$proj_path" && claude --prompt "$prompt")
        ;;
      *) return ;;
    esac
  fi
}

# ─── Codex Integration ──────────────────────────────────────

_proj_ai_codex() {
  local file=$(_proj_file "$_PROJ_CURRENT")
  local proj_path=$(_proj_json_get "$file" links codex)
  local name=$(_proj_json_get "$file" name)

  # Fall back to claude path if no codex-specific path
  [[ -z "$proj_path" ]] && proj_path=$(_proj_json_get "$file" links claude)

  if [[ -z "$proj_path" ]]; then
    echo ""
    _proj_ui_subheader "Codex: $name"
    echo ""
    _proj_ui_warn "No project path set"
    read "proj_path?  ${_PC_CYAN}Project path:${_PC_RESET} "
    [[ -z "$proj_path" ]] && return

    proj_path="${proj_path/#\~/$HOME}"
    _proj_py "$file" set-nested links codex "$proj_path"
    _proj_ui_success "Path saved: $proj_path"
  fi

  proj_path="${proj_path/#\~/$HOME}"

  if [[ ! -d "$proj_path" ]]; then
    _proj_ui_error "Path not found: $proj_path"
    return 1
  fi

  _proj_write_context "$file" "$proj_path"

  echo ""
  _proj_ui_header "Codex: $name" "$_PC_ORANGE"
  echo "  ${_PC_DIM}Path:${_PC_RESET}    $proj_path"
  echo "  ${_PC_DIM}Context:${_PC_RESET} .proj-context.json written"
  echo ""
  echo "  ${_PC_BOLD}[1]${_PC_RESET} Open in new iTerm2 tab"
  echo "  ${_PC_BOLD}[2]${_PC_RESET} Start here"
  echo "  ${_PC_BOLD}[q]${_PC_RESET} Cancel"
  echo ""
  read "choice?  ${_PC_CYAN}>${_PC_RESET} "

  case "$choice" in
    1) _proj_ai_new_tab "codex" "$proj_path" "" "$name" ;;
    2)
      echo "  ${_PC_DIM}Starting Codex...${_PC_RESET}"
      (cd "$proj_path" && codex)
      ;;
    *) return ;;
  esac
}

# ─── Write Context File ─────────────────────────────────────

_proj_write_context() {
  local proj_file="$1"
  local proj_path="$2"

  # Write .proj-context.json to the project directory
  python3 -c "
import json, os
with open('$proj_file') as f:
    data = json.load(f)
# Write a clean context file
context = {
    'name': data.get('name', ''),
    'task': data.get('task', ''),
    'notes': data.get('notes', []),
    'links': data.get('links', {}),
}
out_path = os.path.join('$proj_path', '.proj-context.json')
with open(out_path, 'w') as f:
    json.dump(context, f, indent=2, ensure_ascii=False)
    f.write('\n')
" 2>/dev/null
}

# ─── Open New iTerm2 Tab ────────────────────────────────────

_proj_ai_new_tab() {
  local ai_cmd="$1"
  local proj_path="$2"
  local prompt="$3"
  local name="$4"

  _proj_ui_info "Opening new tab..."

  if [[ "$ai_cmd" == "claude" ]]; then
    local escaped_prompt=$(printf '%s' "$prompt" | sed "s/'/\\\\'/g")
    osascript -e "
      tell application \"iTerm2\"
        tell current window
          create tab with default profile
          tell current session
            write text \"cd '$proj_path' && claude --prompt '$escaped_prompt'\"
          end tell
        end tell
      end tell
    " 2>/dev/null
  else
    osascript -e "
      tell application \"iTerm2\"
        tell current window
          create tab with default profile
          tell current session
            write text \"cd '$proj_path' && $ai_cmd\"
          end tell
        end tell
      end tell
    " 2>/dev/null
  fi

  _proj_ui_success "New tab opened: $ai_cmd for $name"
}
