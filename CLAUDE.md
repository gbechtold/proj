# proj — Project Hub in your Terminal

## Goal
Terminal-based project hub that consolidates links, time tracking, tasks, and AI sessions per project.

## Architecture
- **Entry point:** `src/proj.zsh` (sourced via .zshrc)
- **Libraries:** `src/lib/*.zsh` (ui, core, menu, links, time, ai, dash, stars)
- **JSON engine:** `src/proj_helper.py` (Python3, no external deps)
- **Data:** `~/.config/proj/projects/*.json`

## Key Conventions
- All UI output through `_proj_ui_*` helpers (lib/ui.zsh)
- All JSON operations through `_proj_py` → `proj_helper.py`
- Project files: snake_case.json in `~/.config/proj/projects/`
- iTerm2 escape codes for tab colors/titles/badges/background
- `_proj_is_iterm2` guard on all iTerm2 escape sequences
- `_proj_expand_path` for all tilde expansion
- `_proj_color_code` for color name → escape code mapping
- Contextual shortcut hints after actions via `_proj_ui_hint`
- Gray (`_PC_DIM`) for chrome/labels, white (`_PC_WHITE`) for user values

## Status
- Phase 1: Local hub (links, time, AI) — fertig
- Phase 2: Stars bridge (sessions, sync, deploy, report) — fertig
- Phase 3: Usability (12 optimizations) — fertig
  - Multi-task (todo/doing/done), dashboard, templates (webdev/saas/marketing/freelance)
  - fzf integration, contextual help, link quick-add, enhanced notes
  - iTerm2 background colors, Python batch calls, rm confirmation

## Repos
- **Dieses Repo:** github.com/gbechtold/proj (private)
- **Engine:** github.com/gbechtold/stars-hub (private)
- **Infra:** github.com/gbechtold/stars-ops (private)

## Commands
proj, proj use [-t template], proj info, proj dash,
proj open, proj link add [type] [url], proj link rm,
proj task [add/do/done/rm/list], proj note [rm/edit],
proj time start/stop/log, proj claude, proj codex,
proj color, proj list, proj clear, proj rm,
proj templates, proj sessions, proj sync, proj deploy, proj report,
proj help [all|task|note|link|time|open]
