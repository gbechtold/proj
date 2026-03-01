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

  if [[ -z "$proj_path" ]]; then
    echo ""
    _proj_ui_subheader "Claude Code: $name"
    echo ""
    _proj_ui_warn "No project path set for Claude Code"
    read "proj_path?  ${_PC_CYAN}Project path:${_PC_RESET} "
    [[ -z "$proj_path" ]] && return

    proj_path=$(_proj_expand_path "$proj_path")
    _proj_py "$file" set-nested links claude "$proj_path" >/dev/null
    _proj_ui_success "Path saved: $proj_path"
  fi

  proj_path=$(_proj_expand_path "$proj_path")

  if [[ ! -d "$proj_path" ]]; then
    _proj_ui_error "Path not found: $proj_path"
    _proj_ui_hint "proj link add claude <path> ${_PU_ARROW} update path"
    return 1
  fi

  # Write rich context file
  _proj_write_context "$file" "$proj_path"

  # Build prompt with project context
  local prompt="Project: $name"
  [[ -n "$task" ]] && prompt="$prompt | Task: $task"

  local notes=$(_proj_json_get "$file" notes)
  if [[ "$notes" != "[]" && -n "$notes" ]]; then
    local notes_flat=$(echo "$notes" | python3 -c "import json,sys; print('; '.join(n.get('text',n) if isinstance(n,dict) else n for n in json.loads(sys.stdin.read())))" 2>/dev/null)
    [[ -n "$notes_flat" ]] && prompt="$prompt | Notes: $notes_flat"
  fi

  echo ""
  _proj_ui_header "Claude Code: $name"
  echo "  ${_PC_DIM}Path:${_PC_RESET}    ${_PC_WHITE}$proj_path${_PC_RESET}"
  echo "  ${_PC_DIM}Context:${_PC_RESET} ${_PC_WHITE}.proj/context.json${_PC_RESET}"
  [[ -n "$task" ]] && echo "  ${_PC_DIM}Task:${_PC_RESET}    ${_PC_WHITE}$task${_PC_RESET}"
  echo ""

  local open_mode="${1:-ask}"

  if [[ "$open_mode" == "here" ]]; then
    echo "  ${_PC_DIM}Starting Claude Code...${_PC_RESET}"
    (cd "$proj_path" && claude --prompt "$prompt")
  else
    if _proj_is_iterm2; then
      echo "  ${_PC_DIM}[1]${_PC_RESET} Open in new iTerm2 tab"
    else
      echo "  ${_PC_DIM}[1] Open in new tab (iTerm2 only)${_PC_RESET}"
    fi
    echo "  ${_PC_DIM}[2]${_PC_RESET} Start here"
    echo "  ${_PC_DIM}[q]${_PC_RESET} Cancel"
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

  [[ -z "$proj_path" ]] && proj_path=$(_proj_json_get "$file" links claude)

  if [[ -z "$proj_path" ]]; then
    echo ""
    _proj_ui_subheader "Codex: $name"
    echo ""
    _proj_ui_warn "No project path set"
    read "proj_path?  ${_PC_CYAN}Project path:${_PC_RESET} "
    [[ -z "$proj_path" ]] && return

    proj_path=$(_proj_expand_path "$proj_path")
    _proj_py "$file" set-nested links codex "$proj_path" >/dev/null
    _proj_ui_success "Path saved: $proj_path"
  fi

  proj_path=$(_proj_expand_path "$proj_path")

  if [[ ! -d "$proj_path" ]]; then
    _proj_ui_error "Path not found: $proj_path"
    _proj_ui_hint "proj link add codex <path> ${_PU_ARROW} update path"
    return 1
  fi

  _proj_write_context "$file" "$proj_path"

  echo ""
  _proj_ui_header "Codex: $name"
  echo "  ${_PC_DIM}Path:${_PC_RESET}    ${_PC_WHITE}$proj_path${_PC_RESET}"
  echo "  ${_PC_DIM}Context:${_PC_RESET} ${_PC_WHITE}.proj/context.json${_PC_RESET}"
  echo ""
  if _proj_is_iterm2; then
    echo "  ${_PC_DIM}[1]${_PC_RESET} Open in new iTerm2 tab"
  else
    echo "  ${_PC_DIM}[1] Open in new tab (iTerm2 only)${_PC_RESET}"
  fi
  echo "  ${_PC_DIM}[2]${_PC_RESET} Start here"
  echo "  ${_PC_DIM}[q]${_PC_RESET} Cancel"
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

# ─── Write Context File (Rich) ──────────────────────────────

_proj_write_context() {
  local proj_file="$1"
  local proj_path="$2"
  _proj_py "$proj_file" write-context "$proj_path"
}

# ─── Open New iTerm2 Tab ────────────────────────────────────

_proj_ai_new_tab() {
  local ai_cmd="$1"
  local proj_path="$2"
  local prompt="$3"
  local name="$4"

  if ! _proj_is_iterm2; then
    _proj_ui_error "New tab requires iTerm2"
    _proj_ui_hint "Choose option [2] to start here instead"
    return 1
  fi

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
