# ╔══════════════════════════════════════════════════════════════╗
# ║  proj · Project Hub in your Terminal                        ║
# ║  https://github.com/gbechtold/proj                         ║
# ╚══════════════════════════════════════════════════════════════╝

PROJ_DIR="${PROJ_DATA_DIR:-$HOME/.config/proj/projects}"
PROJ_ROOT="${${(%):-%x}:A:h}"
PROJ_PY="$PROJ_ROOT/proj_helper.py"

[[ -d "$PROJ_DIR" ]] || mkdir -p "$PROJ_DIR"

# ─── Source Libraries ────────────────────────────────────────
for _proj_lib in "$PROJ_ROOT"/lib/*.zsh(N); do
  source "$_proj_lib"
done
unset _proj_lib

# ─── Main Function ──────────────────────────────────────────

proj() {
  local cmd="${1:-menu}"

  case "$cmd" in
    # Interactive
    menu|m)         _proj_menu ;;

    # Project management
    use|u)          shift; _proj_use "$@" ;;
    info|i)         _proj_info ;;
    path|p)         shift; _proj_path "$@" ;;
    cd)             _proj_cd ;;
    list|ls|l)      _proj_list ;;
    clear|x)        _proj_clear ;;
    rm)             shift; _proj_rm "$@" ;;

    # Content
    task|t)         shift; _proj_task "$@" ;;
    note|n)         shift; _proj_note_dispatch "$@" ;;
    notes)          _proj_notes ;;
    notes-clear|nc) _proj_notes_clear ;;
    color|c)        shift; _proj_color "$@" ;;

    # Dashboard & Templates
    dash|status|d)  _proj_dash ;;
    templates|tpl)  _proj_templates ;;

    # Links
    open|o)         shift; _proj_open "$@" ;;
    link)           shift; _proj_link "$@" ;;

    # Time tracking
    time|ti)        shift; _proj_time "$@" ;;

    # AI
    claude|cl)      shift; _proj_ai "claude" "$@" ;;
    codex|cx)       shift; _proj_ai "codex" "$@" ;;

    # Stars integration (workflow engine)
    sessions|ss)    _proj_sessions ;;
    sync)           shift; _proj_sync "$@" ;;
    deploy)         shift; _proj_deploy "$@" ;;
    report)         shift; _proj_report "$@" ;;

    # Utilities
    demo)           _proj_create_demos ;;
    migrate)        _proj_migrate_conf ;;
    version|v)      _proj_ui_banner ;;
    help|h|'?')     shift 2>/dev/null; _proj_help "$@" ;;

    *) _proj_ui_error "Unknown: $cmd" && _proj_ui_hint "proj help ${_PU_ARROW} commands" ;;
  esac
}

# ─── Help ────────────────────────────────────────────────────

_proj_help() {
  local topic="$1"

  # Per-command help
  if [[ -n "$topic" ]]; then
    _proj_help_command "$topic"
    return
  fi

  # Context-aware: no project active → getting started
  if [[ -z "$_PROJ_CURRENT" ]]; then
    _proj_ui_banner
    echo "  ${_PC_BOLD}Getting Started${_PC_RESET}"
    echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
    echo "  ${_PC_CYAN}proj${_PC_RESET}                              ${_PC_DIM}Interactive menu${_PC_RESET}"
    echo "  ${_PC_CYAN}proj use${_PC_RESET} ${_PC_WHITE}<name>${_PC_RESET} ${_PC_DIM}[color]${_PC_RESET}         ${_PC_DIM}Activate / create project${_PC_RESET}"
    echo "  ${_PC_CYAN}proj use${_PC_RESET} ${_PC_WHITE}<name>${_PC_RESET} ${_PC_DIM}-t <tpl>${_PC_RESET}       ${_PC_DIM}Create from template${_PC_RESET}"
    echo "  ${_PC_CYAN}proj list${_PC_RESET}                             ${_PC_DIM}All projects${_PC_RESET}"
    echo "  ${_PC_CYAN}proj dash${_PC_RESET}                             ${_PC_DIM}Cross-project overview${_PC_RESET}"
    echo "  ${_PC_CYAN}proj templates${_PC_RESET}                        ${_PC_DIM}Available templates${_PC_RESET}"
    echo "  ${_PC_CYAN}proj demo${_PC_RESET}                             ${_PC_DIM}Load demo data${_PC_RESET}"
    echo ""
    echo "  ${_PC_DIM}proj help all ${_PU_ARROW} full command reference${_PC_RESET}"
    echo ""
    return
  fi

  # Project active → working commands
  echo ""
  echo "  ${_PC_BOLD}Working: ${_PC_WHITE}$_PROJ_CURRENT${_PC_RESET}"
  echo ""
  echo "  ${_PC_BOLD}Project${_PC_RESET}                            ${_PC_BOLD}Content${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}                            ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}info${_PC_RESET}   ${_PC_DIM}i${_PC_RESET}    ${_PC_DIM}Details${_PC_RESET}                ${_PC_CYAN}task${_PC_RESET}  ${_PC_DIM}t${_PC_RESET}  ${_PC_DIM}Manage tasks${_PC_RESET}"
  echo "  ${_PC_CYAN}open${_PC_RESET}   ${_PC_DIM}o${_PC_RESET}    ${_PC_DIM}Links${_PC_RESET}                  ${_PC_CYAN}note${_PC_RESET}  ${_PC_DIM}n${_PC_RESET}  ${_PC_DIM}Notes${_PC_RESET}"
  echo "  ${_PC_CYAN}path${_PC_RESET}   ${_PC_DIM}p${_PC_RESET}    ${_PC_DIM}Directory${_PC_RESET}              ${_PC_CYAN}color${_PC_RESET} ${_PC_DIM}c${_PC_RESET}  ${_PC_DIM}Tab color${_PC_RESET}"
  echo "  ${_PC_CYAN}cd${_PC_RESET}          ${_PC_DIM}Jump to dir${_PC_RESET}"
  echo ""
  echo "  ${_PC_BOLD}Time${_PC_RESET}                               ${_PC_BOLD}AI${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}                               ${_PC_DIM}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}time start${_PC_RESET}  ${_PC_DIM}Timer on${_PC_RESET}              ${_PC_CYAN}claude${_PC_RESET}   ${_PC_DIM}cl${_PC_RESET}  ${_PC_DIM}Claude Code${_PC_RESET}"
  echo "  ${_PC_CYAN}time stop${_PC_RESET}   ${_PC_DIM}Timer off${_PC_RESET}             ${_PC_CYAN}codex${_PC_RESET}    ${_PC_DIM}cx${_PC_RESET}  ${_PC_DIM}Codex${_PC_RESET}"
  echo "  ${_PC_CYAN}time log${_PC_RESET}    ${_PC_DIM}History${_PC_RESET}               ${_PC_CYAN}sessions${_PC_RESET} ${_PC_DIM}ss${_PC_RESET}  ${_PC_DIM}Sessions${_PC_RESET}"
  echo ""
  echo "  ${_PC_DIM}proj help all ${_PU_ARROW} full reference  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj help <cmd> ${_PU_ARROW} per-command${_PC_RESET}"
  echo ""
}

_proj_help_command() {
  local cmd="$1"
  case "$cmd" in
    all)
      _proj_help_full ;;
    task|t)
      echo ""
      echo "  ${_PC_BOLD}proj task${_PC_RESET} ${_PC_DIM}(t)${_PC_RESET}"
      echo ""
      echo "  ${_PC_CYAN}task${_PC_RESET} ${_PC_WHITE}<text>${_PC_RESET}          ${_PC_DIM}Quick-add task${_PC_RESET}"
      echo "  ${_PC_CYAN}task add${_PC_RESET} ${_PC_WHITE}<text>${_PC_RESET}      ${_PC_DIM}Add task${_PC_RESET}"
      echo "  ${_PC_CYAN}task do${_PC_RESET} ${_PC_WHITE}<#>${_PC_RESET}          ${_PC_DIM}Mark as active (doing)${_PC_RESET}"
      echo "  ${_PC_CYAN}task done${_PC_RESET} ${_PC_WHITE}<#>${_PC_RESET}        ${_PC_DIM}Mark as done${_PC_RESET}"
      echo "  ${_PC_CYAN}task rm${_PC_RESET} ${_PC_WHITE}<#>${_PC_RESET}          ${_PC_DIM}Remove task${_PC_RESET}"
      echo "  ${_PC_CYAN}task list${_PC_RESET}             ${_PC_DIM}Show all tasks${_PC_RESET}"
      echo ""
      ;;
    note|n)
      echo ""
      echo "  ${_PC_BOLD}proj note${_PC_RESET} ${_PC_DIM}(n)${_PC_RESET}"
      echo ""
      echo "  ${_PC_CYAN}note${_PC_RESET} ${_PC_WHITE}<text>${_PC_RESET}          ${_PC_DIM}Add note${_PC_RESET}"
      echo "  ${_PC_CYAN}note rm${_PC_RESET} ${_PC_WHITE}<#>${_PC_RESET}          ${_PC_DIM}Remove note${_PC_RESET}"
      echo "  ${_PC_CYAN}note edit${_PC_RESET} ${_PC_WHITE}<#> <text>${_PC_RESET}  ${_PC_DIM}Edit note${_PC_RESET}"
      echo "  ${_PC_CYAN}notes${_PC_RESET}                 ${_PC_DIM}Show all notes${_PC_RESET}"
      echo ""
      ;;
    link)
      echo ""
      echo "  ${_PC_BOLD}proj link${_PC_RESET}"
      echo ""
      echo "  ${_PC_CYAN}link add${_PC_RESET}                       ${_PC_DIM}Interactive wizard${_PC_RESET}"
      echo "  ${_PC_CYAN}link add${_PC_RESET} ${_PC_WHITE}<type>${_PC_RESET}               ${_PC_DIM}Add by type (prompts URL)${_PC_RESET}"
      echo "  ${_PC_CYAN}link add${_PC_RESET} ${_PC_WHITE}<type> <url>${_PC_RESET}          ${_PC_DIM}Quick-add${_PC_RESET}"
      echo "  ${_PC_CYAN}link rm${_PC_RESET} ${_PC_WHITE}<type>${_PC_RESET}                ${_PC_DIM}Remove link${_PC_RESET}"
      echo ""
      echo "  ${_PC_DIM}Types: $(_proj_link_type_list)${_PC_RESET}"
      echo ""
      ;;
    time|ti)
      echo ""
      echo "  ${_PC_BOLD}proj time${_PC_RESET} ${_PC_DIM}(ti)${_PC_RESET}"
      echo ""
      echo "  ${_PC_CYAN}time start${_PC_RESET}            ${_PC_DIM}Start timer${_PC_RESET}"
      echo "  ${_PC_CYAN}time stop${_PC_RESET}             ${_PC_DIM}Stop timer${_PC_RESET}"
      echo "  ${_PC_CYAN}time log${_PC_RESET} ${_PC_DIM}[days]${_PC_RESET}        ${_PC_DIM}Time log (default 30d)${_PC_RESET}"
      echo "  ${_PC_CYAN}time status${_PC_RESET}           ${_PC_DIM}Current timer${_PC_RESET}"
      echo ""
      ;;
    open|o)
      echo ""
      echo "  ${_PC_BOLD}proj open${_PC_RESET} ${_PC_DIM}(o)${_PC_RESET}"
      echo ""
      echo "  ${_PC_CYAN}open${_PC_RESET}                  ${_PC_DIM}Link menu (fzf if available)${_PC_RESET}"
      echo "  ${_PC_CYAN}open${_PC_RESET} ${_PC_WHITE}<#>${_PC_RESET}              ${_PC_DIM}Open by number${_PC_RESET}"
      echo "  ${_PC_CYAN}open${_PC_RESET} ${_PC_WHITE}<type>${_PC_RESET}            ${_PC_DIM}Open by type${_PC_RESET}"
      echo ""
      ;;
    *)
      _proj_ui_warn "No help for: $cmd"
      _proj_ui_hint "proj help all ${_PU_ARROW} full reference"
      ;;
  esac
}

_proj_help_full() {
  _proj_ui_banner

  echo "  ${_PC_BOLD}Quick Start${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}proj${_PC_RESET}                              ${_PC_DIM}Interactive menu${_PC_RESET}"
  echo "  ${_PC_CYAN}proj use${_PC_RESET} ${_PC_WHITE}<name>${_PC_RESET} ${_PC_DIM}[color]${_PC_RESET}         ${_PC_DIM}Activate project${_PC_RESET}"
  echo "  ${_PC_CYAN}proj use${_PC_RESET} ${_PC_WHITE}<name>${_PC_RESET} ${_PC_DIM}-t <tpl>${_PC_RESET}       ${_PC_DIM}Create from template${_PC_RESET}"
  echo ""

  echo "  ${_PC_BOLD}Project${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}info${_PC_RESET}  ${_PC_DIM}i${_PC_RESET}                          ${_PC_DIM}Project details${_PC_RESET}"
  echo "  ${_PC_CYAN}path${_PC_RESET}  ${_PC_DIM}p${_PC_RESET}  ${_PC_DIM}[dir]${_PC_RESET}                  ${_PC_DIM}Set/show directory${_PC_RESET}"
  echo "  ${_PC_CYAN}cd${_PC_RESET}                                ${_PC_DIM}Jump to directory${_PC_RESET}"
  echo "  ${_PC_CYAN}color${_PC_RESET} ${_PC_DIM}c${_PC_RESET}  ${_PC_DIM}<color>${_PC_RESET}                ${_PC_DIM}Change tab color${_PC_RESET}"
  echo "  ${_PC_CYAN}list${_PC_RESET}  ${_PC_DIM}ls${_PC_RESET}                         ${_PC_DIM}All projects${_PC_RESET}"
  echo "  ${_PC_CYAN}dash${_PC_RESET}  ${_PC_DIM}d${_PC_RESET}                          ${_PC_DIM}Cross-project dashboard${_PC_RESET}"
  echo "  ${_PC_CYAN}clear${_PC_RESET} ${_PC_DIM}x${_PC_RESET}                          ${_PC_DIM}Deactivate${_PC_RESET}"
  echo "  ${_PC_CYAN}rm${_PC_RESET}    ${_PC_DIM}<name>${_PC_RESET}                     ${_PC_DIM}Delete project${_PC_RESET}"
  echo ""

  echo "  ${_PC_BOLD}Tasks & Notes${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}task${_PC_RESET}  ${_PC_DIM}t${_PC_RESET}  ${_PC_DIM}<text>${_PC_RESET}                 ${_PC_DIM}Add task ${_PC_RESET}${_PC_DIM}(add/do/done/rm/list)${_PC_RESET}"
  echo "  ${_PC_CYAN}note${_PC_RESET}  ${_PC_DIM}n${_PC_RESET}  ${_PC_DIM}<text>${_PC_RESET}                 ${_PC_DIM}Add note ${_PC_RESET}${_PC_DIM}(rm/edit)${_PC_RESET}"
  echo "  ${_PC_CYAN}notes${_PC_RESET}                             ${_PC_DIM}Show notes${_PC_RESET}"
  echo ""

  echo "  ${_PC_BOLD}Links${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}open${_PC_RESET}  ${_PC_DIM}o${_PC_RESET}  ${_PC_DIM}[#|type]${_PC_RESET}               ${_PC_DIM}Open link${_PC_RESET}"
  echo "  ${_PC_CYAN}link add${_PC_RESET} ${_PC_DIM}[type] [url]${_PC_RESET}           ${_PC_DIM}Add link${_PC_RESET}"
  echo "  ${_PC_CYAN}link rm${_PC_RESET} ${_PC_DIM}<type>${_PC_RESET}                  ${_PC_DIM}Remove link${_PC_RESET}"
  echo ""

  echo "  ${_PC_BOLD}Time${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}time start${_PC_RESET}                        ${_PC_DIM}Start timer${_PC_RESET}"
  echo "  ${_PC_CYAN}time stop${_PC_RESET}                         ${_PC_DIM}Stop timer${_PC_RESET}"
  echo "  ${_PC_CYAN}time log${_PC_RESET}  ${_PC_DIM}[days]${_PC_RESET}                  ${_PC_DIM}Time log${_PC_RESET}"
  echo ""

  echo "  ${_PC_BOLD}AI & Workflow${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}claude${_PC_RESET}   ${_PC_DIM}cl${_PC_RESET}                      ${_PC_DIM}Claude Code${_PC_RESET}"
  echo "  ${_PC_CYAN}codex${_PC_RESET}    ${_PC_DIM}cx${_PC_RESET}                      ${_PC_DIM}Codex${_PC_RESET}"
  echo "  ${_PC_CYAN}sessions${_PC_RESET} ${_PC_DIM}ss${_PC_RESET}                      ${_PC_DIM}Claude sessions${_PC_RESET}"
  echo "  ${_PC_CYAN}sync${_PC_RESET}     ${_PC_DIM}[moco|clickup]${_PC_RESET}            ${_PC_DIM}Sync${_PC_RESET}"
  echo "  ${_PC_CYAN}deploy${_PC_RESET}                              ${_PC_DIM}Deploy${_PC_RESET}"
  echo "  ${_PC_CYAN}report${_PC_RESET}   ${_PC_DIM}[--month|--client]${_PC_RESET}        ${_PC_DIM}Reports${_PC_RESET}"
  echo ""

  echo "  ${_PC_BOLD}Templates${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}templates${_PC_RESET}                           ${_PC_DIM}List templates${_PC_RESET}"
  echo "  ${_PC_DIM}Available: ${_PC_WHITE}webdev${_PC_RESET} ${_PC_WHITE}saas${_PC_RESET} ${_PC_WHITE}marketing${_PC_RESET} ${_PC_WHITE}freelance${_PC_RESET}"
  echo ""

  echo "  ${_PC_DIM}Colors: ${_PC_GREEN}green${_PC_RESET} ${_PC_BLUE}blue${_PC_RESET} ${_PC_CYAN}cyan${_PC_RESET} ${_PC_RED}red${_PC_RESET} ${_PC_ORANGE}orange${_PC_RESET} ${_PC_YELLOW}yellow${_PC_RESET} ${_PC_PURPLE}purple${_PC_RESET} ${_PC_PINK}pink${_PC_RESET} ${_PC_GRAY}gray${_PC_RESET}"
  echo "  ${_PC_DIM}proj help <cmd> ${_PU_ARROW} per-command help (task, note, link, time, open)${_PC_RESET}"
  echo ""
}

# ─── Demo Projects ──────────────────────────────────────────

_proj_create_demos() {
  _proj_ui_header "Loading Demo Projects" "$_PC_LIME"

  # Cosmic Carrot Studios — web agency with full deploy setup
  local f=$(_proj_file "Cosmic Carrot")
  _proj_py "$f" init "Cosmic Carrot" "orange"
  _proj_py "$f" set path "~/Projects/CosmicCarrot"
  _proj_py "$f" task-add "Landing page redesign"
  _proj_py "$f" task-update 0 doing
  _proj_py "$f" task-add "Setup CI/CD pipeline"
  _proj_py "$f" task-add "SEO audit"
  _proj_py "$f" append-note "Check responsive breakpoints"
  _proj_py "$f" append-note "Client wants parallax hero section"
  _proj_py "$f" set-nested links live "https://cosmiccarrot.example.com"
  _proj_py "$f" set-nested links staging "https://staging.cosmiccarrot.example.com"
  _proj_py "$f" set-nested links cloudways "https://platform.cloudways.com/server/12345/access_detail"
  _proj_py "$f" set-nested links ssh "ssh user@cosmiccarrot.example.com"
  _proj_py "$f" set-nested links clickup "https://app.clickup.com/demo/cosmic-carrot"
  _proj_py "$f" set-nested links moco-kunde "https://mocoapp.example.com/contacts/33"
  _proj_py "$f" set-nested links moco-auftrag "https://mocoapp.example.com/projects/55"
  _proj_py "$f" set-nested links gmail "Cosmic Carrot"
  _proj_py "$f" set-nested links github "https://github.com/demo/cosmic-carrot"
  _proj_py "$f" set-nested links 1password "https://my.1password.com/vaults/abc/items/cosmic-carrot"
  echo "  ${_PC_ORANGE}${_PU_BULLET}${_PC_RESET} Cosmic Carrot ${_PC_DIM}— web agency + deploy (3 tasks)${_PC_RESET}"

  # Turbo Turtle Racing — e-commerce with marketing
  f=$(_proj_file "Turbo Turtle")
  _proj_py "$f" init "Turbo Turtle" "green"
  _proj_py "$f" set path "~/Projects/TurboTurtle"
  _proj_py "$f" task-add "Checkout flow optimization"
  _proj_py "$f" task-update 0 doing
  _proj_py "$f" task-add "A/B test one-page vs multi-step"
  _proj_py "$f" append-note "A/B test: one-page vs multi-step checkout"
  _proj_py "$f" set-nested links live "https://turboturtleracing.example.com"
  _proj_py "$f" set-nested links staging "https://staging.turboturtleracing.example.com"
  _proj_py "$f" set-nested links server "https://console.aws.example.com/ec2/i-turboturtle"
  _proj_py "$f" set-nested links facebook-ads "https://business.facebook.com/adsmanager/manage/campaigns?act=12345"
  _proj_py "$f" set-nested links google-ads "https://ads.google.com/aw/campaigns?ocid=67890"
  _proj_py "$f" set-nested links analytics "https://analytics.google.com/analytics/web/#/p99999/reports"
  _proj_py "$f" set-nested links moco-kunde "https://mocoapp.example.com/contacts/42"
  _proj_py "$f" set-nested links moco-auftrag "https://mocoapp.example.com/projects/101"
  echo "  ${_PC_GREEN}${_PU_BULLET}${_PC_RESET} Turbo Turtle ${_PC_DIM}— e-commerce + marketing (2 tasks)${_PC_RESET}"

  # Pixel Penguin Labs — SaaS with AI
  f=$(_proj_file "Pixel Penguin")
  _proj_py "$f" init "Pixel Penguin" "blue"
  _proj_py "$f" set path "~/Projects/PixelPenguin"
  _proj_py "$f" task-add "API rate limiting"
  _proj_py "$f" task-update 0 doing
  _proj_py "$f" task-add "Dashboard usage graphs"
  _proj_py "$f" task-add "Write API docs"
  _proj_py "$f" append-note "Redis-based token bucket"
  _proj_py "$f" append-note "Dashboard needs usage graphs"
  _proj_py "$f" set-nested links live "https://pixelpenguin.example.com"
  _proj_py "$f" set-nested links dev "http://localhost:3000"
  _proj_py "$f" set-nested links github "https://github.com/demo/pixel-penguin"
  _proj_py "$f" set-nested links claude "~/Projects/PixelPenguin"
  _proj_py "$f" set-nested links ssh "ssh deploy@pixelpenguin.example.com"
  echo "  ${_PC_BLUE}${_PU_BULLET}${_PC_RESET} Pixel Penguin ${_PC_DIM}— SaaS + AI (3 tasks)${_PC_RESET}"

  # Neon Narwhal Design — design with marketing
  f=$(_proj_file "Neon Narwhal")
  _proj_py "$f" init "Neon Narwhal" "purple"
  _proj_py "$f" set path "~/Projects/NeonNarwhal"
  _proj_py "$f" task-add "Brand guidelines PDF"
  _proj_py "$f" task-update 0 doing
  _proj_py "$f" task-add "Dark mode variants"
  _proj_py "$f" append-note "Needs dark mode variants"
  _proj_py "$f" set-nested links clickup "https://app.clickup.com/demo/neon-narwhal"
  _proj_py "$f" set-nested links gmail "Neon Narwhal Design"
  _proj_py "$f" set-nested links facebook-ads "https://business.facebook.com/adsmanager/manage/campaigns?act=55555"
  echo "  ${_PC_PURPLE}${_PU_BULLET}${_PC_RESET} Neon Narwhal ${_PC_DIM}— design + marketing (2 tasks)${_PC_RESET}"

  # Thunderbolt Taco — food delivery with full deploy
  f=$(_proj_file "Thunderbolt Taco")
  _proj_py "$f" init "Thunderbolt Taco" "red"
  _proj_py "$f" set path "~/Projects/ThunderboltTaco"
  _proj_py "$f" task-add "Push notifications"
  _proj_py "$f" task-update 0 doing
  _proj_py "$f" task-add "iOS permission flow UX"
  _proj_py "$f" task-add "Android deep links"
  _proj_py "$f" append-note "Firebase Cloud Messaging setup"
  _proj_py "$f" append-note "iOS permission flow needs UX review"
  _proj_py "$f" set-nested links live "https://thunderbolttaco.example.com"
  _proj_py "$f" set-nested links staging "https://staging.thunderbolttaco.example.com"
  _proj_py "$f" set-nested links dev "http://localhost:8080"
  _proj_py "$f" set-nested links cloudways "https://platform.cloudways.com/server/67890/access_detail"
  _proj_py "$f" set-nested links ssh "ssh app@thunderbolttaco.example.com"
  _proj_py "$f" set-nested links moco-kunde "https://mocoapp.example.com/contacts/77"
  _proj_py "$f" set-nested links codex "~/Projects/ThunderboltTaco"
  _proj_py "$f" set-nested links 1password "https://my.1password.com/vaults/abc/items/thunderbolt-taco"
  echo "  ${_PC_RED}${_PU_BULLET}${_PC_RESET} Thunderbolt Taco ${_PC_DIM}— delivery + deploy (3 tasks)${_PC_RESET}"

  echo ""
  _proj_ui_success "5 demo projects created"
  _proj_ui_hint "proj ${_PU_ARROW} open menu  ${_PC_DIM}|${_PC_RESET}${_PC_DIM}  proj rm <name> ${_PU_ARROW} cleanup"
}

# ─── Migrate .conf to .json ─────────────────────────────────

_proj_migrate_conf() {
  local conf_dir="$PROJ_DIR"
  local -a conf_files
  conf_files=("$conf_dir"/*.conf(N))

  if (( ${#conf_files} == 0 )); then
    _proj_ui_info "No .conf files to migrate"
    return
  fi

  _proj_ui_header "Migrating .conf → .json" "$_PC_YELLOW"

  for conf in "${conf_files[@]}"; do
    local base="${conf:t:r}"
    local json_file="$conf_dir/$base.json"

    if [[ -f "$json_file" ]]; then
      echo "  ${_PC_DIM}skip${_PC_RESET} $base ${_PC_DIM}(JSON exists)${_PC_RESET}"
      continue
    fi

    local result=$(_proj_py "$json_file" migrate-conf "$conf")
    if [[ "$result" == migrated:* ]]; then
      local name="${result#migrated:}"
      echo "  ${_PC_GREEN}${_PU_CHECK}${_PC_RESET} $name"
      # Keep old .conf as backup
      mv "$conf" "${conf}.bak"
    else
      echo "  ${_PC_RED}${_PU_CROSS}${_PC_RESET} Failed: $base"
    fi
  done

  echo ""
  _proj_ui_success "Migration complete"
}

# ─── Tab Completion ──────────────────────────────────────────

_proj_completion() {
  local -a subcmds
  subcmds=(
    'menu:Interactive project menu'
    'use:Activate project'
    'info:Project details'
    'path:Set/show project directory'
    'cd:Jump to project directory'
    'task:Manage tasks (add/do/done/rm/list)'
    'note:Notes (add/rm/edit)'
    'notes:Show notes'
    'notes-clear:Clear notes'
    'open:Open links'
    'link:Manage links (add/rm)'
    'time:Time tracking'
    'color:Change color'
    'list:List projects'
    'dash:Cross-project dashboard'
    'templates:List templates'
    'clear:Deactivate'
    'rm:Delete project'
    'claude:Start Claude Code'
    'codex:Start Codex'
    'sessions:Claude sessions (via stars)'
    'sync:Sync to Moco/ClickUp (via stars)'
    'deploy:Deploy via pipeline (via stars)'
    'report:Generate reports (via stars)'
    'demo:Create demo projects'
    'migrate:Migrate .conf to .json'
    'help:Show help'
  )

  if (( CURRENT == 2 )); then
    _describe 'command' subcmds
  elif (( CURRENT == 3 )); then
    case "${words[2]}" in
      use|u|rm)
        local -a projects
        for f in "$PROJ_DIR"/*.json(N); do
          local pname=$(python3 -c "import json; print(json.load(open('$f')).get('name',''))" 2>/dev/null)
          [[ -n "$pname" ]] && projects+=("$pname")
        done
        _describe 'project' projects
        ;;
      color|c)
        local -a colors
        colors=(${(k)PROJ_COLORS})
        _describe 'color' colors
        ;;
      time|ti)
        local -a timecmds
        timecmds=(start stop log status)
        _describe 'time command' timecmds
        ;;
      task|t)
        local -a taskcmds
        taskcmds=(add do done rm list)
        _describe 'task command' taskcmds
        ;;
      note|n)
        local -a notecmds
        notecmds=(rm edit)
        _describe 'note command' notecmds
        ;;
      link)
        local -a linkcmds
        linkcmds=(add rm)
        _describe 'link command' linkcmds
        ;;
      open|o)
        if [[ -n "$_PROJ_CURRENT" ]]; then
          local file=$(_proj_file "$_PROJ_CURRENT")
          local -a link_keys
          link_keys=("${(@f)$(_proj_py "$file" list-keys links 2>/dev/null)}")
          _describe 'link' link_keys
        fi
        ;;
      help|h)
        local -a helptopics
        helptopics=(all task note link time open)
        _describe 'help topic' helptopics
        ;;
    esac
  elif (( CURRENT == 4 )); then
    case "${words[2]}" in
      link)
        if [[ "${words[3]}" == "add" ]]; then
          local -a linktypes
          for entry in "${_PROJ_LINK_TYPES[@]}"; do
            linktypes+=("${entry%%:*}")
          done
          _describe 'link type' linktypes
        fi
        ;;
    esac
  fi
}
(( $+functions[compdef] )) && compdef _proj_completion proj
