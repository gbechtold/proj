# 🚀 proj — Project Hub in your Terminal

A lightweight, colorful terminal tool that turns your shell into a project command center. Switch contexts, manage links, track time, and launch AI sessions — all without leaving the terminal.

```
╭──────────════════════════════════──────────╮
│  🚀 proj · Project Hub in your Terminal    │
╰──────────════════════════════════──────────╯
```

## ✨ Features

- **Interactive Menu** — Select projects with a numbered list, paging, and quick-create
- **Smart Links** — Store and open project URLs (live, staging, ClickUp, Moco, Gmail, GitHub)
- **Time Tracking** — Simple `start` / `stop` timer with daily log
- **AI Integration** — Launch Claude Code or Codex with full project context
- **iTerm2 Eye Candy** — Colored tabs, titles, and badges per project
- **JSON Storage** — Clean, human-readable project files

## 📦 Installation

```bash
git clone https://github.com/gbechtold/proj.git
cd proj
bash install.sh && source src/proj.zsh
```

That's it — `proj` is ready in your current shell. Future terminals load it automatically via `.zshrc`.

**Requirements:** macOS, zsh, python3, iTerm2 (optional, for tab colors)

## 🎯 Quick Start

```bash
proj                    # Interactive project menu
proj demo               # Load demo projects to explore
```

### Create & Activate

```bash
proj use "My Project" blue    # Create + activate with color
proj task "Fix login bug"     # Set current task
proj note "Check OAuth flow"  # Add a note
```

### Links

```bash
proj link add                 # Interactive: choose type, enter URL
proj open                     # Show all links, pick by number
proj open 1                   # Open link #1 directly
proj open live                # Open by type name
```

### Time Tracking

```bash
proj time start               # ▶ Start timer
proj time stop                # ■ Stop timer + show duration
proj time log                 # View time log (last 30 days)
proj time status              # Check if timer is running
```

### AI Sessions

```bash
proj claude                   # Launch Claude Code with project context
proj codex                    # Launch Codex with project context
```

Both write a `.proj-context.json` to your project directory and can open in a new iTerm2 tab.

## 📋 All Commands

| Command | Short | Description |
|---------|-------|-------------|
| `proj` | `m` | Interactive project menu |
| `proj use <name> [color]` | `u` | Activate / create project |
| `proj info` | `i` | Show project details |
| `proj task <text>` | `t` | Set current task |
| `proj note <text>` | `n` | Add a note |
| `proj notes` | | Show all notes |
| `proj open [#\|type]` | `o` | Open links menu / direct |
| `proj link add` | | Add a link interactively |
| `proj link rm <type>` | | Remove a link |
| `proj time start` | | Start timer |
| `proj time stop` | | Stop timer |
| `proj time log [days]` | | Time log (default: 30 days) |
| `proj color <color>` | `c` | Change tab color |
| `proj list` | `ls` | List all projects |
| `proj clear` | `x` | Deactivate / reset tab |
| `proj rm <name>` | | Delete project |
| `proj claude` | `cl` | Start Claude Code |
| `proj codex` | `cx` | Start Codex |
| `proj help` | `h` | Show help |

## 🎨 Colors

`green` `blue` `cyan` `red` `orange` `yellow` `purple` `pink` `gray`

Colors are applied to your iTerm2 tab background for instant visual context switching.

## 🔗 Link Types

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
| `custom` | 🔗 | Any URL |

## 📁 Data Format

Projects are stored as JSON in `~/.config/proj/projects/`:

```json
{
  "name": "Cosmic Carrot",
  "color": "orange",
  "task": "Landing page redesign",
  "notes": [
    "Check responsive breakpoints",
    "Client wants parallax hero section"
  ],
  "links": {
    "live": "https://cosmiccarrot.example.com",
    "staging": "https://staging.cosmiccarrot.example.com",
    "clickup": "https://app.clickup.com/demo/cosmic-carrot",
    "gmail": "Cosmic Carrot",
    "github": "https://github.com/demo/cosmic-carrot"
  },
  "time": [
    { "start": "2026-02-28T14:32:05", "stop": "2026-02-28T16:15:22" }
  ],
  "ai": {},
  "created": "2026-02-28T10:00:00",
  "updated": "2026-02-28T16:15:22"
}
```

## 🗺 Roadmap

- [x] **Phase 1:** Local project hub with browser links, time tracking, AI launch
- [ ] **Phase 2:** API integrations (Moco time booking, ClickUp ticket creation) — separate project

## 🤝 Migration

Coming from the old `.conf` format? Run:

```bash
proj migrate
```

This converts all `.conf` files to `.json` and keeps backups.

## License

MIT

---

Built with ☕ and terminal magic by [Stars Media IT GmbH](https://starsmedia.com)
