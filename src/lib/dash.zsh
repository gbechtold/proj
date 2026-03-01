# proj/lib/dash.zsh — Cross-project dashboard
# Part of proj · Project Hub in your Terminal

_proj_dash() {
  _proj_ui_header "Dashboard"

  local dash_output=$(_proj_py "$PROJ_DIR/_" dash-data "$PROJ_DIR")

  local -a timers doing recent
  local summary=""

  while IFS='|' read -r type arg1 arg2 arg3 arg4; do
    case "$type" in
      TIMER)  timers+=("$arg1|$arg2|$arg3|$arg4") ;;
      DOING)  doing+=("$arg1|$arg2|$arg3") ;;
      RECENT) recent+=("$arg1|$arg2|$arg3") ;;
      SUMMARY) summary="$arg1|$arg2|$arg3" ;;
    esac
  done <<< "$dash_output"

  # Running timers
  if (( ${#timers} > 0 )); then
    echo "  ${_PC_RED}${_PU_TIMER}${_PC_RESET} ${_PC_BOLD}Running Timers${_PC_RESET}"
    for entry in "${timers[@]}"; do
      IFS='|' read -r name color elapsed task <<< "$entry"
      local cc=$(_proj_color_code "$color")
      printf "  ${cc}${_PU_BULLET}${_PC_RESET} ${_PC_WHITE}${_PC_BOLD}%-18s${_PC_RESET} ${_PC_CYAN}%s${_PC_RESET}" "$name" "$elapsed"
      [[ -n "$task" ]] && printf "  ${_PC_DIM}${_PU_DOT} %s${_PC_RESET}" "$task"
      echo ""
    done
    echo ""
  fi

  # Active tasks
  if (( ${#doing} > 0 )); then
    echo "  ${_PC_YELLOW}${_PU_PLAY}${_PC_RESET} ${_PC_BOLD}Active Tasks${_PC_RESET}"
    for entry in "${doing[@]}"; do
      IFS='|' read -r name color task <<< "$entry"
      local cc=$(_proj_color_code "$color")
      printf "  ${cc}${_PU_BULLET}${_PC_RESET} ${_PC_WHITE}${_PC_BOLD}%-18s${_PC_RESET} ${_PC_DIM}%s${_PC_RESET}\n" "$name" "$task"
    done
    echo ""
  fi

  # No timers and no tasks
  if (( ${#timers} == 0 && ${#doing} == 0 )); then
    echo "  ${_PC_DIM}No running timers or active tasks${_PC_RESET}"
    echo ""
  fi

  # Recently active (top 5)
  if (( ${#recent} > 0 )); then
    echo "  ${_PC_DIM}${_PU_CLOCK} Recent${_PC_RESET}"
    local sorted=$(printf '%s\n' "${recent[@]}" | sort -t'|' -k3 -r | head -5)
    while IFS='|' read -r name color updated; do
      local cc=$(_proj_color_code "$color")
      printf "  ${cc}${_PU_DOT}${_PC_RESET} ${_PC_DIM}%-18s %s${_PC_RESET}\n" "$name" "${updated%T*}"
    done <<< "$sorted"
    echo ""
  fi

  # Summary
  if [[ -n "$summary" ]]; then
    IFS='|' read -r week_time today_time proj_count <<< "$summary"
    _proj_ui_separator
    echo "  ${_PC_DIM}Today:${_PC_RESET} ${_PC_WHITE}${_PC_BOLD}${today_time}${_PC_RESET}  ${_PC_DIM}${_PU_DOT}  Week:${_PC_RESET} ${_PC_WHITE}${_PC_BOLD}${week_time}${_PC_RESET} ${_PC_DIM}across ${proj_count} projects${_PC_RESET}"
  fi

  echo ""
}
