# proj/lib/menu.zsh — Interactive menus
# Part of proj · Project Hub in your Terminal

# ─── Main Project Menu ───────────────────────────────────────

_proj_menu() {
  local page=${1:-1}
  local -a files

  files=("$PROJ_DIR"/*.json(NOm))

  local total=${#files}
  if (( total == 0 )); then
    _proj_ui_banner
    echo "  ${_PC_DIM}No projects yet. Let's create one!${_PC_RESET}"
    echo ""
    echo "  ${_PC_BOLD}[+]${_PC_RESET} New project  ${_PC_DIM}|${_PC_RESET}  ${_PC_BOLD}[d]${_PC_RESET} Load demos  ${_PC_DIM}|${_PC_RESET}  ${_PC_BOLD}[q]${_PC_RESET} Quit"
    echo ""
    read "choice?  ${_PC_CYAN}>${_PC_RESET} "

    case "$choice" in
      +|new|n) _proj_new_interactive ;;
      d|demo) _proj_create_demos && _proj_menu ;;
      *) return ;;
    esac
    return
  fi

  local total_pages=$(( (total + PROJ_PAGE_SIZE - 1) / PROJ_PAGE_SIZE ))
  (( page > total_pages )) && page=$total_pages
  (( page < 1 )) && page=1
  local start=$(( (page - 1) * PROJ_PAGE_SIZE + 1 ))
  local end=$(( page * PROJ_PAGE_SIZE ))
  (( end > total )) && end=$total

  _proj_ui_header "Projects  ${_PC_DIM}${page}/${total_pages}  ${_PU_DOT}  ${total} total${_PC_RESET}" "$_PC_CYAN"

  for i in {$start..$end}; do
    local f="${files[$i]}"
    local pname=$(_proj_json_get "$f" name)
    local pcolor=$(_proj_json_get "$f" color)
    local ptask=$(_proj_json_get "$f" task)
    local active=""
    local timer=""
    [[ "$pname" == "$_PROJ_CURRENT" ]] && active="yes"
    local tstatus=$(_proj_py "$f" time-status)
    [[ "$tstatus" == running:* ]] && timer="yes"

    local idx=$(( i - start + 1 ))
    _proj_ui_project_line "$idx" "$pname" "$pcolor" "$ptask" "$active" "$timer"
  done

  echo ""
  _proj_ui_separator

  # Navigation line
  local nav=""
  (( page > 1 )) && nav="${_PC_BOLD}[p]${_PC_RESET} Prev  "
  (( page < total_pages )) && nav="${nav}${_PC_BOLD}[w]${_PC_RESET} Next  "
  echo "  ${nav}${_PC_BOLD}[+]${_PC_RESET} New  ${_PC_DIM}|${_PC_RESET}  ${_PC_BOLD}[q]${_PC_RESET} Quit"
  echo ""

  read "choice?  ${_PC_CYAN}>${_PC_RESET} "

  case "$choice" in
    q|Q|"") return ;;
    +|new|neu)
      _proj_new_interactive
      ;;
    p|P)
      (( page > 1 )) && _proj_menu $(( page - 1 ))
      ;;
    w|W)
      (( page < total_pages )) && _proj_menu $(( page + 1 ))
      ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local selected=$(( start + choice - 1 ))
        if (( selected >= 1 && selected <= total )); then
          local selfile="${files[$selected]}"
          local selname=$(_proj_json_get "$selfile" name)
          _proj_use "$selname"
        else
          _proj_ui_error "Invalid selection"
        fi
      else
        # Treat as project name — quick create/activate
        _proj_use "$choice"
      fi
      ;;
  esac
}

# ─── New Project Wizard ──────────────────────────────────────

_proj_new_interactive() {
  echo ""
  _proj_ui_subheader "New Project"
  echo ""

  read "name?  ${_PC_CYAN}Name:${_PC_RESET} "
  [[ -z "$name" ]] && _proj_ui_warn "Cancelled" && return

  echo "  ${_PC_DIM}Colors: ${_PC_GREEN}green${_PC_RESET} ${_PC_BLUE}blue${_PC_RESET} ${_PC_CYAN}cyan${_PC_RESET} ${_PC_RED}red${_PC_RESET} ${_PC_ORANGE}orange${_PC_RESET} ${_PC_YELLOW}yellow${_PC_RESET} ${_PC_PURPLE}purple${_PC_RESET} ${_PC_PINK}pink${_PC_RESET} ${_PC_GRAY}gray${_PC_RESET}"
  read "color?  ${_PC_CYAN}Color ${_PC_DIM}[enter=cyan]:${_PC_RESET} "
  [[ -z "$color" ]] && color="cyan"

  _proj_use "$name" "$color"
}
