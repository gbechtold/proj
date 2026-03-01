# proj/lib/menu.zsh — Interactive menus
# Part of proj · Project Hub in your Terminal

# ─── fzf Detection ────────────────────────────────────────────

_proj_has_fzf() {
  [[ -z "$PROJ_NO_FZF" ]] && command -v fzf &>/dev/null
}

# ─── Search Projects (substring, case-insensitive) ───────────

_proj_search_projects() {
  local query="${1:l}"  # lowercase
  local -a matches
  for f in "$PROJ_DIR"/*.json(N); do
    local pname=$(_proj_json_get "$f" name)
    if [[ "${pname:l}" == *"$query"* ]]; then
      matches+=("$f|$pname")
    fi
  done
  printf '%s\n' "${matches[@]}"
}

# ─── fzf Project Selector ─────────────────────────────────────

_proj_fzf_select() {
  local -a files
  files=("$PROJ_DIR"/*.json(NOm))
  (( ${#files} == 0 )) && return 1

  local -a entries
  for f in "${files[@]}"; do
    local pname=$(_proj_json_get "$f" name)
    local ptask=$(_proj_json_get "$f" task)
    local pcolor=$(_proj_json_get "$f" color)
    local active=""
    [[ "$pname" == "$_PROJ_CURRENT" ]] && active=" *"
    local display="${pname}${active}"
    [[ -n "$ptask" ]] && display="${display} · ${ptask}"
    entries+=("${f}|${pname}|${display}")
  done

  local selected=$(printf '%s\n' "${entries[@]}" | \
    fzf --delimiter='|' \
        --with-nth=3 \
        --height=40% \
        --reverse \
        --border \
        --prompt="proj> " \
        --header="Select project (ESC=cancel, +=new)" \
        --bind="+=abort" \
        --preview="python3 '$PROJ_PY' {1} dump 2>/dev/null | python3 -c \"
import json,sys
d=json.loads(sys.stdin.read())
print(f'  Name:  {d.get(\\\"name\\\",\\\"?\\\")}'  )
print(f'  Color: {d.get(\\\"color\\\",\\\"-\\\")}'  )
print(f'  Task:  {d.get(\\\"task\\\",\\\"-\\\")}'  )
print(f'  Notes: {len(d.get(\\\"notes\\\",[]))}'  )
print(f'  Links: {len(d.get(\\\"links\\\",{}))}'  )
print(f'  Time:  {len(d.get(\\\"time\\\",[]))} entries'  )
\"" \
        --preview-window=right:35%:wrap 2>/dev/null)

  [[ -z "$selected" ]] && return 1
  echo "${selected}" | cut -d'|' -f2
}

# ─── Main Project Menu ───────────────────────────────────────

_proj_menu() {
  local -a files
  files=("$PROJ_DIR"/*.json(NOm))
  local total=${#files}

  if (( total == 0 )); then
    _proj_ui_banner
    echo "  ${_PC_DIM}No projects yet. Let's create one!${_PC_RESET}"
    echo ""
    echo "  ${_PC_DIM}[+] New project  |  [d] Load demos  |  [q] Quit${_PC_RESET}"
    echo ""
    read "choice?  ${_PC_CYAN}>${_PC_RESET} "
    case "$choice" in
      +|new|n) _proj_new_interactive ;;
      d|demo) _proj_create_demos && _proj_menu ;;
      *) return ;;
    esac
    return
  fi

  # fzf mode
  if _proj_has_fzf; then
    local selected=$(_proj_fzf_select)
    [[ -n "$selected" ]] && _proj_use "$selected"
    return
  fi

  # Paginated fallback
  _proj_menu_paginated "${1:-1}"
}

_proj_menu_paginated() {
  local page=${1:-1}
  local -a files
  files=("$PROJ_DIR"/*.json(NOm))
  local total=${#files}

  local total_pages=$(( (total + PROJ_PAGE_SIZE - 1) / PROJ_PAGE_SIZE ))
  (( page > total_pages )) && page=$total_pages
  (( page < 1 )) && page=1
  local start=$(( (page - 1) * PROJ_PAGE_SIZE + 1 ))
  local end=$(( page * PROJ_PAGE_SIZE ))
  (( end > total )) && end=$total

  _proj_ui_header "Projects  ${_PC_DIM}${page}/${total_pages}  ${_PU_DOT}  ${total} total${_PC_RESET}"

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

  local nav=""
  (( page > 1 )) && nav="[p] Prev  "
  (( page < total_pages )) && nav="${nav}[w] Next  "
  echo "  ${_PC_DIM}${nav}[+] New  |  [q] Quit${_PC_RESET}"
  echo ""

  read "choice?  ${_PC_CYAN}>${_PC_RESET} "

  case "$choice" in
    q|Q|"") return ;;
    +|new|neu)
      _proj_new_interactive
      ;;
    p|P)
      (( page > 1 )) && _proj_menu_paginated $(( page - 1 ))
      ;;
    w|W)
      (( page < total_pages )) && _proj_menu_paginated $(( page + 1 ))
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
        # Smart match: search existing projects
        local -a results
        results=("${(@f)$(_proj_search_projects "$choice")}")
        results=(${results:#})  # filter empty

        if (( ${#results} == 1 )); then
          local match_name="${results[1]#*|}"
          _proj_ui_info "Match: ${_PC_WHITE}${_PC_BOLD}${match_name}${_PC_RESET}"
          _proj_use "$match_name"
        elif (( ${#results} > 1 )); then
          echo ""
          _proj_ui_subheader "Matches for \"$choice\""
          echo ""
          local midx=0
          for entry in "${results[@]}"; do
            midx=$((midx + 1))
            local mname="${entry#*|}"
            echo "  ${_PC_DIM}${midx})${_PC_RESET} ${_PC_WHITE}${_PC_BOLD}${mname}${_PC_RESET}"
          done
          echo ""
          read "msel?  ${_PC_CYAN}>${_PC_RESET} "
          if [[ "$msel" =~ ^[0-9]+$ ]] && (( msel >= 1 && msel <= ${#results} )); then
            local sel_name="${results[$msel]#*|}"
            _proj_use "$sel_name"
          fi
        else
          echo ""
          _proj_ui_warn "No project matching \"${_PC_WHITE}${choice}${_PC_RESET}${_PC_YELLOW}\"."
          read "yn?  Create it? ${_PC_DIM}[y/N]${_PC_RESET} "
          if [[ "$yn" == [yY] ]]; then
            _proj_new_interactive_with_name "$choice"
          fi
        fi
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

  _proj_new_interactive_with_name "$name"
}

_proj_new_interactive_with_name() {
  local name="$1"

  # Offer templates
  if (( ${#PROJ_TEMPLATES} > 0 )); then
    echo "  ${_PC_DIM}Templates:${_PC_RESET} ${_PC_BOLD}${(kj:, :)PROJ_TEMPLATES}${_PC_RESET}${_PC_DIM}, none${_PC_RESET}"
    read "tpl?  ${_PC_CYAN}Template ${_PC_DIM}[enter=none]:${_PC_RESET} "
  fi

  if [[ -n "$tpl" && "$tpl" != "none" && -n "${PROJ_TEMPLATES[$tpl]}" ]]; then
    _proj_use "$name" -t "$tpl"
  else
    echo "  ${_PC_DIM}Colors: ${_PC_GREEN}green${_PC_RESET} ${_PC_BLUE}blue${_PC_RESET} ${_PC_CYAN}cyan${_PC_RESET} ${_PC_RED}red${_PC_RESET} ${_PC_ORANGE}orange${_PC_RESET} ${_PC_YELLOW}yellow${_PC_RESET} ${_PC_PURPLE}purple${_PC_RESET} ${_PC_PINK}pink${_PC_RESET} ${_PC_GRAY}gray${_PC_RESET}"
    read "color?  ${_PC_CYAN}Color ${_PC_DIM}[enter=cyan]:${_PC_RESET} "
    [[ -z "$color" ]] && color="cyan"
    _proj_use "$name" "$color"
  fi
}
