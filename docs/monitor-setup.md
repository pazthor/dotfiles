# Monitor Setup Guide

## Layout

External ultrawide (AOC U34G2G4R3) on top, laptop screen centered below.

```
┌──────────────────────────────────────────┐
│          HDMI-A-1  3440x1440             │
│          scale 1.67 → logical ~2060×864  │
└──────────────────────────────────────────┘
              ┌───────────────┐
              │     eDP-1     │
              │  (laptop)     │
              └───────────────┘
```

## How it works

`monitors.conf` (tracked in dotfiles) sets shared defaults.
`~/.config/hypr/monitors-local.conf` (NOT in repo) holds machine-specific positions.

## Setup on a new machine

**1. Find your laptop screen resolution**

```bash
hyprctl monitors
# Look at eDP-1 → "availableModes" → pick the native one
```

**2. Calculate the X offset (centers laptop under ultrawide)**

```
X = (3440 / 1.67 - <laptop_width> / 1.5) / 2
```

| Laptop resolution | X offset |
|-------------------|----------|
| 1920×1080         | 390      |
| 2560×1440         | 10       |
| 2880×1800         | 70       |

**3. Create `~/.config/hypr/monitors-local.conf`**

```
# Replace WIDTH×HEIGHT@HZ with your laptop's values, and X with the table above.
monitor=eDP-1,WIDTH×HEIGHTx@HZ,Xx864,1.5,vrr,0
```

Examples:

```bash
# 1920×1080 laptop (levi)
monitor=eDP-1,1920x1080@60,390x864,1.5,vrr,0

# 2880×1800 laptop
monitor=eDP-1,2880x1800@120,70x864,1.5,vrr,0
```

**4. Reload Hyprland**

```bash
hyprctl reload
hyprctl configerrors   # should be empty
```

## Troubleshooting

**Overlap warning** — Y must be ≥ 864 (logical height of the ultrawide is ~863).

**Laptop not centered** — Recalculate X with the formula above.

**Wrong refresh rate** — Run `hyprctl monitors` and check `availableModes` for eDP-1, use exact Hz value.

**No external monitor** — Without HDMI-A-1, Hyprland falls back to `preferred + auto-down` from `monitors.conf`, so the laptop screen still works.
