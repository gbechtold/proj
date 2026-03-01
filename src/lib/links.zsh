# proj/lib/links.zsh — Link management
# Part of proj · Project Hub in your Terminal

# ─── Known Link Types ────────────────────────────────────────
typeset -ga _PROJ_LINK_TYPES
_PROJ_LINK_TYPES=(
  "live:Live Website"
  "staging:Staging"
  "dev:Dev Environment"
  "clickup:ClickUp"
  "moco-kunde:Moco Client"
  "moco-auftrag:Moco Project"
  "gmail:Gmail Search"
  "github:GitHub"
  "claude:Claude Code Path"
  "codex:Codex Path"
  "server:Server Login"
  "ssh:SSH Connection"
  "cloudways:Cloudways Panel"
  "facebook-ads:Facebook Ads"
  "google-ads:Google Ads"
  "analytics:Analytics"
  "1password:1Password Vault"
  "custom:Custom Link"
)

# ─── Link Type Helpers ────────────────────────────────────────

# Resolve type name: exact match, then unique prefix match
_proj_link_resolve_type() {
  local input="${1:l}"
  for entry in "${_PROJ_LINK_TYPES[@]}"; do
    local key="${entry%%:*}"
    [[ "$key" == "$input" ]] && echo "$key" && return
  done
  local -a matches
  for entry in "${_PROJ_LINK_TYPES[@]}"; do
    local key="${entry%%:*}"
    [[ "$key" == ${input}* ]] && matches+=("$key")
  done
  (( ${#matches} == 1 )) && echo "${matches[1]}"
}

_proj_link_type_list() {
  local -a names
  for entry in "${_PROJ_LINK_TYPES[@]}"; do
    names+=("${entry%%:*}")
  done
  echo "${(j:, :)names}"
}

# ─── Open Links Menu ────────────────────────────────────────

_proj_open() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  local direct="$1"

  local -a keys
  keys=("${(@f)$(_proj_py "$file" list-keys links)}")
  keys=(${keys:#})

  if (( ${#keys} == 0 )); then
    _proj_ui_header "Links: $_PROJ_CURRENT"
    echo "  ${_PC_DIM}No links yet${_PC_RESET}"
    echo ""
    echo "  ${_PC_DIM}[+] Add link  |  [q] Back${_PC_RESET}"
    echo ""
    read "choice?  ${_PC_CYAN}>${_PC_RESET} "
    [[ "$choice" == "+" || "$choice" == "a" ]] && _proj_link_add
    return
  fi

  # Direct open by number or type
  if [[ -n "$direct" ]]; then
    if [[ "$direct" =~ ^[0-9]+$ ]]; then
      local idx=$((direct))
      if (( idx >= 1 && idx <= ${#keys} )); then
        local key="${keys[$idx]}"
        local url=$(_proj_json_get "$file" links "$key")
        _proj_open_url "$key" "$url"
        return
      fi
    else
      local url=$(_proj_json_get "$file" links "$direct")
      if [[ -n "$url" ]]; then
        _proj_open_url "$direct" "$url"
        return
      fi
    fi
    _proj_ui_error "Link not found: $direct"
    _proj_ui_hint "proj open ${_PU_ARROW} list links  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj link add ${_PU_ARROW} add"
    return 1
  fi

  # fzf mode for link selection
  if _proj_has_fzf; then
    local -a fzf_entries
    for key in "${keys[@]}"; do
      local url=$(_proj_json_get "$file" links "$key")
      local label=$(_proj_ui_link_label "$key")
      fzf_entries+=("${key}|${label}|${url}")
    done
    local selected=$(printf '%s\n' "${fzf_entries[@]}" | \
      fzf --delimiter='|' \
          --with-nth=2,3 \
          --height=40% \
          --reverse \
          --border \
          --prompt="open> " \
          --header="Select link to open" 2>/dev/null)
    if [[ -n "$selected" ]]; then
      local sel_key=$(echo "$selected" | cut -d'|' -f1)
      local sel_url=$(echo "$selected" | cut -d'|' -f3)
      _proj_open_url "$sel_key" "$sel_url"
    fi
    return
  fi

  # Interactive menu (no fzf)
  _proj_ui_header "Links: $_PROJ_CURRENT"

  local idx=0
  for key in "${keys[@]}"; do
    idx=$((idx + 1))
    local url=$(_proj_json_get "$file" links "$key")
    local icon=$(_proj_ui_link_icon "$key")
    local label=$(_proj_ui_link_label "$key")
    printf "  ${_PC_DIM}%2d) %s %-14s${_PC_RESET} ${_PC_WHITE}%s${_PC_RESET}\n" "$idx" "$icon" "$label" "$url"
  done

  echo ""
  _proj_ui_separator
  echo "  ${_PC_DIM}[#] Open  |  [+] Add  |  [-] Remove  |  [q] Back${_PC_RESET}"
  echo ""

  read "choice?  ${_PC_CYAN}>${_PC_RESET} "

  case "$choice" in
    q|Q|"") return ;;
    +|a) _proj_link_add ;;
    -)
      read "rmidx?  ${_PC_CYAN}Remove #:${_PC_RESET} "
      if [[ "$rmidx" =~ ^[0-9]+$ ]] && (( rmidx >= 1 && rmidx <= ${#keys} )); then
        local rmkey="${keys[$rmidx]}"
        _proj_py "$file" delete-nested links "$rmkey" >/dev/null
        _proj_ui_success "Removed: $rmkey"
      fi
      ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#keys} )); then
        local key="${keys[$choice]}"
        local url=$(_proj_json_get "$file" links "$key")
        _proj_open_url "$key" "$url"
      else
        _proj_ui_error "Invalid selection"
      fi
      ;;
  esac
}

# ─── Link Management ────────────────────────────────────────

_proj_link() {
  local subcmd="${1:-add}"
  shift 2>/dev/null

  case "$subcmd" in
    add|a) _proj_link_add "$@" ;;
    rm|remove|r) _proj_link_rm "$@" ;;
    *) _proj_ui_error "Usage: proj link add|rm" ;;
  esac
}

_proj_link_add() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  local link_type="$1"
  local link_url="$2"

  # Resolve type if given
  if [[ -n "$link_type" ]]; then
    local resolved=$(_proj_link_resolve_type "$link_type")
    if [[ -z "$resolved" ]]; then
      _proj_ui_error "Unknown link type: $link_type"
      echo "  ${_PC_DIM}Types: $(_proj_link_type_list)${_PC_RESET}"
      return 1
    fi
    link_type="$resolved"
  fi

  # Quick-add: both args → save directly
  if [[ -n "$link_type" && -n "$link_url" ]]; then
    _proj_py "$file" set-nested links "$link_type" "$link_url" >/dev/null
    _proj_ui_success "$(_proj_ui_link_label "$link_type") ${_PU_ARROW} ${_PC_WHITE}$link_url${_PC_RESET}"
    return
  fi

  # Type given, no URL → prompt for URL only
  if [[ -n "$link_type" ]]; then
    case "$link_type" in
      gmail)        read "link_url?  ${_PC_CYAN}Search term:${_PC_RESET} " ;;
      claude|codex) read "link_url?  ${_PC_CYAN}Project path:${_PC_RESET} " ;;
      ssh)          read "link_url?  ${_PC_CYAN}SSH command:${_PC_RESET} " ;;
      *)            read "link_url?  ${_PC_CYAN}URL:${_PC_RESET} " ;;
    esac
    [[ -z "$link_url" ]] && _proj_ui_warn "Cancelled" && return
    _proj_py "$file" set-nested links "$link_type" "$link_url" >/dev/null
    _proj_ui_success "$(_proj_ui_link_label "$link_type") ${_PU_ARROW} ${_PC_WHITE}$link_url${_PC_RESET}"
    return
  fi

  # No args → interactive wizard
  echo ""
  _proj_ui_subheader "Add Link to $_PROJ_CURRENT"
  echo ""

  local idx=0
  for entry in "${_PROJ_LINK_TYPES[@]}"; do
    idx=$((idx + 1))
    local key="${entry%%:*}"
    local label="${entry#*:}"
    local icon=$(_proj_ui_link_icon "$key")
    printf "  ${_PC_DIM}%2d)${_PC_RESET} %s %s\n" "$idx" "$icon" "$label"
  done

  echo ""
  read "tidx?  ${_PC_CYAN}Type #:${_PC_RESET} "
  [[ -z "$tidx" ]] && return

  if [[ "$tidx" =~ ^[0-9]+$ ]] && (( tidx >= 1 && tidx <= ${#_PROJ_LINK_TYPES} )); then
    local entry="${_PROJ_LINK_TYPES[$tidx]}"
    link_type="${entry%%:*}"
  else
    link_type="$tidx"
  fi

  case "$link_type" in
    gmail)        read "link_url?  ${_PC_CYAN}Search term:${_PC_RESET} " ;;
    claude|codex) read "link_url?  ${_PC_CYAN}Project path:${_PC_RESET} " ;;
    ssh)          read "link_url?  ${_PC_CYAN}SSH command (e.g. ssh user@host):${_PC_RESET} " ;;
    *)            read "link_url?  ${_PC_CYAN}URL:${_PC_RESET} " ;;
  esac

  [[ -z "$link_url" ]] && _proj_ui_warn "Cancelled" && return

  _proj_py "$file" set-nested links "$link_type" "$link_url"
  _proj_ui_success "$(_proj_ui_link_label "$link_type") ${_PU_ARROW} ${_PC_WHITE}$link_url${_PC_RESET}"
}

_proj_link_rm() {
  [[ -z "$_PROJ_CURRENT" ]] && _proj_ui_error "No active project." && return 1

  local link_type="$1"
  [[ -z "$link_type" ]] && _proj_ui_error "Usage: proj link rm <type>" && return 1

  local file=$(_proj_file "$_PROJ_CURRENT")
  _proj_py "$file" delete-nested links "$link_type" >/dev/null
  _proj_ui_success "Link removed: $link_type"
}

# ─── URL Opener ──────────────────────────────────────────────

_proj_open_url() {
  local type="$1"
  local url="$2"

  # Empty URL (template placeholder)
  if [[ -z "$url" ]]; then
    _proj_ui_warn "No URL set for $(_proj_ui_link_label "$type")"
    _proj_ui_hint "proj link add $type <url> ${_PU_ARROW} set URL"
    return
  fi

  # Special handling for Gmail
  if [[ "$type" == "gmail" ]]; then
    local encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$url'))")
    url="https://mail.google.com/mail/u/0/#search/${encoded}"
  fi

  # claude/codex paths — don't open in browser
  if [[ "$type" == "claude" || "$type" == "codex" ]]; then
    _proj_ui_info "Path: ${_PC_WHITE}${_PC_BOLD}$url${_PC_RESET}"
    _proj_ui_hint "proj $type ${_PU_ARROW} start AI session"
    return
  fi

  # SSH — copy to clipboard + show
  if [[ "$type" == "ssh" ]]; then
    echo "$url" | pbcopy
    _proj_ui_info "SSH: ${_PC_WHITE}${_PC_BOLD}$url${_PC_RESET}"
    _proj_ui_success "Copied to clipboard"
    return
  fi

  _proj_ui_info "Opening: ${_PC_WHITE}$url${_PC_RESET}"
  open "$url" 2>/dev/null
}
