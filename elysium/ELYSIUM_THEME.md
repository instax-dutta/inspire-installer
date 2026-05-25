# Elysium Pterodactyl Theme

A terminal-native dark-only theme for Pterodactyl Panel — every character in JetBrains Mono, flat surfaces held apart by hairline rules, and the Apple HIG semantic ramp from the OpenCode-inspired design system.

## What It Changes

- JetBrains Mono typography across every UI role (button, label, table, badge, tab, input).
- Dark-only token system inverted from OpenCode's warm-cream light palette.
- Flat surfaces with 1px hairline borders — no drop shadows.
- 4px radius on all interactive elements; 0px on containers.
- Gradient mesh atmosphere on authentication pages (soft blue/violet tones against near-black).
- Blade/admin panel overrides without a frontend rebuild.

## Design Tokens

See `tailwind.config.js` for the design token reference.

## Install On A Panel Server

Upload this bundle to your Pterodactyl server, extract it, then run:

```bash
cd elysium
sudo bash install.sh /var/www/pterodactyl
```

If your panel is somewhere else, pass that path instead.

The installer creates a backup, copies the theme views, CSS, and prebuilt client assets into place, clears Laravel caches, and fixes ownership when `www-data` exists. Node is not required.
