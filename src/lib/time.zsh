# proj/lib/time.zsh — Time tracking
# Part of proj · Project Hub in your Terminal

_proj_time() {
  local subcmd="${1:-status}"

  case "$subcmd" in
    start|s)  _proj_time_start ;;
    stop|x)   _proj_time_stop ;;
    log|l)    shift; _proj_time_log "$@" ;;
    status|?) _proj_time_status ;;
    *)        _proj_ui_error "Usage: proj time start|stop|log|status" ;;
  esac
}

# ─── Start Timer ─────────────────────────────────────────────

_proj_time_start() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  local result=$(_proj_py "$file" time-start)

  case "$result" in
    started:*)
      local ts="${result#started:}"
      echo ""
      echo "  ${_PC_GREEN}${_PU_PLAY}${_PC_RESET}  Timer started: ${_PC_BOLD}${ts#*T}${_PC_RESET} ${_PC_DIM}${_PU_DOT} ${_PROJ_CURRENT}${_PC_RESET}"
      _proj_ui_hint "proj time stop ${_PU_ARROW} stop timer  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj time log ${_PU_ARROW} view log"
      ;;
    running:*)
      local ts="${result#running:}"
      _proj_ui_warn "Timer already running since ${_PC_BOLD}${ts#*T}${_PC_RESET}"
      _proj_ui_hint "proj time stop ${_PU_ARROW} stop first"
      ;;
  esac
}

# ─── Stop Timer ──────────────────────────────────────────────

_proj_time_stop() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  local result=$(_proj_py "$file" time-stop)

  case "$result" in
    stopped:*)
      # Format: stopped:start:stop:duration
      local parts=("${(@s/:/)result}")
      # Reconstruct properly (timestamps have colons)
      local duration=$(echo "$result" | python3 -c "
import sys
parts = sys.stdin.read().strip().split(':')
# Last two parts before 'm' are the duration components
# Format: stopped:YYYY-MM-DDTHH:MM:SS:YYYY-MM-DDTHH:MM:SS:Xh Ym
text = ':'.join(parts[1:])
# Find the last duration part
segs = text.rsplit(':', 1)
print(segs[-1])
")
      echo ""
      echo "  ${_PC_RED}${_PU_STOP}${_PC_RESET}  Timer stopped ${_PC_DIM}${_PU_DOT} ${_PROJ_CURRENT}${_PC_RESET}"
      echo "  ${_PC_DIM}   Duration:${_PC_RESET} ${_PC_BOLD}${duration}${_PC_RESET}"
      _proj_ui_hint "proj time log ${_PU_ARROW} view log  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj time start ${_PU_ARROW} restart"
      ;;
    no_timer)
      _proj_ui_warn "No timer running"
      _proj_ui_hint "proj time start ${_PU_ARROW} start timer"
      ;;
  esac
}

# ─── Timer Status ────────────────────────────────────────────

_proj_time_status() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  local result=$(_proj_py "$file" time-status)

  case "$result" in
    running:*)
      local info="${result#running:}"
      local started="${info%%:*}"
      local elapsed="${info##*:}"
      echo ""
      echo "  ${_PC_RED}${_PU_TIMER}${_PC_RESET}  ${_PC_BOLD}Timer running${_PC_RESET} ${_PC_DIM}${_PU_DOT} ${_PROJ_CURRENT}${_PC_RESET}"
      echo "  ${_PC_DIM}   Started:${_PC_RESET}  ${started#*T}"
      echo "  ${_PC_DIM}   Elapsed:${_PC_RESET}  ${_PC_BOLD}${elapsed}${_PC_RESET}"
      ;;
    idle)
      echo "  ${_PC_DIM}${_PU_CLOCK} No timer running for ${_PROJ_CURRENT}${_PC_RESET}"
      _proj_ui_hint "proj time start ${_PU_ARROW} start timer"
      ;;
  esac
}

# ─── Time Log ────────────────────────────────────────────────

_proj_time_log() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local days="${1:-30}"
  local file=$(_proj_file "$_PROJ_CURRENT")

  _proj_ui_header "Time Log: $_PROJ_CURRENT" "$_PC_PURPLE"

  local log_output=$(_proj_py "$file" time-log "$days")

  if [[ -z "$log_output" || "$log_output" == "TOTAL|0h 00m|0 entries" ]]; then
    echo "  ${_PC_DIM}No time entries in the last ${days} days${_PC_RESET}"
    _proj_ui_hint "proj time start ${_PU_ARROW} start tracking"
    return
  fi

  # Header
  printf "  ${_PC_DIM}%-12s  %-6s  %-8s  %s${_PC_RESET}\n" "Date" "Start" "Stop" "Duration"
  _proj_ui_separator 42

  local prev_date=""
  while IFS='|' read -r date start stop duration; do
    # Total line
    if [[ "$date" == "TOTAL" ]]; then
      _proj_ui_separator 42
      printf "  ${_PC_BOLD}%-12s  %16s  %s${_PC_RESET}\n" "" "" "$start"
      echo "  ${_PC_DIM}${stop}${_PC_RESET}"
      continue
    fi

    # Date grouping — show date only on change
    local show_date="$date"
    [[ "$date" == "$prev_date" ]] && show_date=""
    prev_date="$date"

    local stop_display="$stop"
    local dur_color="$_PC_RESET"
    if [[ "$stop" == "running" ]]; then
      stop_display="${_PC_RED}${_PU_PLAY} now${_PC_RESET}"
      dur_color="$_PC_RED"
    fi

    printf "  %-12s  ${_PC_CYAN}%-6s${_PC_RESET}  %-8b  ${dur_color}%s${_PC_RESET}\n" "$show_date" "$start" "$stop_display" "$duration"
  done <<< "$log_output"

  echo ""
}
