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
    note|n)         shift; _proj_note "$@" ;;
    notes)          _proj_notes ;;
    notes-clear|nc) _proj_notes_clear ;;
    color|c)        shift; _proj_color "$@" ;;

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
    help|h)         _proj_help ;;

    *) _proj_ui_error "Unknown: $cmd" && echo "" && _proj_help ;;
  esac
}

# ─── Help ────────────────────────────────────────────────────

_proj_help() {
  _proj_ui_banner

  echo "  ${_PC_BOLD}Quick Start${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}proj${_PC_RESET}                          Interactive menu"
  echo "  ${_PC_CYAN}proj use${_PC_RESET} ${_PC_DIM}<name> [color]${_PC_RESET}      Activate project"
  echo ""

  echo "  ${_PC_BOLD}Project${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}info${_PC_RESET}  ${_PC_DIM}i${_PC_RESET}                      Project details"
  echo "  ${_PC_CYAN}path${_PC_RESET}  ${_PC_DIM}p${_PC_RESET}  ${_PC_DIM}[dir]${_PC_RESET}              Set/show local directory"
  echo "  ${_PC_CYAN}cd${_PC_RESET}                            Jump to project directory"
  echo "  ${_PC_CYAN}task${_PC_RESET}  ${_PC_DIM}t${_PC_RESET}  ${_PC_DIM}<text>${_PC_RESET}             Set current task"
  echo "  ${_PC_CYAN}note${_PC_RESET}  ${_PC_DIM}n${_PC_RESET}  ${_PC_DIM}<text>${_PC_RESET}             Add note"
  echo "  ${_PC_CYAN}color${_PC_RESET} ${_PC_DIM}c${_PC_RESET}  ${_PC_DIM}<color>${_PC_RESET}            Change tab color"
  echo "  ${_PC_CYAN}list${_PC_RESET}  ${_PC_DIM}ls${_PC_RESET}                     List all projects"
  echo "  ${_PC_CYAN}clear${_PC_RESET} ${_PC_DIM}x${_PC_RESET}                      Deactivate"
  echo "  ${_PC_CYAN}rm${_PC_RESET}    ${_PC_DIM}<name>${_PC_RESET}                 Delete project"
  echo ""

  echo "  ${_PC_BOLD}Links & Deploy${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}open${_PC_RESET}  ${_PC_DIM}o${_PC_RESET}  ${_PC_DIM}[#|type]${_PC_RESET}           Open link menu / by #"
  echo "  ${_PC_CYAN}link add${_PC_RESET}                      Add a link"
  echo "  ${_PC_CYAN}link rm${_PC_RESET} ${_PC_DIM}<type>${_PC_RESET}               Remove a link"
  echo "  ${_PC_DIM}  Types: live staging dev clickup moco-kunde moco-auftrag${_PC_RESET}"
  echo "  ${_PC_DIM}         gmail github server ssh cloudways${_PC_RESET}"
  echo "  ${_PC_DIM}         facebook-ads google-ads analytics 1password${_PC_RESET}"
  echo ""

  echo "  ${_PC_BOLD}Time${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}time start${_PC_RESET}  ${_PC_DIM}s${_PC_RESET}                Start timer"
  echo "  ${_PC_CYAN}time stop${_PC_RESET}   ${_PC_DIM}x${_PC_RESET}                Stop timer"
  echo "  ${_PC_CYAN}time log${_PC_RESET}    ${_PC_DIM}l [days]${_PC_RESET}          Time log (default 30d)"
  echo "  ${_PC_CYAN}time status${_PC_RESET}                   Current timer"
  echo ""

  echo "  ${_PC_BOLD}AI${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}claude${_PC_RESET} ${_PC_DIM}cl${_PC_RESET}                    Start Claude Code"
  echo "  ${_PC_CYAN}codex${_PC_RESET}  ${_PC_DIM}cx${_PC_RESET}                    Start Codex"
  echo "  ${_PC_CYAN}sessions${_PC_RESET} ${_PC_DIM}ss${_PC_RESET}                  Claude sessions (via stars)"
  echo ""

  echo "  ${_PC_BOLD}Workflow (stars)${_PC_RESET}"
  echo "  ${_PC_DIM}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PU_H}${_PC_RESET}"
  echo "  ${_PC_CYAN}sync${_PC_RESET}    ${_PC_DIM}[moco|clickup]${_PC_RESET}        Sync to external systems"
  echo "  ${_PC_CYAN}deploy${_PC_RESET}                          Deploy via pipeline"
  echo "  ${_PC_CYAN}report${_PC_RESET}  ${_PC_DIM}[--month|--client]${_PC_RESET}    Generate reports"
  echo ""

  echo "  ${_PC_DIM}Colors: ${_PC_GREEN}green${_PC_RESET} ${_PC_BLUE}blue${_PC_RESET} ${_PC_CYAN}cyan${_PC_RESET} ${_PC_RED}red${_PC_RESET} ${_PC_ORANGE}orange${_PC_RESET} ${_PC_YELLOW}yellow${_PC_RESET} ${_PC_PURPLE}purple${_PC_RESET} ${_PC_PINK}pink${_PC_RESET} ${_PC_GRAY}gray${_PC_RESET}"
  echo ""
}

# ─── Demo Projects ──────────────────────────────────────────

_proj_create_demos() {
  _proj_ui_header "Loading Demo Projects" "$_PC_LIME"

  # Cosmic Carrot Studios — web agency with full deploy setup
  local f=$(_proj_file "Cosmic Carrot")
  _proj_py "$f" init "Cosmic Carrot" "orange"
  _proj_py "$f" set task "Landing page redesign"
  _proj_py "$f" set path "~/Projects/CosmicCarrot"
  _proj_py "$f" append notes '"Check responsive breakpoints"'
  _proj_py "$f" append notes '"Client wants parallax hero section"'
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
  echo "  ${_PC_ORANGE}${_PU_BULLET}${_PC_RESET} Cosmic Carrot ${_PC_DIM}— web agency + deploy${_PC_RESET}"

  # Turbo Turtle Racing — e-commerce with marketing
  f=$(_proj_file "Turbo Turtle")
  _proj_py "$f" init "Turbo Turtle" "green"
  _proj_py "$f" set task "Checkout flow optimization"
  _proj_py "$f" set path "~/Projects/TurboTurtle"
  _proj_py "$f" append notes '"A/B test: one-page vs multi-step checkout"'
  _proj_py "$f" set-nested links live "https://turboturtleracing.example.com"
  _proj_py "$f" set-nested links staging "https://staging.turboturtleracing.example.com"
  _proj_py "$f" set-nested links server "https://console.aws.example.com/ec2/i-turboturtle"
  _proj_py "$f" set-nested links facebook-ads "https://business.facebook.com/adsmanager/manage/campaigns?act=12345"
  _proj_py "$f" set-nested links google-ads "https://ads.google.com/aw/campaigns?ocid=67890"
  _proj_py "$f" set-nested links analytics "https://analytics.google.com/analytics/web/#/p99999/reports"
  _proj_py "$f" set-nested links moco-kunde "https://mocoapp.example.com/contacts/42"
  _proj_py "$f" set-nested links moco-auftrag "https://mocoapp.example.com/projects/101"
  echo "  ${_PC_GREEN}${_PU_BULLET}${_PC_RESET} Turbo Turtle ${_PC_DIM}— e-commerce + marketing${_PC_RESET}"

  # Pixel Penguin Labs — SaaS with AI
  f=$(_proj_file "Pixel Penguin")
  _proj_py "$f" init "Pixel Penguin" "blue"
  _proj_py "$f" set task "API rate limiting"
  _proj_py "$f" set path "~/Projects/PixelPenguin"
  _proj_py "$f" append notes '"Redis-based token bucket"'
  _proj_py "$f" append notes '"Dashboard needs usage graphs"'
  _proj_py "$f" set-nested links live "https://pixelpenguin.example.com"
  _proj_py "$f" set-nested links dev "http://localhost:3000"
  _proj_py "$f" set-nested links github "https://github.com/demo/pixel-penguin"
  _proj_py "$f" set-nested links claude "~/Projects/PixelPenguin"
  _proj_py "$f" set-nested links ssh "ssh deploy@pixelpenguin.example.com"
  echo "  ${_PC_BLUE}${_PU_BULLET}${_PC_RESET} Pixel Penguin ${_PC_DIM}— SaaS + AI${_PC_RESET}"

  # Neon Narwhal Design — design with marketing
  f=$(_proj_file "Neon Narwhal")
  _proj_py "$f" init "Neon Narwhal" "purple"
  _proj_py "$f" set task "Brand guidelines PDF"
  _proj_py "$f" set path "~/Projects/NeonNarwhal"
  _proj_py "$f" append notes '"Needs dark mode variants"'
  _proj_py "$f" set-nested links clickup "https://app.clickup.com/demo/neon-narwhal"
  _proj_py "$f" set-nested links gmail "Neon Narwhal Design"
  _proj_py "$f" set-nested links facebook-ads "https://business.facebook.com/adsmanager/manage/campaigns?act=55555"
  echo "  ${_PC_PURPLE}${_PU_BULLET}${_PC_RESET} Neon Narwhal ${_PC_DIM}— design + marketing${_PC_RESET}"

  # Thunderbolt Taco — food delivery with full deploy
  f=$(_proj_file "Thunderbolt Taco")
  _proj_py "$f" init "Thunderbolt Taco" "red"
  _proj_py "$f" set task "Push notifications"
  _proj_py "$f" set path "~/Projects/ThunderboltTaco"
  _proj_py "$f" append notes '"Firebase Cloud Messaging setup"'
  _proj_py "$f" append notes '"iOS permission flow needs UX review"'
  _proj_py "$f" set-nested links live "https://thunderbolttaco.example.com"
  _proj_py "$f" set-nested links staging "https://staging.thunderbolttaco.example.com"
  _proj_py "$f" set-nested links dev "http://localhost:8080"
  _proj_py "$f" set-nested links cloudways "https://platform.cloudways.com/server/67890/access_detail"
  _proj_py "$f" set-nested links ssh "ssh app@thunderbolttaco.example.com"
  _proj_py "$f" set-nested links moco-kunde "https://mocoapp.example.com/contacts/77"
  _proj_py "$f" set-nested links codex "~/Projects/ThunderboltTaco"
  _proj_py "$f" set-nested links 1password "https://my.1password.com/vaults/abc/items/thunderbolt-taco"
  echo "  ${_PC_RED}${_PU_BULLET}${_PC_RESET} Thunderbolt Taco ${_PC_DIM}— delivery + deploy${_PC_RESET}"

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
    'task:Set current task'
    'note:Add note'
    'notes:Show notes'
    'notes-clear:Clear notes'
    'open:Open links'
    'link:Manage links'
    'time:Time tracking'
    'color:Change color'
    'list:List projects'
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
      link)
        local -a linkcmds
        linkcmds=(add rm)
        _describe 'link command' linkcmds
        ;;
      open|o)
        # Complete with link types from current project
        if [[ -n "$_PROJ_CURRENT" ]]; then
          local file=$(_proj_file "$_PROJ_CURRENT")
          local -a link_keys
          link_keys=("${(@f)$(_proj_py "$file" list-keys links 2>/dev/null)}")
          _describe 'link' link_keys
        fi
        ;;
    esac
  fi
}
(( $+functions[compdef] )) && compdef _proj_completion proj
