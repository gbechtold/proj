# proj — Project Hub in your Terminal

A lightweight, colorful terminal tool that turns your shell into a project command center. Switch contexts, manage tasks, track time, and launch AI sessions — all without leaving the terminal.

```
╭──────────════════════════════════──────────╮
│  🚀 proj · Project Hub in your Terminal    │
╰──────────════════════════════════──────────╯
```

## Features

- **Interactive Menu** — fzf fuzzy finder with preview, or paginated fallback with smart match
- **Multi-Task Workflow** — todo/doing/done per project, shown in tab title
- **Smart Links** — Store and open project URLs with quick-add (`proj link add github https://...`)
- **Time Tracking** — Simple `start` / `stop` timer with daily log
- **AI Integration** — Launch Claude Code or Codex with rich project context (git, file tree, packages)
- **Cross-Project Dashboard** — Timers, active tasks, and weekly summary across all projects
- **Project Templates** — webdev, saas, marketing, freelance — one command setup
- **iTerm2 Eye Candy** — Tab colors, background tint, titles, and badges per project
- **Contextual Help** — Shows relevant commands based on state
- **JSON Storage** — Clean, human-readable project files

## Installation

```bash
git clone https://github.com/gbechtold/proj.git
cd proj
bash install.sh && source src/proj.zsh
```

**Requirements:** macOS, zsh, python3, iTerm2 (optional, for colors), fzf (optional, for fuzzy selection)

## Quick Start

```bash
proj                              # Interactive menu (fzf or paginated)
proj demo                         # Load demo projects to explore
proj help                         # Context-aware help
```

### Create & Activate

```bash
proj use "My Project" blue        # Create + activate with color
proj use "Client Site" -t webdev  # Create from template
proj templates                    # List available templates
```

### Tasks

```bash
proj task Fix login bug           # Quick-add task
proj task list                    # Show all tasks
proj task do 1                    # Mark task #1 as active (doing)
proj task done 1                  # Mark task #1 as done
proj task rm 2                    # Remove task #2
```

The active ("doing") task is shown in the iTerm2 tab title and badge.

### Notes

```bash
proj note Check OAuth flow        # Add timestamped note
proj notes                        # Show all notes
proj note rm 2                    # Remove note #2
proj note edit 1 Updated text     # Edit note #1
```

### Links

```bash
proj link add                     # Interactive wizard
proj link add github https://github.com/me/repo  # Quick-add
proj open                         # fzf link selector (or numbered menu)
proj open 1                       # Open link #1 directly
proj open live                    # Open by type name
```

### Time Tracking

```bash
proj time start                   # Start timer
proj time stop                    # Stop timer + show duration
proj time log                     # View time log (last 30 days)
proj time status                  # Check if timer is running
```

### Dashboard

```bash
proj dash                         # Cross-project overview
```

Shows running timers, active tasks, recently updated projects, and today/week totals.

### AI Sessions

```bash
proj claude                       # Launch Claude Code with project context
proj codex                        # Launch Codex
proj sessions                     # Browse Claude sessions (via stars)
```

Writes a `.proj/context.json` with git info, file tree, package type, timer status, and task context.

## All Commands

| Command | Short | Description |
|---------|-------|-------------|
| `proj` | `m` | Interactive menu (fzf / paginated) |
| `proj use <name> [color]` | `u` | Activate / create project |
| `proj use <name> -t <tpl>` | | Create from template |
| `proj info` | `i` | Project details |
| `proj dash` | `d` | Cross-project dashboard |
| `proj task <text>` | `t` | Quick-add task |
| `proj task add/do/done/rm/list` | | Task management |
| `proj note <text>` | `n` | Add timestamped note |
| `proj note rm/edit` | | Note management |
| `proj notes` | | Show all notes |
| `proj open [#\|type]` | `o` | Open links (fzf / menu) |
| `proj link add [type] [url]` | | Add link (wizard or quick-add) |
| `proj link rm <type>` | | Remove link |
| `proj time start/stop/log/status` | `ti` | Time tracking |
| `proj color <color>` | `c` | Change tab color |
| `proj path [dir]` | `p` | Set/show project directory |
| `proj cd` | | Jump to project directory |
| `proj list` | `ls` | List all projects |
| `proj templates` | `tpl` | List project templates |
| `proj clear` | `x` | Deactivate / reset tab |
| `proj rm <name>` | | Delete project (with confirmation) |
| `proj claude` | `cl` | Start Claude Code |
| `proj codex` | `cx` | Start Codex |
| `proj sessions` | `ss` | Claude sessions (via stars) |
| `proj sync` | | Sync to Moco/ClickUp (via stars) |
| `proj deploy` | | Deploy via pipeline (via stars) |
| `proj report` | | Generate reports (via stars) |
| `proj help [topic]` | `h` | Context-aware help |

## Templates

| Name | Color | Default Task | Link Slots |
|------|-------|-------------|------------|
| `webdev` | cyan | Site launch | live, staging, dev, github, cloudways, ssh, clickup, moco, 1password |
| `saas` | blue | MVP sprint | live, dev, github, claude, analytics, 1password |
| `marketing` | orange | Campaign launch | live, google-ads, facebook-ads, analytics, clickup, moco |
| `freelance` | green | Project kickoff | live, github, gmail, moco, 1password |

## Colors

`green` `blue` `cyan` `red` `orange` `yellow` `purple` `pink` `gray`

Colors set iTerm2 tab color + subtle background tint for instant visual context switching.
Non-iTerm2 terminals get a one-time notice and work without colors.

## Link Types

| Type | Icon | Example |
|------|------|---------|
| `live` | 🌐 | Production website |
| `staging` | 🔧 | Staging environment |
| `dev` | 🛠 | Local dev server |
| `clickup` | 📋 | ClickUp space/task |
| `moco-kunde` | 💼 | Moco client page |
| `moco-auftrag` | 💰 | Moco project page |
| `gmail` | 📧 | Gmail search (auto-builds URL) |
| `github` | 🐙 | GitHub repository |
| `claude` | 🧠 | Claude Code project path |
| `codex` | ⚡ | Codex project path |
| `server` | 🖥 | Server panel |
| `ssh` | 🔑 | SSH connection (copies to clipboard) |
| `cloudways` | ☁️ | Cloudways panel |
| `facebook-ads` | 📣 | Facebook Ads Manager |
| `google-ads` | 📢 | Google Ads |
| `analytics` | 📊 | Google Analytics |
| `1password` | 🔐 | 1Password vault |
| `custom` | 🔗 | Any URL |

## Data Format

Projects are stored as JSON in `~/.config/proj/projects/`:

```json
{
  "name": "Cosmic Carrot",
  "color": "orange",
  "task": "Landing page redesign",
  "tasks": [
    { "text": "Landing page redesign", "status": "doing", "created": "2026-02-28T10:00:00" },
    { "text": "Setup CI/CD pipeline", "status": "todo", "created": "2026-02-28T10:00:00" },
    { "text": "Initial project setup", "status": "done", "created": "2026-02-28T09:00:00" }
  ],
  "notes": [
    { "text": "Check responsive breakpoints", "created": "2026-02-28T10:00:00" },
    { "text": "Client wants parallax hero", "created": "2026-02-28T11:00:00" }
  ],
  "links": {
    "live": "https://cosmiccarrot.example.com",
    "github": "https://github.com/demo/cosmic-carrot",
    "clickup": "https://app.clickup.com/demo/cosmic-carrot"
  },
  "time": [
    { "start": "2026-02-28T14:32:05", "stop": "2026-02-28T16:15:22" }
  ],
  "created": "2026-02-28T10:00:00",
  "updated": "2026-02-28T16:15:22"
}
```

The legacy `task` string field stays synced with the current "doing" task for backward compatibility.

## Roadmap

- [x] **Phase 1:** Local project hub (links, time tracking, AI launch)
- [x] **Phase 2:** Stars Hub bridge (sessions, sync, deploy, report)
- [x] **Phase 3:** Usability (multi-task, dashboard, templates, fzf, contextual help)
- [ ] **Phase 4:** Archive/export, Moco hours in info, live dashboard refresh

## Related Projects

- [stars-hub](https://github.com/gbechtold/stars-hub) — Workflow automation engine (Node.js)
- [stars-ops](https://github.com/gbechtold/stars-ops) — Server infrastructure (Hetzner)

## Migration

Coming from the old `.conf` format? Run:

```bash
proj migrate
```

This converts all `.conf` files to `.json` and keeps backups.

## License

MIT

---

Built with terminal magic by [Stars Media IT GmbH](https://starsmedia.com)
