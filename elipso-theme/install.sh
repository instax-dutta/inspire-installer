#!/usr/bin/env bash
set -euo pipefail

REPO_ZIP_URL="${REPO_ZIP_URL:-https://github.com/instax-dutta/elipso-theme/archive/refs/heads/main.zip}"
DEFAULT_TMP_DIR="${TMPDIR:-/tmp}"
SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '[elipso] %s\n' "$1" >&2
}

die() {
    printf '[elipso] Error: %s\n' "$1" >&2
    exit 1
}

sudo_cmd() {
    if [[ "${EUID}" -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

detect_panel_dir() {
    local explicit="${1:-}"
    if [[ -n "$explicit" ]]; then
        [[ -f "$explicit/artisan" ]] || die "no artisan file found in $explicit"
        printf '%s\n' "$explicit"
        return
    fi

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

    die "could not detect your Pterodactyl panel path automatically; rerun with: bash install.sh /path/to/panel"
}

download_bundle() {
    local workdir="$1"
    local zip_path="$workdir/elipso-theme.zip"
    local src_dir="$workdir/src"

    log "downloading latest Elipso bundle"
    need_cmd unzip

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_ZIP_URL" -o "$zip_path"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$zip_path" "$REPO_ZIP_URL"
    else
        die "install curl or wget first"
    fi

    unzip -q "$zip_path" -d "$src_dir"

    local extracted
    extracted="$(find "$src_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
    [[ -n "$extracted" ]] || die "downloaded archive did not contain a theme directory"
    printf '%s\n' "$extracted"
}

resolve_source_dir() {
    if [[ -f "$SELF_PATH/resources/views/templates/wrapper.blade.php" ]]; then
        printf '%s\n' "$SELF_PATH"
        return
    fi

    local workdir src_dir
    workdir="$(mktemp -d "$DEFAULT_TMP_DIR/elipso-install.XXXXXX")"
    src_dir="$(download_bundle "$workdir")"
    [[ -f "$src_dir/resources/views/templates/wrapper.blade.php" ]] || die "theme bundle is missing resources/views/templates/wrapper.blade.php"
    printf '%s\n' "$src_dir"
}

backup_files() {
    local panel_dir="$1"
    local backup_dir="$2"

    sudo_cmd mkdir -p "$backup_dir"

    [[ -f "$panel_dir/resources/views/templates/wrapper.blade.php" ]] && sudo_cmd cp -a "$panel_dir/resources/views/templates/wrapper.blade.php" "$backup_dir/wrapper.blade.php"
    [[ -f "$panel_dir/resources/views/templates/base/core.blade.php" ]] && sudo_cmd cp -a "$panel_dir/resources/views/templates/base/core.blade.php" "$backup_dir/core.blade.php"
    [[ -f "$panel_dir/resources/views/layouts/admin.blade.php" ]] && sudo_cmd cp -a "$panel_dir/resources/views/layouts/admin.blade.php" "$backup_dir/admin.blade.php"
    [[ -d "$panel_dir/public/themes/elipso-vercel" ]] && sudo_cmd cp -a "$panel_dir/public/themes/elipso-vercel" "$backup_dir/"
    [[ -d "$panel_dir/public/assets" ]] && sudo_cmd cp -a "$panel_dir/public/assets" "$backup_dir/"
}

install_theme() {
    local source_dir="$1"
    local panel_dir="$2"
    local assets_tmp=""

    sudo_cmd install -d "$panel_dir/resources/views/templates/base"
    sudo_cmd install -d "$panel_dir/resources/views/layouts"
    sudo_cmd install -d "$panel_dir/public/themes/elipso-vercel"

    sudo_cmd install -m 0644 "$source_dir/resources/views/templates/wrapper.blade.php" "$panel_dir/resources/views/templates/wrapper.blade.php"
    sudo_cmd install -m 0644 "$source_dir/resources/views/templates/base/core.blade.php" "$panel_dir/resources/views/templates/base/core.blade.php"
    sudo_cmd install -m 0644 "$source_dir/resources/views/layouts/admin.blade.php" "$panel_dir/resources/views/layouts/admin.blade.php"
    sudo_cmd install -m 0644 "$source_dir/public/themes/elipso-vercel/elipso.css" "$panel_dir/public/themes/elipso-vercel/elipso.css"
    sudo_cmd install -m 0644 "$source_dir/public/themes/elipso-vercel/theme.css" "$panel_dir/public/themes/elipso-vercel/theme.css"

    log "copying React component source files..."
    sudo_cmd mkdir -p "$panel_dir/resources/scripts"
    sudo_cmd cp -r "$source_dir/resources/scripts/." "$panel_dir/resources/scripts/"

    if [[ -d "$source_dir/public/assets" ]] && [[ -f "$source_dir/public/assets/manifest.json" ]]; then
        assets_tmp="$panel_dir/public/assets.elipso.$$"
        sudo_cmd rm -rf "$assets_tmp"
        sudo_cmd mkdir -p "$assets_tmp"
        sudo_cmd cp -a "$source_dir/public/assets/." "$assets_tmp/"
        sudo_cmd rm -rf "$panel_dir/public/assets"
        sudo_cmd mv "$assets_tmp" "$panel_dir/public/assets"
    fi
}

clear_panel_cache() {
    local panel_dir="$1"

    log "clearing Laravel caches"
    sudo_cmd php "$panel_dir/artisan" view:clear >/dev/null || true
    sudo_cmd php "$panel_dir/artisan" cache:clear >/dev/null || true
    sudo_cmd php "$panel_dir/artisan" config:clear >/dev/null || true
    sudo_cmd php "$panel_dir/artisan" optimize:clear >/dev/null || true
}

fix_permissions() {
    local panel_dir="$1"
    if id -u www-data >/dev/null 2>&1; then
        sudo_cmd chown -R www-data:www-data "$panel_dir/resources/views" "$panel_dir/public/themes/elipso-vercel" "$panel_dir/public/assets" >/dev/null 2>&1 || true
    fi
}

restore_default_panel() {
    local panel_dir="$1"
    log "restoring panel to default files to ensure default theme baseline"
    
    cd "$panel_dir"
    sudo_cmd php artisan down || true
    
    log "downloading and extracting latest panel release files..."
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | sudo_cmd tar -xzv
    
    log "setting baseline folder permissions..."
    sudo_cmd chmod -R 755 storage/* bootstrap/cache
    
    log "running composer installation..."
    sudo_cmd composer install --no-dev --optimize-autoloader
    
    log "clearing Laravel caches..."
    sudo_cmd php artisan view:clear
    sudo_cmd php artisan config:clear
    
    log "running database migrations..."
    sudo_cmd php artisan migrate --seed --force
    
    log "setting ownership permissions to www-data..."
    if id -u www-data >/dev/null 2>&1; then
        sudo_cmd chown -R www-data:www-data "$panel_dir"/* >/dev/null 2>&1 || true
    fi
    
    log "restarting queue workers..."
    sudo_cmd php artisan queue:restart
    sudo_cmd php artisan up
    
    log "restarting nginx, redis-server, and pteroq systemctl services..."
    sudo_cmd systemctl restart nginx redis-server pteroq || true
}

build_assets() {
    local panel_dir="$1"
    
    # Check if yarn command is available on target system
    if command -v yarn >/dev/null 2>&1; then
        log "installing node dependencies and compiling production assets inside panel"
        cd "$panel_dir"
        
        # Set OpenSSL legacy provider to ensure compatibility with Webpack
        export NODE_OPTIONS=--openssl-legacy-provider
        
        sudo_cmd yarn install
        sudo_cmd yarn build:production
    else
        log "WARNING: 'yarn' command not found. Skipping server-side compilation."
        log "Please run 'yarn install && yarn build:production' inside $panel_dir manually to compile React components."
    fi
}

main() {
    need_cmd php
    need_cmd cp
    need_cmd install
    need_cmd curl
    need_cmd tar
    need_cmd composer

    local panel_dir
    panel_dir="$(detect_panel_dir "${1:-}")"

    local source_dir
    source_dir="$(resolve_source_dir)"

    local backup_dir="/var/www/elipso-backup-$(date +%Y%m%d-%H%M%S)"

    log "panel detected at $panel_dir"
    log "creating backup at $backup_dir"
    backup_files "$panel_dir" "$backup_dir"

    restore_default_panel "$panel_dir"

    log "installing theme files"
    install_theme "$source_dir" "$panel_dir"
    
    build_assets "$panel_dir"
    
    clear_panel_cache "$panel_dir"
    fix_permissions "$panel_dir"

    log "install complete"
    printf '\n'
    printf 'Panel:   %s\n' "$panel_dir"
    printf 'Backup:  %s\n' "$backup_dir"
    printf 'Theme:   dark-only premium panel skin enabled\n'
    printf '\n'
    printf 'Next: hard refresh your browser once to load the new assets and styles.\n'
}

main "$@"
