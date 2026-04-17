# Omarchy Theme Configuration Guide

How the theming system works, what files to edit, and how to customize the desktop appearance.

## Architecture Overview

Omarchy uses a **centralized theme system**. One theme definition propagates colors and styles across all integrated applications: Waybar, Hyprland, terminals (Alacritty/Kitty/Ghostty), Neovim, btop, mako, walker, and more.

```
~/.config/omarchy/current/theme/    <-- active theme (symlinked)
├── waybar.css          Colors for the status bar
├── hyprland.conf       Window border colors
├── colors.toml         Full 16-color palette + accent/cursor/bg/fg
├── alacritty.toml      Terminal colors
├── kitty.conf
├── ghostty.conf
├── neovim.lua          Editor colorscheme
├── btop.theme
├── mako.ini            Notification colors
├── walker.css          Launcher theme
├── obsidian.css
├── vscode.json
├── chromium.theme
├── icons.theme
├── keyboard.rgb
└── backgrounds/        Wallpapers bundled with the theme
```

### How Theme Switching Works

The directory `~/.config/omarchy/current/theme/` is a symlink pointing to the active theme. Built-in themes live in `~/.local/share/omarchy/themes/`, custom-installed themes in `~/.config/omarchy/themes/`. Switching a theme re-points this symlink, and every app that imports from it picks up the new colors automatically.

The active theme name is stored in `~/.config/omarchy/current/theme.name`.

## Color Definitions

Each theme provides two color sources:

### `waybar.css` — Waybar-specific variables

```css
@define-color foreground #cdd6f4;
@define-color background #181824;
```

These GTK CSS variables are used throughout `style.css` via `@foreground` and `@background`.

### `colors.toml` — Full palette

```toml
accent = "#89b4fa"
cursor = "#f5e0dc"
foreground = "#cdd6f4"
background = "#1e1e2e"
selection_foreground = "#1e1e2e"
selection_background = "#f5e0dc"

color0  = "#45475a"   # Black
color1  = "#f38ba8"   # Red
color2  = "#a6e3a1"   # Green
color3  = "#f9e2af"   # Yellow
color4  = "#89b4fa"   # Blue
color5  = "#f5c2e7"   # Magenta
color6  = "#94e2d5"   # Cyan
color7  = "#bac2de"   # White
color8  = "#585b70"   # Bright Black
color9  = "#f38ba8"   # Bright Red
color10 = "#a6e3a1"   # Bright Green
color11 = "#f9e2af"   # Bright Yellow
color12 = "#89b4fa"   # Bright Blue
color13 = "#f5c2e7"   # Bright Magenta
color14 = "#94e2d5"   # Bright Cyan
color15 = "#a6adc8"   # Bright White
```

Used by terminals, editors, and other apps that consume TOML configs.

### `hyprland.conf` — Window manager colors

```
$activeBorderColor = rgb(89b4fa)

general {
    col.active_border = $activeBorderColor
}

group {
    col.border_active = $activeBorderColor
}
```

Sourced by Hyprland after the default config and before user overrides.

## Waybar Components

### File Roles

| File | Location | Managed by | Purpose |
|---|---|---|---|
| `config.jsonc` | `~/.config/waybar/` | dotfiles repo (stow) | Bar layout, modules, behavior |
| `style.css` | `~/.config/waybar/` | manual (not in repo) | Visual styling, shapes, animations |
| `waybar.css` | `~/.config/omarchy/current/theme/` | theme system | Color variables only |

### config.jsonc — Layout & Modules

Defines what appears on the bar and how modules behave.

**Bar properties:**
```jsonc
{
  "reload_style_on_change": true,   // hot-reload CSS on save
  "layer": "top",                   // render above windows
  "position": "top",                // bar at top of screen
  "spacing": 0,
  "height": 26
}
```

**Module placement** — three zones:

```
┌─────────────────────────────────────────────────────────────┐
│  LEFT            │     CENTER          │        RIGHT        │
│  omarchy-icon    │     clock           │    tray  bt  net    │
│  workspaces      │     update          │    audio cpu bat    │
│                  │     rec-indicator   │                     │
└─────────────────────────────────────────────────────────────┘
```

```jsonc
"modules-left": ["custom/omarchy", "hyprland/workspaces"],
"modules-center": ["clock", "custom/update", "custom/screenrecording-indicator"],
"modules-right": ["group/tray-expander", "bluetooth", "network", "pulseaudio", "cpu", "battery"]
```

**Workspace mapping** — dual-monitor setup with remapped labels:

```jsonc
"hyprland/workspaces": {
  "all-outputs": false,               // each monitor shows only its workspaces
  "format-icons": {
    "1": "1", "2": "2", "3": "3", "4": "4", "5": "5",
    "6": "1", "7": "2", "8": "3", "9": "4", "10": "5",  // HDMI shows as 1-5
    "active": "󱓻"
  },
  "persistent-workspaces": {
    "eDP-1": [1, 2, 3, 4, 5],
    "HDMI-A-1": [6, 7, 8, 9, 10]
  }
}
```

### style.css — Visual Styling

The first line imports theme colors; everything else is custom styling:

```css
@import "../omarchy/current/theme/waybar.css";
```

This makes `@foreground` and `@background` available throughout the stylesheet.

**Key visual patterns:**

```css
/* Rounded pill shape on all containers */
border-radius: 24px;

/* Semi-transparent backgrounds using theme color */
background-color: alpha(@background, 0.9);

/* Border using theme foreground */
border: 2px solid alpha(@foreground, 0.8);

/* Gradient hover effect */
background: linear-gradient(180deg, @background 75%, @foreground);

/* Module opacity */
opacity: 0.95;
```

**CSS structure by section:**

| Section | Selectors | What it controls |
|---|---|---|
| Global | `*` | Font family, size, weight |
| Waybar window | `window#waybar` | Bar background gradient, border-radius |
| Sub-groups | `#left1`, `#left2` | Module group containers (if using groups) |
| Module zones | `.modules-center`, `.modules-right` | Zone-level borders, opacity, radius |
| Workspaces | `#workspaces`, `#workspaces button` | Pill-shaped workspace buttons, active/empty/hover states |
| General modules | `#cpu`, `#clock`, `#battery`, etc. | Spacing, padding for individual modules |
| Hover states | `#clock:hover`, `#cpu:hover`, etc. | Gradient highlight on hover |
| Tray | `#group-tray-expander`, `#tray` | Expandable system tray drawer |
| Tooltip | `tooltip`, `tooltip label` | Popup tooltip styling |
| Animations | `@keyframes blink`, `blink-recording`, `blink-inhibitor` | Blinking effects for recording/idle indicators |

**Workspace button states:**

```css
/* Normal workspace with a window */
button        → background: alpha(@foreground, 0.5), color: @background

/* Currently focused workspace */
button.active → background: alpha(@foreground, 0.9), opacity: 1.0

/* Empty workspace (no windows) */
button.empty  → opacity: 0.45, border: 1px groove

/* Hover */
button:hover  → gradient background
```

### Animations

Three `@keyframes` definitions for status indicators:

- **`blink`** — MPRIS (media): fades text to `#4a4a4a` over 3s, alternating
- **`blink-recording`** — Screen recording: flashes `#eb7087` ↔ background at 0.5s
- **`blink-inhibitor`** — Idle inhibitor: pulses `#178b76` ↔ background at 1s

## Available Themes

Built-in (in `~/.local/share/omarchy/themes/`):

| Theme | Style |
|---|---|
| catppuccin | Warm pastels on dark blue (current) |
| catppuccin-latte | Light variant of catppuccin |
| ethereal | |
| everforest | Earthy greens on dark |
| flexoki-light | Light warm tones |
| gruvbox | Retro warm colors |
| hackerman | |
| kanagawa | Japanese-inspired palette |
| matte-black | Minimal dark |
| miasma | |
| nord | Cool blues, arctic tones |
| osaka-jade | |
| ristretto | |
| rose-pine | Muted pinks and purples |
| tokyo-night | Dark with vibrant accents |
| vantablack | Pure black |
| white | Light theme |

Custom themes can be installed with:
```sh
omarchy-theme-install <git-url>
```

Custom themes are stored in `~/.config/omarchy/themes/`.

## How to Customize

### Change the active theme

Use the Omarchy menu or install/switch via CLI. The theme system re-symlinks `~/.config/omarchy/current/theme/` and all apps pick up new colors.

### Modify Waybar layout (which modules, where)

Edit the repo file and re-stow:

```sh
# Edit the config
vim ~/Code/dotfiles-omarchy/.config/waybar/config.jsonc

# It's already symlinked, so changes are live immediately
# Waybar reloads automatically if "reload_style_on_change": true
```

To add a module: add it to the appropriate `modules-*` array, then define its configuration block below.

### Modify Waybar appearance (shapes, spacing, animations)

Edit the live stylesheet directly (it's not in the repo):

```sh
vim ~/.config/waybar/style.css
```

Waybar hot-reloads CSS changes. Keep `@import "../omarchy/current/theme/waybar.css"` as the first line so theme colors work.

### Override theme colors without changing themes

Add overrides after the `@import` in `style.css`:

```css
@import "../omarchy/current/theme/waybar.css";

/* Override specific colors */
@define-color foreground #ffffff;
@define-color background #000000;
```

### Override Hyprland border colors

Add overrides in `~/.config/hypr/looknfeel.conf` (sourced after the theme):

```
general {
    col.active_border = rgb(ff0000)
}
```

## Hyprland Theme Loading Order

Defined in `~/.config/hypr/hyprland.conf`:

```
1. ~/.local/share/omarchy/default/hypr/looknfeel.conf    (Omarchy defaults)
2. ~/.local/share/omarchy/default/hypr/envs.conf
3. ~/.config/omarchy/current/theme/hyprland.conf          (Active theme)
4. ~/.config/hypr/looknfeel.conf                          (User overrides)
5. ~/.config/hypr/envs.conf
```

Later sources override earlier ones. Put personal customizations in step 4/5.

## Troubleshooting

**Waybar not showing:**
1. Check for CSS syntax errors — orphaned properties outside selectors will crash the parser
2. Verify the `@import` path resolves: `ls -la ~/.config/omarchy/current/theme/waybar.css`
3. Check `config.jsonc` is valid JSON: `jq . < ~/.config/waybar/config.jsonc`
4. Restart: `uwsm-app -- waybar &`

**Colors not updating after theme switch:**
- Verify symlink: `readlink ~/.config/omarchy/current/theme`
- Waybar should auto-reload; if not, restart it

**Modules not appearing:**
- Check the module name matches exactly in both the `modules-*` array and the config block
- Check `exec` paths exist for custom modules
