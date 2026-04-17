
# Split-Monitor-Workspaces Setup for Independent Workspace Numbering

> ⚠️ **WARNING - INSTALLATION FAILED (2025-11-10)**
>
> This configuration is **NOT CURRENTLY FUNCTIONAL** due to hyprpm compatibility issues with Hyprland 0.52.0 on Arch Linux.
> The plugin installation fails with "Headers version mismatched" errors.
>
> **See**: [`split-monitor-workspaces-postmortem.md`](split-monitor-workspaces-postmortem.md) for full details and future solutions.
>
> This document is preserved for reference and future compatibility attempts.

## System Information

- **Model**: ASUS Zenbook S 14 UX5406SA (UX5406SA)
- **CPU**: Intel Core Ultra 7 258V (Lunar Lake)
- **Internal Display**: Samsung Display Corp. 0x419D - 2880x1800@120Hz (eDP-1)
- **External Monitor**: YCT InnoView Innoview - 3840x2400@60Hz (DP-1)
- **OS**: Arch Linux (Omarchy 3.1.3)
- **Kernel**: 6.17.4-arch2-1
- **WM**: Hyprland 0.51.1
- **Bar**: Waybar

## Overview

This setup provides **independent workspace numbering per monitor**, allowing each monitor to have its own workspaces 1-5. This is an awesome/dwm-like behavior where pressing `SUPER+1` on any monitor takes you to workspace 1 of *that monitor*.

## Problem Statement

By default, Hyprland uses global workspace numbering (1-10). In a dual-monitor setup, this means:
- You need to remember which workspace numbers belong to which monitor
- Keybindings like `SUPER+6` might feel unnatural for the second monitor

**Desired behavior**: Each monitor should have workspaces 1-5 that are completely independent.

## Solution: split-monitor-workspaces Plugin

The `split-monitor-workspaces` Hyprland plugin provides awesome/dwm-like workspace behavior by:
- Assigning workspace ranges to each monitor (Monitor 0: 1-5, Monitor 1: 6-10)
- Remapping the numbers so you always access them as 1-5 on whichever monitor you're focused on
- Making workspace switching context-aware based on cursor position

## Installation

### 1. Install Plugin via hyprpm

The plugin is installed using Hyprland's plugin manager:

```bash
# Initialize hyprpm (requires sudo for first-time setup)
hyprpm update

# Add the plugin repository
hyprpm add https://github.com/Duckonaut/split-monitor-workspaces

# Enable the plugin
hyprpm enable split-monitor-workspaces

# Reload plugins
hyprpm reload
```

**Note**: The plugin must be compiled against your exact Hyprland version. Run `hyprpm update` after Hyprland updates.

### 2. Verify Plugin Installation

```bash
hyprctl plugin list
```

Should show:
```
Plugin split-monitor-workspaces by Duckonaut:
	Handle: [address]
	Version: 1.2.0
	Description: Split monitor workspace namespaces
```

## Configuration

### 1. Plugin Configuration

The plugin is configured in the hyprdynamicmonitors template since it needs to be part of the monitor configuration.

**File**: `~/.config/hyprdynamicmonitors/hyprconfigs/Dual Setup.go.tmpl`

```go
# Plugin configuration for split-monitor-workspaces
plugin {
    split-monitor-workspaces {
        count = 5
        enable_persistent_workspaces = 1
    }
}

exec-once = hyprpm reload -n
```

**Configuration options:**
- `count = 5` - Each monitor gets 5 workspaces
- `enable_persistent_workspaces = 1` - Auto-create workspaces on startup

### 2. Keybinding Configuration

The plugin requires using special dispatchers instead of the default Hyprland ones.

**File**: `~/.config/hypr/bindings.conf`

First, unbind the default Omarchy workspace bindings:

```conf
# Unbind default Omarchy workspace bindings to use split-monitor-workspaces
unbind = SUPER, code:10  # 1
unbind = SUPER, code:11  # 2
unbind = SUPER, code:12  # 3
unbind = SUPER, code:13  # 4
unbind = SUPER, code:14  # 5
unbind = SUPER SHIFT, code:10
unbind = SUPER SHIFT, code:11
unbind = SUPER SHIFT, code:12
unbind = SUPER SHIFT, code:13
unbind = SUPER SHIFT, code:14
```

Then add the split-workspace bindings:

```conf
# Override Omarchy defaults to use split-monitor-workspaces plugin
# Switch workspaces with SUPER + [1-5] (each monitor gets 1-5)
bindd = SUPER, code:10, Switch to workspace 1, split-workspace, 1
bindd = SUPER, code:11, Switch to workspace 2, split-workspace, 2
bindd = SUPER, code:12, Switch to workspace 3, split-workspace, 3
bindd = SUPER, code:13, Switch to workspace 4, split-workspace, 4
bindd = SUPER, code:14, Switch to workspace 5, split-workspace, 5

# Move active window to a workspace with SUPER + SHIFT + [1-5]
bindd = SUPER SHIFT, code:10, Move window to workspace 1, split-movetoworkspacesilent, 1
bindd = SUPER SHIFT, code:11, Move window to workspace 2, split-movetoworkspacesilent, 2
bindd = SUPER SHIFT, code:12, Move window to workspace 3, split-movetoworkspacesilent, 3
bindd = SUPER SHIFT, code:13, Move window to workspace 4, split-movetoworkspacesilent, 4
bindd = SUPER SHIFT, code:14, Move window to workspace 5, split-movetoworkspacesilent, 5

# Move window between monitors with SUPER + CTRL + H/L
bindd = SUPER CTRL, H, Move window to previous monitor, split-changemonitor, prev
bindd = SUPER CTRL, L, Move window to next monitor, split-changemonitor, next

# Swap between workspace with SUPER+ALT vim motions
bindd = SUPER ALT, H, Previous workspace, split-workspace, e-1
bindd = SUPER ALT, L, Next workspace, split-workspace, e+1
```

**Key dispatchers:**
- `split-workspace N` - Switch to workspace N on current monitor
- `split-movetoworkspacesilent N` - Move window to workspace N without focus
- `split-changemonitor prev/next` - Move window to previous/next monitor
- `split-workspace e+1/e-1` - Cycle through workspaces on current monitor

### 3. Waybar Configuration

Waybar needs special configuration to display workspaces correctly with the plugin.

**File**: `~/.config/waybar/config.jsonc`

```json
"hyprland/workspaces": {
  "on-click": "activate",
  "format": "{icon}",
  "all-outputs": false,
  "format-icons": {
    "default": "",
    "1": "1",
    "2": "2",
    "3": "3",
    "4": "4",
    "5": "5",
    "6": "1",
    "7": "2",
    "8": "3",
    "9": "4",
    "10": "5",
    "active": "󱓻"
  },
  "persistent-workspaces": {
    "eDP-1": [1, 2, 3, 4, 5],
    "DP-1": [6, 7, 8, 9, 10]
  }
}
```

**Key configuration points:**

1. **`all-outputs: false`** - Shows only workspaces relevant to each monitor
2. **Icon remapping** - Workspaces 6-10 display as "1"-"5" on the external monitor
3. **Monitor-specific persistent-workspaces** - Tells Waybar which workspaces belong to which monitor:
   - `eDP-1` (laptop): Shows workspaces 1-5
   - `DP-1` (external): Shows workspaces 6-10 (displayed as 1-5)

## How It Works

### Workspace Mapping

The plugin assigns workspace ID ranges to each monitor:

- **Monitor 0 (eDP-1, laptop)**: Workspace IDs 1-5
- **Monitor 1 (DP-1, external)**: Workspace IDs 6-10

When you use the plugin dispatchers, they remap the numbers:
- On laptop: `split-workspace 1` → actual workspace 1
- On external: `split-workspace 1` → actual workspace 6

### Context-Aware Switching

The plugin determines which monitor you're on based on cursor position:
- Move cursor to laptop, press `SUPER+1` → Go to workspace 1 (laptop)
- Move cursor to external, press `SUPER+1` → Go to workspace 6 (displayed as 1)

### Waybar Display

Waybar shows the actual Hyprland workspace IDs (1-10), so we use icon remapping:
- Workspace IDs 1-5 → Display as "1", "2", "3", "4", "5"
- Workspace IDs 6-10 → Display as "1", "2", "3", "4", "5"

Combined with `persistent-workspaces` per monitor, each Waybar instance only shows its monitor's workspaces.

## Usage

### Basic Workspace Switching

- **`SUPER + 1-5`** - Switch to workspace 1-5 on the current monitor
- **`SUPER + SHIFT + 1-5`** - Move active window to workspace 1-5 on current monitor
- **`SUPER + ALT + H/L`** - Cycle through workspaces on current monitor

### Moving Windows Between Monitors

- **`SUPER + CTRL + H`** - Move window to previous monitor (left)
- **`SUPER + CTRL + L`** - Move window to next monitor (right)

### Behavior Examples

1. **On laptop screen**, press `SUPER+1`:
   - Switches to workspace 1 (actual ID: 1)
   - Waybar shows: `[1] 2 3 4 5`

2. **On external monitor**, press `SUPER+1`:
   - Switches to workspace 6 (displayed as 1)
   - Waybar shows: `[1] 2 3 4 5`

3. **Move window between monitors**:
   - On laptop with window focused, press `SUPER+CTRL+L`
   - Window moves to external monitor workspace 1 (actual ID: 6)

## Troubleshooting

### Issue: Keybindings Don't Work

**Symptom**: Pressing `SUPER+1` goes to global workspace 1 instead of monitor-specific workspace.

**Cause**: Default Hyprland workspace bindings are conflicting.

**Solution**: Ensure you've unbound the default bindings before adding split-workspace bindings:

```bash
# Check active bindings
hyprctl binds | grep "workspace.*[0-9]"

# Should only show split-workspace, not workspace
```

### Issue: Waybar Shows All Workspaces on Both Monitors

**Symptom**: Both monitors show workspaces 1-10 or duplicate numbers.

**Cause**: `persistent-workspaces` is configured globally instead of per-monitor.

**Solution**: Use monitor-specific persistent-workspaces:

```json
"persistent-workspaces": {
  "eDP-1": [1, 2, 3, 4, 5],
  "DP-1": [6, 7, 8, 9, 10]
}
```

### Issue: Plugin Not Loading After Hyprland Update

**Symptom**: `hyprctl plugin list` shows no plugins or errors.

**Cause**: Plugin needs to be recompiled for new Hyprland version.

**Solution**:
```bash
hyprpm update
hyprpm reload
```

### Issue: Workspaces Show Wrong Numbers in Waybar

**Symptom**: External monitor shows workspaces 6-10 instead of 1-5.

**Cause**: Icon remapping not configured.

**Solution**: Add icon mappings in Waybar config:
```json
"format-icons": {
  "6": "1",
  "7": "2",
  "8": "3",
  "9": "4",
  "10": "5"
}
```

## Dotfiles Integration

The configuration is managed in the dotfiles repository:

```
dotfiles/
├── .config/
│   ├── hypr/
│   │   └── bindings.conf (split-workspace keybindings)
│   ├── hyprdynamicmonitors/
│   │   ├── config.toml
│   │   └── hyprconfigs/
│   │       └── Dual Setup.go.tmpl (plugin config)
│   └── waybar/
│       └── config.jsonc (workspace display config)
└── .stow-local-ignore (excludes monitors.conf)
```

### Stowing

```bash
cd ~/dotfiles
make migrate-apply
```

**Note**: `monitors.conf` is auto-generated by hyprdynamicmonitors and excluded from stow via `.stow-local-ignore`.

## Integration with hyprdynamicmonitors

The split-monitor-workspaces plugin works seamlessly with hyprdynamicmonitors:

1. **Plugin config** is in the Dual Setup template
2. **Lid events** continue to work (disable laptop screen when closed)
3. **Power events** continue to work (AC vs battery configs)

When the lid is closed:
- Laptop screen (eDP-1) is disabled
- Workspaces 1-5 become "orphaned" and may move to the active monitor
- When lid opens, workspaces return to their assigned monitor

## Advanced Configuration

### Adjusting Workspace Count

To change the number of workspaces per monitor (e.g., 10 instead of 5):

1. Update plugin config:
   ```
   plugin {
       split-monitor-workspaces {
           count = 10
       }
   }
   ```

2. Update keybindings for workspaces 6-10:
   ```conf
   bindd = SUPER, code:15, Switch to workspace 6, split-workspace, 6
   # ... etc
   ```

3. Update Waybar config:
   ```json
   "format-icons": {
     "1": "1", "2": "2", ..., "10": "10",
     "11": "1", "12": "2", ..., "20": "10"
   },
   "persistent-workspaces": {
     "eDP-1": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
     "DP-1": [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
   }
   ```

### Using with More Than 2 Monitors

The plugin supports multiple monitors. With 3 monitors:

- Monitor 0: Workspaces 1-5
- Monitor 1: Workspaces 6-10
- Monitor 2: Workspaces 11-15

Update Waybar persistent-workspaces accordingly:
```json
"persistent-workspaces": {
  "eDP-1": [1, 2, 3, 4, 5],
  "DP-1": [6, 7, 8, 9, 10],
  "DP-2": [11, 12, 13, 14, 15]
}
```

## References

- **Plugin Repository**: https://github.com/Duckonaut/split-monitor-workspaces
- **Hyprland Plugin Management**: https://wiki.hyprland.org/Plugins/Using-Plugins/
- **Waybar Hyprland Module**: https://github.com/Alexays/Waybar/wiki/Module:-Hyprland
- **Original hyprdynamicmonitors Setup**: See `docs/hyprdynamicmonitors/setup.md`

## Date Configured

2025-10-28

## Credits

Configuration and troubleshooting assistance provided by Claude Code.
