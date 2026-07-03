# VITURE Luma Ultra XR Glasses on Omarchy

How the VITURE Luma Ultra glasses are set up on this machine: as an **external
monitor** (fully in the tracked dotfiles) and, optionally, as a **head-tracked
cursor** (XRLinuxDriver, installed system-side). Prioritized for stable dev work
and readable text (astigmatism), not experimental XR.

## TL;DR

| Thing | Where | Tracked in repo? |
|---|---|---|
| Monitor config (mode, scale, position) | `config/.config/hypr/monitors.conf` | ✅ Yes |
| Head-tracking toggle keybind (`SUPER+F12`) | `config/.config/hypr/bindings.conf` | ✅ Yes |
| Toggle script | `config/.local/bin/xr-driver-toggle` | ✅ Yes |
| XRLinuxDriver (binary, service, udev rule) | `~/.local`, `/usr/lib/udev/rules.d` | ❌ No (system install) |
| Driver settings | `~/.config/xr_driver/config.ini` | ❌ No (tied to install) |

---

## 1. Monitor mode (the part that matters most)

The glasses connect over **USB-C DisplayPort Alt Mode** and appear as a normal
external display — **no driver is needed just to use them as a monitor.**

They enumerate as `CVT VITURE` and advertise `1920x1080` and `1920x1200` modes up
to 120 Hz (1200p is the per-eye internal panel, not the desktop mode).

The tracked rule in `monitors.conf`:

```conf
monitor=desc:CVT VITURE 0x88888800,1920x1200@120,1920x0,1.6
```

- **Matched by `desc:`** (not `DP-2`) so it survives connector renumbering.
- **`1920x1200@120`** — full vertical space, smooth refresh.
- **Position `1920x0`** — extends to the *right* of the laptop (which is 1920
  logical px wide). Note: `auto-right` does **not** work here because `eDP-1` has
  an explicit position, so directional-auto has no anchor and lands at `0x0`
  (overlapping). Use an explicit x-offset.
- **`scale 1.6`** → logical 1200×750, larger readable text.
  ⚠️ Only fractional scales that yield whole pixels are valid: `1.6` (1200×750)
  and `1.5` (1280×800) work; `1.55` silently snaps up to `1.6`.

Below it, the generic catch-all `monitor=,preferred,auto,auto` stays as a
fallback for any *other* external display.

### Tune the scale live (no file edit)

```bash
hyprctl keyword monitor "desc:CVT VITURE 0x88888800,1920x1200@120,1920x0,1.5"   # smaller text, more space
hyprctl keyword monitor "desc:CVT VITURE 0x88888800,1920x1200@120,1920x0,1.6"   # bigger text
```

Then bake the value you like into `monitors.conf`.

---

## 2. Head-tracking (optional — XRLinuxDriver)

Turns head movement into cursor movement, **inside Hyprland** (works at the input
layer, so it needs no compositor support). Installed from the official
[XRLinuxDriver](https://github.com/wheaney/XRLinuxDriver) — the Luma Ultra is on
its supported-devices list (official VITURE collaboration + closed-source Linux
SDK).

**Install (system-side, one-time, needs sudo):**
```bash
curl -L https://github.com/wheaney/XRLinuxDriver/releases/latest/download/xr_driver_setup \
  -o ~/xr_driver_setup
sudo bash ~/xr_driver_setup
```
This drops the binary in `~/.local/bin`, a `xr-driver.service` (user, enabled),
and a udev rule `70-viture-xr.rules` in `/usr/lib/udev/rules.d` that grants your
user access to the glasses' hidraw IMU node (via `uaccess` ACL — no root needed
at runtime).

**Current settings** (`~/.config/xr_driver/config.ini`):
```ini
output_mode=mouse       # head -> cursor
external_mode=none
```

### Control it

`SUPER+F12` toggles tracking on/off (script: `xr-driver-toggle`, with an OSD).
Or via CLI:

```bash
xr_driver_cli --status        # "enabled" / "disabled"
xr_driver_cli -e / -d         # enable / disable
xr_driver_cli -m              # mouse mode (head -> cursor)
xr_driver_cli -ms 30          # sensitivity (higher = faster)
xr_driver_cli -dz 1.5         # deadzone degrees (higher = ignore jitter/drift)
xr_driver_cli --look-ahead-ms 20   # latency compensation
```

⚠️ While enabled, the cursor follows your head whenever the glasses are tracking
— if they're on the desk plugged in, the cursor can drift. Hit `SUPER+F12` (or
`xr_driver_cli -d`) when you're not wearing them.

---

## 3. Virtual / anchored monitors (NOT set up — for reference)

The "floating screens that stay put as you turn your head" experience is
**Breezy Desktop**. It is **not** available on Hyprland — it ships only as a
GNOME Shell extension (GNOME 45–50) or a KDE Plasma 6 KWin effect, and requires
XRLinuxDriver + Wayland. Using it means installing a *second* desktop
environment and logging into it as a separate session (Omarchy/Hyprland stays
your daily driver). Not done here; GNOME would be the lighter option if pursued.

---

## Rollback

**Monitor:** delete the VITURE line in `monitors.conf`, `hyprctl reload` — the
catch-all takes over.

**Head-tracking driver (fully reversible):**
```bash
xr_driver_cli -d
systemctl --user disable --now xr-driver.service
~/.local/bin/xr_driver_uninstall     # removes binary, service, udev rule
```

**Keybind/script:** remove the `SUPER, F12` line from `bindings.conf` and the
`xr-driver-toggle` script (+ its `~/.local/bin` symlink).

---

## Troubleshooting

| Symptom | Check |
|---|---|
| Glasses show no image | `hyprctl monitors all` — is `CVT VITURE` listed? Try another USB-C port; confirm DP Alt Mode; no dock. |
| Glasses overlap the laptop | Position resolved to `0x0`; ensure the explicit `1920x0` offset (not `auto-right`). |
| Scale "wrong" | Only whole-pixel scales apply; `1.55`→`1.6`. Check live with `hyprctl monitors`. |
| Cursor doesn't follow head | `xr_driver_cli --status` (enabled?), `systemctl --user status xr-driver.service`, `tail ~/.local/state/xr_driver/driver.log` (should log "Found device ... 0x35ca ... 0x1104"). |
| Cursor drifts on its own | Glasses tracking while idle — `SUPER+F12` to disable, or raise deadzone `-dz`. |

Baseline diagnostics and install logs from setup live in `~/viture-setup-audit/`.
