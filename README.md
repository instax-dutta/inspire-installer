# Inspire Theme Installer ⚡

A premium, unified, menu-driven command-line installer designed specifically for the state-of-the-art Pterodactyl Panel themes: **Elden Theme (Sentri Dark)**, **Elysium Theme**, and **Elipso Theme**.

Crafted for absolute perfection, this installer features a fully interactive terminal Text User Interface (TUI), comprehensive automatic backups, an advanced multi-layered cache eviction engine, automatic permission alignment, and an official core baseline restorer.

---

## Key Features

- **🎨 Premium Terminal UI (TUI)**: Beautiful ASCII artwork, colored state loggers, dynamic background loaders, and custom interactive selectors.
- **🔄 Dual Resolution Engine**:
  - **Local Mode**: Instantly detects and installs themes from local directories in your repository.
  - **Remote Mode**: Automatically resolves and fetches the official theme zip bundles directly from GitHub if run via a clean one-liner.
- **📦 Pre-flight Diagnostics**: Verifies your active server requirements and CLI tools before running to avoid mid-install issues.
- **🔒 Safe Backup System**: Creates timestamped backups (`inspire-backup-<theme>-YYYYMMDD-HHMMSS`) of all key views, styles, and configurations prior to modifications.
- **🧼 Cache Eviction Orchestrator**: Safely flushes Laravel Artisan structures, FPM OPcache, Nginx/Apache setups, supervisor queue workers (`pteroq:*`), and active Docker containers.
- **🛠️ Permissions Repair**: Auto-detects effective web server users (`www-data`, `nginx`, etc.) and restores clean folder permissions.
- **🎯 Baseline Restorer**: Offers a complete, clean rebuild of the Pterodactyl core files back to the official releases for a flawless theme installation environment.
- **↩️ Complete Uninstaller**: Instantly roll back to your original setup from the stored backup files via the interactive menu.

---

## Tech Stack

- **Scripting Language**: Bash / POSIX Shell
- **Dependency Utilities**: Curl, Wget, Unzip, Tar, Composer, Git, PHP (Artisan)
- **Target Platform**: Pterodactyl Panel v1.x.x

---

## Prerequisites

To run the installer, your host environment must satisfy:
- **Operating System**: Linux/macOS with SSH / Terminal access.
- **Privileges**: Sudo / Root access (the script automatically escalates when run).
- **Core CLI Packages**: `curl`, `wget`, `unzip`, `tar`, `php`.
- **Yarn (Optional)**: For compiling Elipso React component assets on-the-fly.

---

## Getting Started

### 1. One-Liner Remote Run (Recommended)
You can run the installer on any production Pterodactyl server instantly without downloading it first:
```bash
bash <(curl -s https://raw.githubusercontent.com/instax-dutta/inspire-installer/main/install.sh)
```

### 2. Local Setup & Run
If you clone this repository to your panel server:
```bash
# Clone the repository
git clone https://github.com/instax-dutta/inspire-installer.git
cd inspire-installer

# Make the script executable
chmod +x install.sh

# Start the interactive installer
./install.sh
```

---

## Non-Interactive CLI Automation

The installer also supports non-interactive arguments, which is perfect for automated cron setup or DevOps pipelines:

| Option | Description |
|---|---|
| `--elden` | Directly installs Elden Theme (Sentri Dark) |
| `--elysium` | Directly installs Elysium Theme (Monospaced Dark) |
| `--elipso` | Directly installs Elipso Theme (Premium Vercel Skin) |
| `--restore-baseline` | Rebuilds panel core files back to the default Pterodactyl release |
| `--uninstall` | Opens the backup restoration menu |
| `--clear-cache` | Performs a full system cache purge |
| `-h, --help` | Displays the help menu and exit options |

### Example Automated Command:
```bash
./install.sh --elden
```

---

## Architecture & Data Flow

### Workspace Structure
```
/Users/saiduttaabhishekdash/inspire-installer/
  ├── install.sh                  # Core Installer Execution Script
  ├── elden-theme/                # Elden (Sentri Dark Theme) files
  ├── elysium/                    # Elysium (Monospaced Dark) files
  └── elipso-theme/               # Elipso (Vercel-like Skin) files
```

### Installation Lifecycle Flowchart
```
[User Selects Theme] ──➔ [Create Timestamped Backup] ──➔ [Resolve Local/Remote Files]
                                                                  │
[Complete Cache Eviction] ⮘── [Fix Folder Ownership] ⮘── [Copy Theme Assets & Configs]
```

### Under The Hood
1. **Source Resolution**: Checks if local `./<theme_name>` exists and contains views. If not, temporarily downloads the ZIP archive from GitHub.
2. **Asset Allocation**:
   - **Elden**: Installs templates and theme CSS tokens (`theme.css` / `tailwind.config.js`).
   - **Elysium**: Installs wrapper views, layouts, theme CSS, and precompiled production assets.
   - **Elipso**: Resets core files, inserts template blades, overwrites scripts layout folders, injects production assets, and compiles CSS/JS via Yarn.
3. **OPcache & Server Eviction**: Gracefully restarts or reloads web-server sockets, PHP-FPM, Supervisor queue workers, and clears Artisan views to flush all in-memory structures.

---

## Troubleshooting

### Error: `unzip: Command not found`
**Solution**: The installer requires `unzip` to parse remote theme bundles. Install it using your system package manager:
```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y unzip

# CentOS / RHEL
sudo dnf install -y unzip
```

### Error: `'yarn' CLI utility was not found`
**Solution**: The **Elipso Theme** recommends building React source files using Yarn. If Yarn is missing, the installer will warn you and inject working pre-built production assets. If you wish to build them live, install Yarn:
```bash
npm install --global yarn
```

### Error: `could not detect your Pterodactyl panel path`
**Solution**: If your Pterodactyl install directory is in a custom folder, pass the path directly or enter it into the interactive prompt. The installer looks for the folder containing the `artisan` configuration.

---

## Authors & Support
- **Author**: instax-dutta
- **Inspired by**: Premium web layouts and custom Pterodactyl gaming themes.
