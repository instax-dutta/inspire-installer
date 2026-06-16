# Inspire Theme Installer ⚡

**One-command installer for premium Pterodactyl Panel themes** — Elden (Sentri Dark), Elysium (Monospaced Dark), and Elipso (Vercel-inspired). Backs up your panel, installs the theme, fixes permissions, and evicts every cache layer so it just works.

```bash
bash <(curl -s https://raw.githubusercontent.com/instax-dutta/inspire-installer/main/install.sh)
```

---

## Key Features

- **🎨 Interactive TUI Menu**: Beautiful ASCII interface with dynamic spinners and colored logging.
- **🔄 Local + Remote Mode**: Installs from local repo files or auto-downloads the latest ZIP from GitHub.
- **🔒 Safe Backups**: Timestamped backup (`inspire-backup-<theme>-YYYYMMDD-HHMMSS`) of views, styles, and config before any change.
- **🧼 Full Cache Eviction**: Flushes Laravel Artisan caches, PHP-FPM OPcache, Nginx/Apache, Supervisor queue workers (`pteroq:*`), and Docker containers.
- **🛠️ Auto Permissions**: Detects web server user (`www-data`, `nginx`, etc.) and sets correct ownership.
- **🎯 Baseline Restorer**: Rebuilds panel to official Pterodactyl core files — useful for clean slates.
- **↩️ One-Key Uninstall**: Browse and restore from any previous backup via the menu.
- **⚡ Graceful Elipso Install**: No forced baseline restore. Backs up existing files and layers the theme on top.
- **🔐 Auto Root Elevation**: Re-executes with `sudo` automatically — no forgotten privileges.
- **💾 Disk Space Check**: Warns if free space is low before downloading or extracting.
- **👁️ Dry-Run Mode**: `--dry-run` to preview what would happen without making changes.
- **🤖 CI/CD Ready**: Every command available as a CLI flag for automated pipelines.

---

## Supported Themes

| Theme | Style | Theme ID |
|-------|-------|----------|
| **Elden** (Sentri Dark) | Dark, clean panel skin | `sentri-pterodactyl-dark` |
| **Elysium** (Monospaced Dark) | Monospaced dark UI with React admin | `elysium-dark` |
| **Elipso** (Premium Vercel Skin) | Vercel-inspired near-black canvas, Geist typography | `elipso-vercel` |

---

## Quick Start

### One-Liner (Recommended — no clone needed)
```bash
bash <(curl -s https://raw.githubusercontent.com/instax-dutta/inspire-installer/main/install.sh)
```

### Clone & Run
```bash
git clone https://github.com/instax-dutta/inspire-installer.git
cd inspire-installer
chmod +x install.sh
./install.sh
```

---

## CLI Flags (Headless / CI)

```bash
./install.sh <flag>

--elden              Install Elden (Sentri Dark)
--elysium            Install Elysium (Monospaced Dark)
--elipso             Install Elipso (Vercel Premium)
--restore-baseline   Reset panel to official Pterodactyl release
--uninstall          Open backup restore menu
--clear-cache        Full system cache eviction
--dry-run, -n        Preview actions without making changes
--version, -V        Show version
--help, -h           Show this help
```

Global flags like `--dry-run` can be combined:  
```bash
bash install.sh --dry-run --elipso
```

---

## Prerequisites

- **OS**: Linux or macOS with SSH / terminal access
- **Privileges**: Sudo / root (handled automatically)
- **Required**: `curl`, `wget`, `unzip`, `tar`, `php`
- **Optional**: `yarn` + `node` (for live React asset compilation on Elipso)

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `unzip: Command not found` | `sudo apt install unzip` (Debian) or `sudo dnf install unzip` (RHEL) |
| `yarn not found` | Not required — prebuilt assets are injected automatically. Install with `npm i -g yarn` if you want live builds. |
| Panel path not detected | Pass it: `bash install.sh /custom/path/to/panel` |

---

## Architecture

```
inspire-installer/
  ├── install.sh          # Orchestrator — menu + all install logic
  ├── elden-theme/        # Sentri Dark theme files
  ├── elysium/            # Elysium Monospaced Dark theme files
  └── elipso-theme/       # Elipso Vercel Premium theme files
```

**Flow**: Select theme → backup → resolve source (local or GitHub) → copy views/styles/assets → verify → fix permissions → evict all caches → done.

---

## License

MIT

---

## Author

**instax-dutta** — Premium Pterodactyl themes for self-hosted game server panels.
