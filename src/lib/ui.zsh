# proj/lib/ui.zsh — Colors, formatting, and eye candy
# Part of proj · Project Hub in your Terminal

# ─── Color Palette ──────────────────────────────────────────
typeset -g _PC_RESET=$'\033[0m'
typeset -g _PC_BOLD=$'\033[1m'
typeset -g _PC_DIM=$'\033[2m'
typeset -g _PC_ITALIC=$'\033[3m'
typeset -g _PC_UNDER=$'\033[4m'

# Vibrant 256-color palette
typeset -g _PC_RED=$'\033[38;5;203m'
typeset -g _PC_GREEN=$'\033[38;5;114m'
typeset -g _PC_YELLOW=$'\033[38;5;221m'
typeset -g _PC_BLUE=$'\033[38;5;111m'
typeset -g _PC_PURPLE=$'\033[38;5;141m'
typeset -g _PC_CYAN=$'\033[38;5;80m'
typeset -g _PC_ORANGE=$'\033[38;5;209m'
typeset -g _PC_PINK=$'\033[38;5;211m'
typeset -g _PC_GRAY=$'\033[38;5;243m'
typeset -g _PC_WHITE=$'\033[38;5;255m'
typeset -g _PC_LIME=$'\033[38;5;156m'
typeset -g _PC_SKY=$'\033[38;5;117m'

# Background accents
typeset -g _PC_BG_DIM=$'\033[48;5;236m'

# ─── Unicode Glyphs ─────────────────────────────────────────
typeset -g _PU_DOT='·'
typeset -g _PU_ARROW='→'
typeset -g _PU_CHECK='✓'
typeset -g _PU_CROSS='✗'
typeset -g _PU_CLOCK='◷'
typeset -g _PU_PLAY='▶'
typeset -g _PU_STOP='■'
typeset -g _PU_STAR='★'
typeset -g _PU_BULLET='●'
typeset -g _PU_DIAMOND='◆'
typeset -g _PU_LINK='⟶'
typeset -g _PU_TIMER='⏱'
typeset -g _PU_SPARK='✦'
typeset -g _PU_ROCKET='🚀'
typeset -g _PU_FOLDER='📂'
typeset -g _PU_BRAIN='🧠'

# Box drawing
typeset -g _PU_H='─'
typeset -g _PU_V='│'
typeset -g _PU_TL='╭'
typeset -g _PU_TR='╮'
typeset -g _PU_BL='╰'
typeset -g _PU_BR='╯'
typeset -g _PU_HDbl='═'

# ─── Output Helpers ──────────────────────────────────────────

_proj_ui_header() {
  local text="$1"
  local color="${2:-$_PC_DIM}"
  local width=45
  local pad=$(( (width - ${#text} - 2) / 2 ))
  local lpad=$(printf '%*s' "$pad" '' | tr ' ' "$_PU_HDbl")
  local rpad=$(printf '%*s' "$(( width - ${#text} - 2 - pad ))" '' | tr ' ' "$_PU_HDbl")
  echo ""
  echo "${_PC_DIM}${lpad}${_PC_RESET} ${_PC_WHITE}${_PC_BOLD}${text}${_PC_RESET} ${_PC_DIM}${rpad}${_PC_RESET}"
  echo ""
}

_proj_ui_subheader() {
  local text="$1"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET} ${_PC_BOLD}${text}${_PC_RESET}"
}

_proj_ui_separator() {
  local width=${1:-45}
  echo "  ${_PC_DIM}$(printf '%*s' "$width" '' | tr ' ' "$_PU_H")${_PC_RESET}"
}

_proj_ui_success() {
  echo "  ${_PC_GREEN}${_PU_CHECK}${_PC_RESET} $1"
}

_proj_ui_error() {
  echo "  ${_PC_RED}${_PU_CROSS}${_PC_RESET} $1"
}

_proj_ui_info() {
  echo "  ${_PC_CYAN}${_PU_BULLET}${_PC_RESET} $1"
}

_proj_ui_warn() {
  echo "  ${_PC_YELLOW}${_PU_DIAMOND}${_PC_RESET} $1"
}

# Contextual shortcut hint — shown after actions
_proj_ui_hint() {
  echo ""
  echo "  ${_PC_DIM}${_PU_SPARK} $1${_PC_RESET}"
}

# Prompt with color
_proj_ui_prompt() {
  local label="${1:->}"
  echo -n "  ${_PC_CYAN}${label}${_PC_RESET} "
}

# Pretty project line for menus
# Usage: _proj_ui_project_line <num> <name> <color> <task> <active> <timer>
_proj_ui_project_line() {
  local num="$1" name="$2" color="$3" task="$4" active="$5" timer="$6"

  # Map project color to terminal color
  local cc=""
  case "$color" in
    green)  cc="$_PC_GREEN" ;;
    blue)   cc="$_PC_BLUE" ;;
    cyan)   cc="$_PC_CYAN" ;;
    red)    cc="$_PC_RED" ;;
    orange) cc="$_PC_ORANGE" ;;
    yellow) cc="$_PC_YELLOW" ;;
    purple) cc="$_PC_PURPLE" ;;
    pink)   cc="$_PC_PINK" ;;
    gray)   cc="$_PC_GRAY" ;;
    *)      cc="$_PC_WHITE" ;;
  esac

  local marker=""
  [[ -n "$active" ]] && marker=" ${_PC_GREEN}${_PU_BULLET}${_PC_RESET}"
  [[ -n "$timer" ]] && marker="${marker} ${_PC_RED}${_PU_TIMER}${_PC_RESET}"

  local task_display=""
  [[ -n "$task" ]] && task_display=" ${_PC_DIM}${_PU_DOT} ${task}${_PC_RESET}"

  printf "  ${_PC_DIM}%2s)${_PC_RESET} ${_PC_WHITE}${_PC_BOLD}%-18s${_PC_RESET}${task_display}${marker}\n" "$num" "$name"
}

# Banner — shown on first use or proj --version
_proj_ui_banner() {
  echo ""
  echo "  ${_PC_CYAN}${_PU_TL}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_TR}${_PC_RESET}"
  echo "  ${_PC_CYAN}${_PU_V}${_PC_RESET}  ${_PU_ROCKET} ${_PC_BOLD}proj${_PC_RESET} ${_PC_DIM}${_PU_DOT} Project Hub in your Terminal${_PC_RESET}  ${_PC_CYAN}${_PU_V}${_PC_RESET}"
  echo "  ${_PC_CYAN}${_PU_BL}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_BR}${_PC_RESET}"
  echo ""
}

# Link type icons
_proj_ui_link_icon() {
  case "$1" in
    live)         echo "🌐" ;;
    staging)      echo "🔧" ;;
    dev)          echo "🛠" ;;
    clickup)      echo "📋" ;;
    moco-kunde)   echo "💼" ;;
    moco-auftrag) echo "💰" ;;
    gmail)        echo "📧" ;;
    claude)       echo "🧠" ;;
    codex)        echo "⚡" ;;
    github)       echo "🐙" ;;
    server)       echo "🖥" ;;
    ssh)          echo "🔑" ;;
    cloudways)    echo "☁️" ;;
    facebook-ads) echo "📣" ;;
    google-ads)   echo "📢" ;;
    analytics)    echo "📊" ;;
    1password)    echo "🔐" ;;
    *)            echo "🔗" ;;
  esac
}

# Link type labels
_proj_ui_link_label() {
  case "$1" in
    live)         echo "Live" ;;
    staging)      echo "Staging" ;;
    dev)          echo "Dev" ;;
    clickup)      echo "ClickUp" ;;
    moco-kunde)   echo "Moco Client" ;;
    moco-auftrag) echo "Moco Project" ;;
    gmail)        echo "Gmail" ;;
    claude)       echo "Claude Code" ;;
    codex)        echo "Codex" ;;
    github)       echo "GitHub" ;;
    server)       echo "Server" ;;
    ssh)          echo "SSH" ;;
    cloudways)    echo "Cloudways" ;;
    facebook-ads) echo "Facebook Ads" ;;
    google-ads)   echo "Google Ads" ;;
    analytics)    echo "Analytics" ;;
    1password)    echo "1Password" ;;
    *)            echo "$1" ;;
  esac
}
