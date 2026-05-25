# Elipso Vercel Dark Theme

Elipso is a Vercel-inspired dark-only theme for Pterodactyl Panel with a more premium, professional finish across the client and admin panel.

## What It Changes

- Geist and Geist Mono typography.
- Dark-only token system.
- Compact radii, restrained borders, and stronger functional hierarchy.
- Gradient atmosphere on authentication pages.
- Blade/admin panel overrides without a frontend rebuild.

## Install On A Panel Server

Upload this bundle to your Pterodactyl server, extract it, then run:

```bash
cd elipso-vercel-theme
sudo bash install.sh /var/www/pterodactyl
```

If your panel is somewhere else, pass that path instead.

The installer creates a backup, copies the theme views, CSS, and prebuilt client assets into place, clears Laravel caches, and fixes ownership when `www-data` exists. Node is not required.
