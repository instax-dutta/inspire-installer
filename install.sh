#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚡ INSPIRE THEME INSTALLER — Unified Pterodactyl Theme Setup
# Designed and Crafted for absolute perfection, zero silent failures,
# comprehensive backups, and complete cache eviction.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# ─── Colors & TUI Elements ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Config & Constants ───────────────────────────────────────────────────────
BACKUP_ROOT="/var/www"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR=""

# Theme Metadata
ELDEN_NAME="elden-theme"
ELDEN_ID="sentri-pterodactyl-dark"
ELDEN_ZIP="https://github.com/instax-dutta/elden-theme/archive/refs/heads/main.zip"

ELYSIUM_NAME="elysium"
ELYSIUM_ID="elysium-dark"
ELYSIUM_ZIP="https://github.com/instax-dutta/elysium/archive/refs/heads/main.zip"

ELIPSO_NAME="elipso-theme"
ELIPSO_ID="elipso-vercel"
ELIPSO_ZIP="https://github.com/instax-dutta/elipso-theme/archive/refs/heads/main.zip"

# ─── Logging Helpers ─────────────────────────────────────────────────────────
log_info()    { printf "${CYAN}[ℹ] %s${RESET}\n" "$1" >&2; }
log_success() { printf "${GREEN}[✓] %s${RESET}\n" "$1" >&2; }
log_warn()    { printf "${YELLOW}[!] %s${RESET}\n" "$1" >&2; }
log_error()   { printf "${RED}[✗] %s${RESET}\n" "$1" >&2; }
die()         { log_error "$1"; exit 1; }

# Beautiful Banner
draw_banner() {
    clear
    printf "${CYAN}╭────────────────────────────────────────────────────────────╮${RESET}\n"
    printf "${CYAN}│${RESET}                                                            ${CYAN}│${RESET}\n"
    printf "${CYAN}│${RESET}   ${BOLD}${PURPLE}⚡  I N S P I R E   T H E M E   I N S T A L L E R  ⚡${RESET}   ${CYAN}│${RESET}\n"
    printf "${CYAN}│${RESET}         ${DIM}Perfect Unified Setup for Premium Skins${RESET}            ${CYAN}│${RESET}\n"
    printf "${CYAN}│${RESET}               ${DIM}Crafted by instax-dutta${RESET}                      ${CYAN}│${RESET}\n"
    printf "${CYAN}│${RESET}                                                            ${CYAN}│${RESET}\n"
    printf "${CYAN}╰────────────────────────────────────────────────────────────╯${RESET}\n"
    printf "\n"
}

# ─── Cleanup ──────────────────────────────────────────────────────────────────
_cleanup() {
    local rc=$?
    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    fi
    if [[ $rc -ne 0 ]]; then
        printf "\n"
        log_error "Installation interrupted or encountered an error. Status Code: $rc"
        log_info "Files in your backups directory remain completely safe."
    fi
}
trap _cleanup EXIT

# ─── Helper Functions ─────────────────────────────────────────────────────────
need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1. Please install it first."
}

sudo_run() {
    if [[ "${EUID}" -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

quietly() {
    "$@" >/dev/null 2>&1 || true
}

# ─── System Pre-flight Checks ─────────────────────────────────────────────────
pre_flight_checks() {
    log_info "Running system compatibility checks..."
    need_cmd awk
    need_cmd cp
    need_cmd grep
    need_cmd mktemp
    need_cmd unzip
    need_cmd curl
    need_cmd tar
    need_cmd php
    log_success "All critical commands are available on this host."
}

# ─── Panel Detection ──────────────────────────────────────────────────────────
detect_panel_dir() {
    local candidates=(
        /var/www/pterodactyl
        /var/www/panel
        /var/www/html/pterodactyl
        /var/www/html/panel
        /opt/pterodactyl
        /opt/panel
    )
    local dir
    for dir in "${candidates[@]}"; do
        if [[ -f "$dir/artisan" ]]; then
            printf '%s\n' "$dir"
            return
        fi
    done

    # Fallback to interactive prompt if panel folder not automatically found
    if [[ -t 0 ]]; then
        log_warn "Pterodactyl installation folder could not be auto-detected."
        local manual_path
        read -rp '    Enter the absolute path to your panel: ' manual_path
        if [[ -f "$manual_path/artisan" ]]; then
            printf '%s\n' "$manual_path"
            return
        fi
    fi

    die "Could not find a valid Pterodactyl directory containing 'artisan'."
}

# ─── Interactive Spinner ──────────────────────────────────────────────────────
run_with_spinner() {
    local message="$1"
    shift
    local pid
    # Run the actual command in background
    "$@" &
    pid=$!

    # Spin frame animation
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    tput civis # Hide cursor
    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r${CYAN}[%c]${RESET} %s..." "${spinstr:$i:1}" "$message"
            sleep $delay
        done
    done
    tput cnorm # Restore cursor
    wait $pid
    printf "\r\033[K"
}

# ─── Local or Remote Theme Resolver ───────────────────────────────────────────
resolve_theme_source() {
    local name="$1"
    local zip_url="$2"
    local local_dir="$SELF_PATH/$name"

    # 1. Check local directory (cloned repository setup)
    if [[ -d "$local_dir" && -f "$local_dir/resources/views/templates/wrapper.blade.php" ]]; then
        log_success "Found local source files for $name."
        printf '%s\n' "$local_dir"
        return
    fi

    # 2. Otherwise download remote ZIP bundle
    log_info "Local files for $name not found. Fetching from GitHub..."
    WORK_DIR="$(mktemp -d "/tmp/inspire-install-$name.XXXXXX")"
    local zip="$WORK_DIR/bundle.zip"
    local src="$WORK_DIR/src"

    run_with_spinner "Downloading $name bundle from GitHub" curl -fsSL "$zip_url" -o "$zip"
    run_with_spinner "Extracting zip archive" unzip -q "$zip" -d "$src"

    local extracted
    extracted="$(find "$src" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    if [[ -n "$extracted" && -f "$extracted/resources/views/templates/wrapper.blade.php" ]]; then
        printf '%s\n' "$extracted"
    else
        die "The downloaded bundle is corrupt or does not contain a valid theme directory structure."
    fi
}

# ─── Create Backup ────────────────────────────────────────────────────────────
create_backup() {
    local panel_dir="$1"
    local theme_id="$2"
    local backup_dir="$BACKUP_ROOT/inspire-backup-$theme_id-$(date +%Y%m%d-%H%M%S)"

    log_info "Creating a safe backup of panel config and files..."
    sudo_run mkdir -p "$backup_dir"

    # Save wrapper blade files
    if [[ -f "$panel_dir/resources/views/templates/wrapper.blade.php" ]]; then
        sudo_run cp -a "$panel_dir/resources/views/templates/wrapper.blade.php" "$backup_dir/wrapper.blade.php"
    fi
    if [[ -f "$panel_dir/resources/views/templates/base/core.blade.php" ]]; then
        sudo_run cp -a "$panel_dir/resources/views/templates/base/core.blade.php" "$backup_dir/core.blade.php"
    fi
    if [[ -f "$panel_dir/resources/views/layouts/admin.blade.php" ]]; then
        sudo_run cp -a "$panel_dir/resources/views/layouts/admin.blade.php" "$backup_dir/admin.blade.php"
    fi
    if [[ -f "$panel_dir/tailwind.config.js" ]]; then
        sudo_run cp -a "$panel_dir/tailwind.config.js" "$backup_dir/tailwind.config.js"
    fi

    # Save style folders
    if [[ -d "$panel_dir/public/themes/$theme_id" ]]; then
        sudo_run cp -a "$panel_dir/public/themes/$theme_id" "$backup_dir/"
    fi
    if [[ -d "$panel_dir/public/assets" ]]; then
        sudo_run cp -a "$panel_dir/public/assets" "$backup_dir/"
    fi

    log_success "Backup safely created at: $backup_dir"
    printf '%s\n' "$backup_dir"
}

# ─── Cache Eviction System ────────────────────────────────────────────────────
clear_caches() {
    local panel_dir="$1"
    log_info "Running comprehensive cache eviction routine..."

    # 1. Laravel Artisan commands
    if command -v php >/dev/null 2>&1; then
        log_info "Clearing Laravel views, configs, routes, and application caches..."
        sudo_run php "$panel_dir/artisan" view:clear --no-interaction --ansi || log_warn "artisan view:clear failed"
        sudo_run php "$panel_dir/artisan" route:clear --no-interaction --ansi || log_warn "artisan route:clear failed"
        sudo_run php "$panel_dir/artisan" config:clear --no-interaction --ansi || log_warn "artisan config:clear failed"
        sudo_run php "$panel_dir/artisan" cache:clear --no-interaction --ansi || log_warn "artisan cache:clear failed"
        sudo_run php "$panel_dir/artisan" optimize:clear --no-interaction --ansi || log_warn "artisan optimize:clear failed"
    fi

    # 2. PHP-FPM Opcache Reload
    log_info "Flushing PHP-FPM OPcache compiled memory structures..."
    local fpm_reloaded=0
    local svc
    for svc in php8.4-fpm php8.3-fpm php8.2-fpm php8.1-fpm php8.0-fpm php7.4-fpm php-fpm; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            if sudo_run systemctl reload "$svc" 2>/dev/null; then
                log_success "Reloaded $svc (OPcache flushed successfully)"
                fpm_reloaded=1
                break
            fi
        fi
    done
    if [[ $fpm_reloaded -eq 0 ]]; then
        if quietly pkill -SIGUSR2 -x php-fpm; then
            log_success "Sent SIGUSR2 to php-fpm master process (flushed OPcache)"
            fpm_reloaded=1
        fi
    fi

    # 3. Web Server Reloads
    log_info "Reloading active web servers gracefully..."
    local server_reloaded=0
    if systemctl is-active --quiet nginx 2>/dev/null; then
        if sudo_run systemctl reload nginx 2>/dev/null; then
            log_success "Nginx configuration and cache reloaded."
            server_reloaded=1
        fi
    fi
    for apache_svc in apache2 httpd; do
        if systemctl is-active --quiet "$apache_svc" 2>/dev/null; then
            if sudo_run systemctl reload "$apache_svc" 2>/dev/null; then
                log_success "Apache ($apache_svc) reloaded."
                server_reloaded=1
            fi
            break
        fi
    done

    # 4. Supervisor Queue Restart
    if command -v supervisorctl >/dev/null 2>&1; then
        log_info "Restarting Supervisor pteroq queue workers..."
        if quietly sudo_run supervisorctl restart 'pteroq:*' 2>/dev/null; then
            log_success "Queue workers restarted."
        fi
    fi

    # 5. Docker Containers Cache Clear
    if command -v docker >/dev/null 2>&1; then
        local containers
        mapfile -t containers < <(docker ps --format '{{.Names}}' 2>/dev/null | grep -E '^(pterodactyl|ptero|panel)' || true)
        for container in "${containers[@]}"; do
            log_info "Clearing internal cache for Docker container: $container"
            quietly docker exec "$container" php artisan view:clear
            quietly docker exec "$container" php artisan cache:clear
            quietly docker exec "$container" php artisan config:clear
            log_success "Docker container cache evicted."
        done
    fi

    log_success "Cache eviction routine completed."
}

# ─── Permissions Fixer ────────────────────────────────────────────────────────
fix_permissions() {
    local panel_dir="$1"
    local theme_id="$2"
    log_info "Aligning file permission attributes..."

    local web_user=""
    local candidate
    for candidate in www-data nginx apache caddy http nobody; do
        if id -u "$candidate" >/dev/null 2>&1; then
            web_user="$candidate"
            break
        fi
    done

    if [[ -n "$web_user" ]]; then
        sudo_run chown -R "$web_user:$web_user" "$panel_dir/resources/views" 2>/dev/null || true
        if [[ -d "$panel_dir/public/themes/$theme_id" ]]; then
            sudo_run chown -R "$web_user:$web_user" "$panel_dir/public/themes/$theme_id" 2>/dev/null || true
            sudo_run chmod -R a+r "$panel_dir/public/themes/$theme_id" 2>/dev/null || true
        fi
        if [[ -d "$panel_dir/public/assets" ]]; then
            sudo_run chown -R "$web_user:$web_user" "$panel_dir/public/assets" 2>/dev/null || true
            sudo_run chmod -R a+r "$panel_dir/public/assets" 2>/dev/null || true
        fi
        log_success "Permissions correctly reassigned to web user: $web_user"
    else
        log_warn "No common web server user found. Skipping automated chown. Permissions may need manual review."
    fi
}

# ─── Baseline Restorer ────────────────────────────────────────────────────────
restore_baseline() {
    local panel_dir="$1"
    log_warn "This operation will reset Pterodactyl Panel's core files back to the official default baseline."
    read -rp "    Are you absolutely sure you want to continue? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Baseline restore aborted."
        return
    fi

    log_info "Putting panel into maintenance mode..."
    sudo_run php "$panel_dir/artisan" down || true

    log_info "Downloading latest Pterodactyl release..."
    WORK_DIR="$(mktemp -d "/tmp/baseline-restore.XXXXXX")"
    local tarball="$WORK_DIR/panel.tar.gz"

    run_with_spinner "Downloading panel tarball" curl -L "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz" -o "$tarball"
    
    log_info "Extracting clean release files over the panel..."
    sudo_run tar -xzf "$tarball" -C "$panel_dir"

    log_info "Configuring default folder permissions..."
    cd "$panel_dir"
    sudo_run chmod -R 755 storage/* bootstrap/cache

    log_info "Running composer dependency optimization..."
    run_with_spinner "Composer installation" sudo_run composer install --no-dev --optimize-autoloader

    log_info "Updating database structures & running seed updates..."
    sudo_run php "$panel_dir/artisan" migrate --seed --force

    log_info "Flushing cached configurations..."
    sudo_run php "$panel_dir/artisan" view:clear
    sudo_run php "$panel_dir/artisan" config:clear

    log_info "Restarting pteroq queue processes..."
    sudo_run php "$panel_dir/artisan" queue:restart

    fix_permissions "$panel_dir" "default"
    
    log_info "Taking panel out of maintenance mode..."
    sudo_run php "$panel_dir/artisan" up || true

    log_success "Pterodactyl Panel core has been completely restored to official baseline!"
    log_info "Reloading system services..."
    sudo_run systemctl restart nginx redis-server pteroq 2>/dev/null || true
    
    printf "\n"
    read -rp "Press Enter to return to the main menu..." dummy
}

# ─── Install Elden Theme ──────────────────────────────────────────────────────
install_elden() {
    local panel_dir="$1"
    draw_banner
    printf "${BOLD}${PURPLE}⚡  Installing Elden Theme (Sentri Dark)${RESET}\n\n"

    local src
    src="$(resolve_theme_source "$ELDEN_NAME" "$ELDEN_ZIP")"

    create_backup "$panel_dir" "$ELDEN_ID"

    log_info "Copying Sentri template wrapper file..."
    sudo_run mkdir -p "$panel_dir/resources/views/templates"
    sudo_run cp -a "$src/resources/views/templates/wrapper.blade.php" "$panel_dir/resources/views/templates/wrapper.blade.php"

    log_info "Copying Sentri stylesheet styles..."
    sudo_run mkdir -p "$panel_dir/public/themes/$ELDEN_ID"
    sudo_run cp -a "$src/public/themes/$ELDEN_ID/theme.css" "$panel_dir/public/themes/$ELDEN_ID/theme.css"

    if [[ -f "$src/tailwind.config.js" ]]; then
        log_info "Updating panel tailwind configuration file..."
        sudo_run cp -a "$src/tailwind.config.js" "$panel_dir/tailwind.config.js"
    fi

    # Verify installation integrity
    if [[ ! -f "$panel_dir/resources/views/templates/wrapper.blade.php" ]] || \
       [[ ! -f "$panel_dir/public/themes/$ELDEN_ID/theme.css" ]]; then
        die "Verification failed. Crucial theme files are missing from the panel directories."
    fi

    fix_permissions "$panel_dir" "$ELDEN_ID"
    clear_caches "$panel_dir"

    printf "\n"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success " Elden Theme (Sentri Pterodactyl Dark) Installed Successfully!"
    log_info " Theme ID:  $ELDEN_ID"
    log_info " Target:    $panel_dir"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "\n"
    log_info "Please hard refresh your browser (Ctrl+Shift+R) to load new theme styles."
    printf "\n"
    read -rp "Press Enter to return to the main menu..." dummy
}

# ─── Install Elysium Theme ────────────────────────────────────────────────────
install_elysium() {
    local panel_dir="$1"
    draw_banner
    printf "${BOLD}${PURPLE}⚡  Installing Elysium Theme (Monospaced Dark)${RESET}\n\n"

    local src
    src="$(resolve_theme_source "$ELYSIUM_NAME" "$ELYSIUM_ZIP")"

    create_backup "$panel_dir" "$ELYSIUM_ID"

    log_info "Creating views layouts directory hierarchy..."
    sudo_run install -d "$panel_dir/resources/views/templates/base"
    sudo_run install -d "$panel_dir/resources/views/layouts"
    sudo_run install -d "$panel_dir/public/themes/$ELYSIUM_ID"

    log_info "Copying Elysium custom blade views templates..."
    sudo_run install -m 0644 "$src/resources/views/templates/wrapper.blade.php" "$panel_dir/resources/views/templates/wrapper.blade.php"
    sudo_run install -m 0644 "$src/resources/views/templates/base/core.blade.php" "$panel_dir/resources/views/templates/base/core.blade.php"
    sudo_run install -m 0644 "$src/resources/views/layouts/admin.blade.php" "$panel_dir/resources/views/layouts/admin.blade.php"

    log_info "Copying Elysium theme stylesheet config files..."
    sudo_run install -m 0644 "$src/public/themes/$ELYSIUM_ID/elysium.css" "$panel_dir/public/themes/$ELYSIUM_ID/elysium.css"
    sudo_run install -m 0644 "$src/public/themes/$ELYSIUM_ID/theme.css" "$panel_dir/public/themes/$ELYSIUM_ID/theme.css"

    # If the bundle contains a custom precompiled React bundle directory, replace the assets folder
    if [[ -d "$src/public/assets" ]] && [[ -f "$src/public/assets/manifest.json" ]]; then
        log_info "Injecting prebuilt Elysium production React components assets..."
        local assets_tmp="$panel_dir/public/assets.elysium.$$"
        sudo_run rm -rf "$assets_tmp"
        sudo_run mkdir -p "$assets_tmp"
        sudo_run cp -a "$src/public/assets/." "$assets_tmp/"
        sudo_run rm -rf "$panel_dir/public/assets"
        sudo_run mv "$assets_tmp" "$panel_dir/public/assets"
    fi

    # Verify installation integrity
    if [[ ! -f "$panel_dir/resources/views/templates/wrapper.blade.php" ]] || \
       [[ ! -f "$panel_dir/public/themes/$ELYSIUM_ID/elysium.css" ]]; then
        die "Verification failed. Elysium theme files are missing from the panel directories."
    fi

    fix_permissions "$panel_dir" "$ELYSIUM_ID"
    clear_caches "$panel_dir"

    printf "\n"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success " Elysium Theme Installed Successfully!"
    log_info " Theme ID:  $ELYSIUM_ID"
    log_info " Target:    $panel_dir"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "\n"
    log_info "Please hard refresh your browser (Ctrl+Shift+R) to load new theme assets."
    printf "\n"
    read -rp "Press Enter to return to the main menu..." dummy
}

# ─── Install Elipso Theme ─────────────────────────────────────────────────────
install_elipso() {
    local panel_dir="$1"
    draw_banner
    printf "${BOLD}${PURPLE}⚡  Installing Elipso Theme (Premium Vercel Skin)${RESET}\n\n"

    local src
    src="$(resolve_theme_source "$ELIPSO_NAME" "$ELIPSO_ZIP")"

    # Ask the user if they want to reset to baseline first to guarantee a flawless install
    printf "    Elipso requires replacing Pterodactyl's core scripts and layouts.\n"
    printf "    It is highly recommended to establish a clean panel baseline before proceeding.\n\n"
    read -rp "    Establish a clean panel baseline first? [Y/n]: " setup_baseline
    if [[ "$setup_baseline" != "n" && "$setup_baseline" != "N" ]]; then
        restore_baseline "$panel_dir"
    fi

    create_backup "$panel_dir" "$ELIPSO_ID"

    log_info "Creating views layouts directory hierarchy..."
    sudo_run install -d "$panel_dir/resources/views/templates/base"
    sudo_run install -d "$panel_dir/resources/views/layouts"
    sudo_run install -d "$panel_dir/public/themes/$ELIPSO_ID"

    log_info "Copying Elipso custom blade views templates..."
    sudo_run install -m 0644 "$src/resources/views/templates/wrapper.blade.php" "$panel_dir/resources/views/templates/wrapper.blade.php"
    sudo_run install -m 0644 "$src/resources/views/templates/base/core.blade.php" "$panel_dir/resources/views/templates/base/core.blade.php"
    sudo_run install -m 0644 "$src/resources/views/layouts/admin.blade.php" "$panel_dir/resources/views/layouts/admin.blade.php"

    log_info "Copying Elipso theme stylesheet config files..."
    sudo_run install -m 0644 "$src/public/themes/$ELIPSO_ID/elipso.css" "$panel_dir/public/themes/$ELIPSO_ID/elipso.css"
    sudo_run install -m 0644 "$src/public/themes/$ELIPSO_ID/theme.css" "$panel_dir/public/themes/$ELIPSO_ID/theme.css"

    log_info "Injecting React component source layouts..."
    sudo_run mkdir -p "$panel_dir/resources/scripts"
    sudo_run cp -r "$src/resources/scripts/." "$panel_dir/resources/scripts/"

    # Prebuilt assets fallback
    if [[ -d "$src/public/assets" ]] && [[ -f "$src/public/assets/manifest.json" ]]; then
        log_info "Found precompiled Elipso production React components assets. Injecting..."
        local assets_tmp="$panel_dir/public/assets.elipso.$$"
        sudo_run rm -rf "$assets_tmp"
        sudo_run mkdir -p "$assets_tmp"
        sudo_run cp -a "$src/public/assets/." "$assets_tmp/"
        sudo_run rm -rf "$panel_dir/public/assets"
        sudo_run mv "$assets_tmp" "$panel_dir/public/assets"
    fi

    # Compile files if Yarn is available
    if command -v yarn >/dev/null 2>&1; then
        log_info "Yarn installation found on host. Initiating full server-side React webpack compilation..."
        cd "$panel_dir"
        export NODE_OPTIONS=--openssl-legacy-provider
        run_with_spinner "Compiling theme production assets" sudo_run yarn install
        run_with_spinner "Building production web assets" sudo_run yarn build:production
    else
        log_warn "'yarn' CLI utility was not found. Skipping live server-side asset compilation."
        log_warn "Prebuilt theme assets were injected. They should work perfectly."
        log_warn "If modifications are needed, please run 'yarn install && yarn build:production' inside your panel folder."
    fi

    # Verify installation integrity
    if [[ ! -f "$panel_dir/resources/views/templates/wrapper.blade.php" ]] || \
       [[ ! -f "$panel_dir/public/themes/$ELIPSO_ID/elipso.css" ]]; then
        die "Verification failed. Elipso theme files are missing from the panel directories."
    fi

    fix_permissions "$panel_dir" "$ELIPSO_ID"
    clear_caches "$panel_dir"

    printf "\n"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success " Elipso Theme (Premium Vercel Skin) Installed Successfully!"
    log_info " Theme ID:  $ELIPSO_ID"
    log_info " Target:    $panel_dir"
    log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "\n"
    log_info "Please hard refresh your browser (Ctrl+Shift+R) to load new theme layouts."
    printf "\n"
    read -rp "Press Enter to return to the main menu..." dummy
}

# ─── Uninstall & Restore Backups ──────────────────────────────────────────────
uninstall_menu() {
    local panel_dir="$1"
    draw_banner
    printf "${BOLD}${RED}⚡  Uninstall Themes & Restore Backups${RESET}\n\n"

    log_info "Searching for existing backups in $BACKUP_ROOT..."
    local backups=()
    mapfile -t backups < <(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "inspire-backup-*" -o -name "sentri-theme-backup-*" -o -name "elysium-backup-*" -o -name "elipso-backup-*" 2>/dev/null | sort -r || true)

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_warn "No backups found under $BACKUP_ROOT."
        log_info "To clean install a fresh theme, please choose 'Restore Default Panel Baseline' from the main menu."
        printf "\n"
        read -rp "Press Enter to return to the main menu..." dummy
        return
    fi

    printf "    Select a backup to restore:\n\n"
    local i
    for i in "${!backups[@]}"; do
        local b_name
        b_name="$(basename "${backups[$i]}")"
        printf "    [${CYAN}%d${RESET}]  %s\n" $((i+1)) "$b_name"
    done
    printf "    [${CYAN}c${RESET}]  Cancel\n\n"

    read -rp "    Enter option [1-${#backups[@]}]: " choice
    if [[ "$choice" == "c" || "$choice" == "C" ]]; then
        return
    fi

    if [[ "$choice" -ge 1 && "$choice" -le ${#backups[@]} ]]; then
        local chosen_backup="${backups[$((choice-1))]}"
        log_info "Restoring files from: $chosen_backup..."

        # Restore templates
        if [[ -f "$chosen_backup/wrapper.blade.php" ]]; then
            sudo_run cp -a "$chosen_backup/wrapper.blade.php" "$panel_dir/resources/views/templates/wrapper.blade.php"
        fi
        if [[ -f "$chosen_backup/core.blade.php" ]]; then
            sudo_run cp -a "$chosen_backup/core.blade.php" "$panel_dir/resources/views/templates/base/core.blade.php"
        fi
        if [[ -f "$chosen_backup/admin.blade.php" ]]; then
            sudo_run cp -a "$chosen_backup/admin.blade.php" "$panel_dir/resources/views/layouts/admin.blade.php"
        fi
        if [[ -f "$chosen_backup/tailwind.config.js" ]]; then
            sudo_run cp -a "$chosen_backup/tailwind.config.js" "$panel_dir/tailwind.config.js"
        fi

        # Restore style files
        if [[ -d "$chosen_backup/$ELDEN_ID" ]]; then
            sudo_run rm -rf "$panel_dir/public/themes/$ELDEN_ID"
            sudo_run cp -a "$chosen_backup/$ELDEN_ID" "$panel_dir/public/themes/"
        fi
        if [[ -d "$chosen_backup/$ELYSIUM_ID" ]]; then
            sudo_run rm -rf "$panel_dir/public/themes/$ELYSIUM_ID"
            sudo_run cp -a "$chosen_backup/$ELYSIUM_ID" "$panel_dir/public/themes/"
        fi
        if [[ -d "$chosen_backup/$ELIPSO_ID" ]]; then
            sudo_run rm -rf "$panel_dir/public/themes/$ELIPSO_ID"
            sudo_run cp -a "$chosen_backup/$ELIPSO_ID" "$panel_dir/public/themes/"
        fi
        if [[ -d "$chosen_backup/assets" ]]; then
            sudo_run rm -rf "$panel_dir/public/assets"
            sudo_run cp -a "$chosen_backup/assets" "$panel_dir/public/"
        fi

        # Remove public themes if clean uninstall
        sudo_run rm -rf "$panel_dir/public/themes/$ELDEN_ID"
        sudo_run rm -rf "$panel_dir/public/themes/$ELYSIUM_ID"
        sudo_run rm -rf "$panel_dir/public/themes/$ELIPSO_ID"

        clear_caches "$panel_dir"
        log_success "Backup restored successfully. Panels styles reverted."
    else
        log_error "Invalid selection."
    fi

    printf "\n"
    read -rp "Press Enter to return..." dummy
}

# ─── Main Menu Loop ───────────────────────────────────────────────────────────
interactive_menu() {
    local panel_dir
    panel_dir="$(detect_panel_dir)"

    while true; do
        draw_banner
        printf "    ${BOLD}Pterodactyl Panel detected at:${RESET} ${CYAN}%s${RESET}\n\n" "$panel_dir"
        printf "    [${CYAN}1${RESET}]  Install Elden Theme (Sentri Dark)\n"
        printf "    [${CYAN}2${RESET}]  Install Elysium Theme (Monospaced Dark)\n"
        printf "    [${CYAN}3${RESET}]  Install Elipso Theme (Premium Vercel Skin)\n"
        printf "    [${CYAN}4${RESET}]  Restore Default Panel Baseline (Clean Core Rebuild)\n"
        printf "    [${CYAN}5${RESET}]  Uninstall Themes / Restore Previous Backups\n"
        printf "    [${CYAN}6${RESET}]  Force System Cache Eviction (Artisan, FPM, Webservers)\n"
        printf "    [${CYAN}7${RESET}]  Exit\n\n"

        read -rp "    Enter your option [1-7]: " menu_option
        case "$menu_option" in
            1) install_elden "$panel_dir" ;;
            2) install_elysium "$panel_dir" ;;
            3) install_elipso  "$panel_dir" ;;
            4) restore_baseline "$panel_dir" ;;
            5) uninstall_menu "$panel_dir" ;;
            6) clear_caches "$panel_dir"
               printf "\n"
               read -rp "Press Enter to return..." dummy ;;
            7) log_success "Thank you for using Inspire Theme Installer. Have a beautiful day!"
               exit 0 ;;
            *) log_error "Invalid menu selection. Please choose a number from 1 to 7."
               sleep 1.5 ;;
        esac
    done
}

# ─── Main Entry Point ─────────────────────────────────────────────────────────
main() {
    pre_flight_checks

    # Check for CLI arguments first
    if [[ $# -gt 0 ]]; then
        local action="${1:-}"
        local panel_dir
        panel_dir="$(detect_panel_dir)"

        case "$action" in
            --elden|--install-elden)
                install_elden "$panel_dir" ;;
            --elysium|--install-elysium)
                install_elysium "$panel_dir" ;;
            --elipso|--install-elipso)
                install_elipso "$panel_dir" ;;
            --restore-baseline)
                restore_baseline "$panel_dir" ;;
            --uninstall)
                uninstall_menu "$panel_dir" ;;
            --clear-cache)
                clear_caches "$panel_dir" ;;
            --help|-h)
                printf "⚡ Unified Pterodactyl Theme Installer Help Menu\n\n"
                printf "Usage: bash install.sh [option]\n\n"
                printf "Options:\n"
                printf "  --elden            Installs Elden Theme (Sentri Dark) directly\n"
                printf "  --elysium          Installs Elysium Theme directly\n"
                printf "  --elipso           Installs Elipso Theme directly\n"
                printf "  --restore-baseline Restores panel to official Pterodactyl core files\n"
                printf "  --uninstall        Opens backup restoration menu\n"
                printf "  --clear-cache      Performs full cache eviction directly\n"
                printf "  -h, --help         Show this message\n"
                exit 0 ;;
            *)
                die "Unknown parameter: $action. Use --help to view options." ;;
        esac
        exit 0
    fi

    # Fallback to interactive mode if no arguments are provided
    interactive_menu
}

main "$@"
