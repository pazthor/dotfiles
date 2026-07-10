# Monitor Setup Guide

## Layout

Shared defaults live in `~/.config/hypr/monitors.conf`.
Machine-specific layouts live in `~/.config/hypr/monitors-local.conf`.

`scripts/bootstrap` creates the local file from a safe no-op default so
Hyprland never errors on a missing source file. For known laptops, copy a
tracked example over it.

## Current shared external layout

External ultrawide (AOC U34G2G4R3) on top, laptop screen centered below.

```text
┌──────────────────────────────────────────┐
│          HDMI-A-1  3440x1440             │
│          scale 1.6 → logical 2150×900    │
└──────────────────────────────────────────┘
              ┌───────────────┐
              │     eDP-1     │
              │  (laptop)     │
              └───────────────┘
```

## Files

- `monitors.conf` — shared monitor defaults, tracked in dotfiles.
- `monitors-local.conf` — active machine-local overrides, created locally by bootstrap.
- `monitors-local.default.conf` — tracked no-op fallback copied by bootstrap.
- `monitors-local.levi.conf` — tracked Levi example layout.
- `monitors-local.omar.conf` — tracked Omar/high-DPI laptop example layout.

## Setup on a known laptop

After running `just sync` or `scripts/bootstrap`, choose the matching example:

```bash
# Levi
cp ~/.config/hypr/monitors-local.levi.conf ~/.config/hypr/monitors-local.conf

# Omar / high-DPI laptop
cp ~/.config/hypr/monitors-local.omar.conf ~/.config/hypr/monitors-local.conf
```

Then reload:

```bash
hyprctl reload
hyprctl configerrors   # should be empty
```

## Setup on a new laptop

**1. Find your laptop screen resolution**

```bash
hyprctl monitors
# Look at eDP-1 → availableModes → pick the native mode and refresh rate.
```

**2. Calculate the X offset to center the laptop under the ultrawide**

Current ultrawide logical size is `3440 / 1.6 = 2150` wide and
`1440 / 1.6 = 900` tall.

```text
X = (2150 - (<laptop_width> / 1.5)) / 2
Y = 900
```

| Laptop resolution | Logical width at scale 1.5 | X offset | Y offset |
|-------------------|----------------------------|----------|----------|
| 1920×1080         | 1280                       | 435      | 900      |
| 2560×1440         | 1707                       | 221      | 900      |
| 2880×1800         | 1920                       | 115      | 900      |

**3. Create or update `~/.config/hypr/monitors-local.conf`**

```conf
monitor=eDP-1,WIDTHxHEIGHT@HZ,Xx900,1.5,vrr,0
```

Examples:

```conf
# 1920×1080 laptop (Levi)
monitor=eDP-1,1920x1080@60,435x900,1.5,vrr,0

# 2880×1800 laptop (Omar/high-DPI)
monitor=eDP-1,2880x1800@120,115x900,1.5,vrr,0
```

## Why this pattern?

Do not put every laptop's monitor geometry directly in `monitors.conf`.
That file should stay safe and shared.

Use named examples for known machines because they are easy to restore after a
reinstall and easy to copy onto new laptops. Keep the active
`monitors-local.conf` as the single machine-local file Hyprland sources. It is
created locally by bootstrap, so copying examples over it does not dirty the
repo.

## Troubleshooting

**Line 24 / source error** — run `scripts/bootstrap` so it creates
`~/.config/hypr/monitors-local.conf` from the no-op fallback file.

**Overlap warning** — Y must be at least `900`, because the ultrawide logical
height is `1440 / 1.6 = 900`.

**Laptop not centered** — recalculate X with the formula above.

**Wrong refresh rate** — run `hyprctl monitors` and use the exact eDP-1 mode.

**No external monitor** — without HDMI-A-1, Hyprland falls back to
`preferred + auto-down` from `monitors.conf`, so the laptop screen still works.
