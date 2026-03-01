# proj — Project Hub in your Terminal

## Goal
Terminal-based project hub that consolidates links, time tracking, and AI sessions per project.

## Architecture
- **Entry point:** `src/proj.zsh` (sourced via .zshrc)
- **Libraries:** `src/lib/*.zsh` (ui, core, menu, links, time, ai)
- **JSON engine:** `src/proj_helper.py` (Python3, no external deps)
- **Data:** `~/.config/proj/projects/*.json`

## Key Conventions
- All UI output through `_proj_ui_*` helpers (lib/ui.zsh)
- All JSON operations through `_proj_py` → `proj_helper.py`
- Project files: snake_case.json in `~/.config/proj/projects/`
- iTerm2 escape codes for tab colors/titles/badges
- Contextual shortcut hints after actions via `_proj_ui_hint`

## Status
- Phase 1: Local hub (links, time, AI) — fertig
- Phase 2: Stars bridge (sessions, sync, deploy, report) — fertig

## Repos
- **Dieses Repo:** github.com/gbechtold/proj (private)
- **Engine:** github.com/gbechtold/stars-hub (private)
- **Infra:** github.com/gbechtold/stars-ops (private)

## Commands
proj, proj use, proj info, proj open, proj link add/rm,
proj time start/stop/log, proj claude, proj codex,
proj task, proj note, proj color, proj list, proj clear, proj rm,
proj sessions, proj sync, proj deploy, proj report
