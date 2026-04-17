# Postmortem: split-monitor-workspaces Plugin Installation Failure

**Date**: 2025-11-10
**System**: Omarchy 3.1.4 (Arch Linux), Hyprland 0.52.0-1
**Status**: ❌ Failed - Reverted to default Hyprland workspace management
**Severity**: Medium - Feature unavailable but system functional

---

## Executive Summary

Attempted to install the `split-monitor-workspaces` Hyprland plugin to enable per-monitor workspace numbering (awesome/dwm-style). Installation failed due to header version mismatches between the Hyprland 0.52.0 Arch package and hyprpm's plugin build system. All plugin configuration was removed and the system was reverted to default Hyprland workspace management.

---

## Problem Statement

### Initial Issue

Configuration files referenced the `split-monitor-workspaces` plugin dispatchers (`split-workspace`, `split-movetoworkspacesilent`, etc.) in `bindings.conf`, but the plugin was never actually installed. This caused "invalid dispatcher" errors when Hyprland loaded the configuration.

**Error observed**:
```
invalid dispatcher, requested split-workspace does not exist
```

**Affected files**:
- `.config/hypr/bindings.conf` (lines 57-61, 64-68, 71-74, 77-78)
- `.config/hyprdynamicmonitors/hyprconfigs/dual-external-top.go.tmpl`

### Root Cause Analysis

1. **Configuration Drift**: Plugin configuration was committed to dotfiles but plugin was never installed on the system
2. **Documentation Present**: Comprehensive setup guides existed in `docs/` but were aspirational rather than reflecting actual system state
3. **Template Inconsistency**: Plugin configuration existed in `dual-external-top.go.tmpl` but was missing from `laptop-ac.go.tmpl` and `laptop-battery.go.tmpl`

---

## Timeline

### Attempted Resolution

| Time | Action | Result |
|------|--------|--------|
| T+0 | Identified missing plugin configuration in laptop templates | Added plugin blocks to `laptop-ac.go.tmpl` and `laptop-battery.go.tmpl` |
| T+5 | Attempted `hyprpm update` to download headers | ❌ Failed with "Headers version mismatched" (error code 4) |
| T+10 | Investigated hyprpm state and Hyprland version | Found Hyprland 0.52.0 built without git metadata ("unknown" commit/branch) |
| T+15 | Attempted `hyprpm purge-cache` | ❌ Failed - requires superuser privileges |
| T+20 | Re-ran `hyprpm update` | ❌ Still failed - headers version mismatch persists |
| T+25 | Cloned plugin repository to `/tmp/` for manual build | ✅ Repository cloned successfully |
| T+30 | Attempted manual build with system headers | ❌ User interrupted - decided to abandon plugin approach |
| T+35 | Removed all plugin configuration | ✅ Successfully cleaned up |
| T+40 | Restored default Hyprland bindings | ✅ System functional |

---

## Technical Details

### Environment Information

```
Hyprland: 0.52.0-1
Installation: Arch Linux pacman package
Build Date: 2025-11-07
Packager: Caleb Maclennan <alerque@archlinux.org>

Hyprland Version Info:
- Branch: unknown
- Commit: unknown
- Git metadata: NOT PRESENT (breaks hyprpm)

System Headers: /usr/include/hyprland/ (present)
Plugin Headers: /var/cache/hyprpm/pazthor/headersRoot/include (expected by pkg-config but empty)
```

### Why hyprpm Failed

**The Core Problem**: Hyprland 0.52.0 on Arch Linux was built as a standard package without git repository metadata. When `hyprpm update` runs, it:

1. Clones Hyprland source from GitHub
2. Tries to checkout the exact commit matching the running version
3. Fails because the running version reports `commit: unknown`
4. Cannot verify header compatibility
5. Aborts with "Headers version mismatched"

**From hyprpm output**:
```
✔ Hyprland cloned
✔ checked out to running ver
! configuring Hyprland
✔ configured Hyprland
✖ failed to install headers with error code 4 (Headers version mismatched)
→ if the problem persists, try running hyprpm purge-cache.
```

### Why pkg-config Configuration Was Incorrect

The file `/usr/share/pkgconfig/hyprland.pc` pointed to:
```
prefix=/var/cache/hyprpm/pazthor/headersRoot/include
```

But this directory didn't exist because `hyprpm update` never completed successfully. The actual headers were in `/usr/include/hyprland/` from the Arch package.

### Manual Build Attempt

Attempted to bypass hyprpm by building directly:
```bash
cd /tmp/split-monitor-workspaces
HYPRLAND_HEADERS=/usr/include/hyprland make all
```

**Failed because**: The Makefile expects `HYPRLAND_HEADERS` to point to the Hyprland source repository root (with `hyprland/protocols/` subdirectory structure), not the installed headers directory which has a different layout.

---

## Resolution

### Actions Taken

1. **Removed plugin configuration from all templates**:
   - `laptop-ac.go.tmpl` - Removed plugin block
   - `laptop-battery.go.tmpl` - Removed plugin block
   - `dual-external-top.go.tmpl` - Removed plugin block

2. **Restored default Hyprland workspace bindings**:
   - Removed all `unbind` statements in `bindings.conf`
   - Removed all `split-workspace`, `split-movetoworkspacesilent`, `split-changemonitor` bindings
   - Default Omarchy workspace bindings (SUPER+1-9) now active

3. **Cleaned up temporary files**:
   - Removed `/tmp/split-monitor-workspaces` clone

4. **Reloaded Hyprland configuration**: Verified system functional

### Configuration Changes

**Files modified**:
```
.config/hyprdynamicmonitors/hyprconfigs/laptop-ac.go.tmpl
.config/hyprdynamicmonitors/hyprconfigs/laptop-battery.go.tmpl
.config/hyprdynamicmonitors/hyprconfigs/dual-external-top.go.tmpl
.config/hypr/bindings.conf
```

**Git diff summary**:
- Removed 13 lines of plugin configuration from each template (3 templates × 13 lines = 39 lines)
- Removed ~45 lines of plugin-specific keybindings from `bindings.conf`
- Total cleanup: ~84 lines removed

### Verification

```bash
$ hyprctl binds | grep workspace | head -5
description: Switch to workspace 1
	dispatcher: workspace
description: Switch to workspace 2
	dispatcher: workspace
description: Switch to workspace 3
	dispatcher: workspace
```

✅ Default Hyprland workspace dispatchers active
✅ No "invalid dispatcher" errors
✅ Workspaces functional in dual-monitor setup

---

## Impact Assessment

### What We Lost

❌ **Per-monitor workspace numbering**: Each monitor would have had workspaces 1-5, context-aware based on cursor position
❌ **Workspace wrapping**: Cycle through workspaces with automatic wrap-around
❌ **Monitor-aware window movement**: Easy window movement between monitors with vim-style bindings
❌ **Persistent workspace management**: Auto-creation of workspaces per monitor

### What We Kept

✅ **Global workspace numbering**: Workspaces 1-10 available across all monitors
✅ **Standard window movement**: Move windows to any workspace with SUPER+SHIFT+number
✅ **System stability**: No plugin crashes or dispatcher errors
✅ **Omarchy defaults**: All default workspace bindings functional

### User Experience Impact

**Before (intended with plugin)**:
- On laptop: SUPER+1 → Workspace 1 (laptop)
- On external: SUPER+1 → Workspace 6 (displayed as 1)
- Intuitive per-monitor workflow

**After (current)**:
- On laptop: SUPER+1 → Workspace 1 (global)
- On external: SUPER+1 → Workspace 1 (global, switches focus to laptop)
- Need to remember which workspaces are on which monitor

---

## Lessons Learned

### What Went Wrong

1. **Assumption Failure**: Assumed hyprpm would work like standard plugin managers (like vim-plug, zinit, etc.) but it has strict version requirements

2. **Package Build Limitations**: Arch packages are built without git metadata for reproducibility, but this breaks tools that rely on exact git commit matching

3. **Header Location Mismatch**: System headers installed by pacman are not in the format expected by plugin Makefiles designed for source builds

4. **Configuration Before Installation**: Committed working configuration to dotfiles without verifying the plugin could actually be installed

### What Went Right

1. **Documentation**: Comprehensive docs allowed quick understanding of the intended setup

2. **Clean Rollback**: All changes were in configuration files, no system-level modifications made

3. **Template System**: hyprdynamicmonitors templates made it easy to update all monitor configurations at once

4. **Git Tracking**: All changes tracked in dotfiles repo for easy review and reversal

---

## Future Solutions

### Option 1: Wait for Plugin Compatibility (Recommended)

**When to try**: After next Hyprland update or plugin update

**Steps**:
1. Check plugin issues: https://github.com/Duckonaut/split-monitor-workspaces/issues
2. Search for "Hyprland 0.52" or current version
3. If compatibility confirmed, retry `hyprpm add`

**Pros**:
- Least effort required
- Plugin officially supported by Hyprland ecosystem
- Clean installation through hyprpm

**Cons**:
- Uncertain timeline
- May never work with Arch packages that lack git metadata

### Option 2: AUR Package

**When to try**: Check if available now

**Steps**:
```bash
# Search AUR
yay -Ss hyprland-plugin-split-monitor-workspaces
paru -Ss split-monitor-workspaces

# If found, install
yay -S hyprland-plugin-split-monitor-workspaces-git
```

**Pros**:
- Packager handles compatibility
- Automatic updates through AUR
- No manual building

**Cons**:
- Package may not exist
- Still requires AUR helper (yay/paru)
- May lag behind plugin updates

### Option 3: Manual Build from Source

**When to try**: If you're comfortable compiling Hyprland from source

**Requirements**:
- Clone and build Hyprland from source instead of using Arch package
- Ensure git metadata is preserved
- Build plugin against your custom Hyprland build

**Steps**:
```bash
# 1. Clone Hyprland
git clone https://github.com/hyprwm/Hyprland ~/repos/Hyprland
cd ~/repos/Hyprland
git checkout v0.52.0  # or current version

# 2. Build Hyprland
make all
sudo make install

# 3. Set environment
export HYPRLAND_HEADERS="$HOME/repos/Hyprland"

# 4. Build plugin
cd /tmp
git clone https://github.com/Duckonaut/split-monitor-workspaces
cd split-monitor-workspaces
make all

# 5. Install plugin
mkdir -p ~/.config/hypr/plugins
cp split-monitor-workspaces.so ~/.config/hypr/plugins/

# 6. Load plugin (add to hyprland.conf)
exec-once = hyprctl plugin load ~/.config/hypr/plugins/split-monitor-workspaces.so
```

**Pros**:
- Full control over build environment
- Guaranteed header compatibility
- Can customize Hyprland if needed

**Cons**:
- Time-consuming initial setup
- Need to rebuild on every Hyprland update
- Lose Arch package management benefits
- Higher maintenance burden

### Option 4: Alternative Implementation

**When to try**: If plugin installation remains problematic

**Approach**: Implement similar behavior using native Hyprland features and scripts

**Strategy**:
1. Use workspace rules to bind workspaces to monitors
2. Create wrapper scripts for workspace switching
3. Use `hyprctl` to detect current monitor
4. Remap workspace numbers in scripts

**Example script** (`~/.config/hypr/scripts/smart-workspace.sh`):
```bash
#!/bin/bash
# Usage: smart-workspace.sh <workspace_number>
# Switches to workspace N on current monitor

WORKSPACE=$1
ACTIVE_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .id')

# Monitor 0 (eDP-1): workspaces 1-5
# Monitor 1 (HDMI-A-1): workspaces 6-10
if [ "$ACTIVE_MONITOR" -eq 0 ]; then
    ACTUAL_WORKSPACE=$WORKSPACE
else
    ACTUAL_WORKSPACE=$((WORKSPACE + 5))
fi

hyprctl dispatch workspace $ACTUAL_WORKSPACE
```

**Bindings**:
```conf
bind = SUPER, 1, exec, ~/.config/hypr/scripts/smart-workspace.sh 1
bind = SUPER, 2, exec, ~/.config/hypr/scripts/smart-workspace.sh 2
# etc...
```

**Pros**:
- No plugin dependency
- Full control and customization
- Works across all Hyprland versions
- Can add custom logic (notifications, animations, etc.)

**Cons**:
- More complex to maintain
- Slight delay compared to native plugin
- Need to handle edge cases manually
- Requires scripting knowledge

### Option 5: Use NixOS (Long-term)

**When to try**: If considering a switch to NixOS

**Benefits**:
- Declarative configuration
- Plugin compatibility guaranteed through flake inputs
- Atomic rollbacks if plugin breaks
- Reproducible builds

**Example** (from plugin README):
```nix
# flake.nix
{
  inputs = {
    hyprland.url = "github:hyprwm/Hyprland";
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
  };

  # ... config
  wayland.windowManager.hyprland = {
    plugins = [
      split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
    ];
  };
}
```

**Pros**:
- Plugin management just works
- No version mismatch issues
- Declarative dotfiles
- Excellent for Hyprland plugin users

**Cons**:
- Requires full OS migration
- Steep learning curve
- Different package management paradigm

---

## Monitoring & Prevention

### How to Detect This Issue Again

**Symptoms**:
```
✖ invalid dispatcher, requested split-workspace does not exist
✖ invalid dispatcher, requested split-movetoworkspacesilent does not exist
```

**Quick check**:
```bash
# Verify plugin is loaded
hyprctl plugin list

# Should show split-monitor-workspaces if working
# If empty, plugin not loaded
```

### Prevention Checklist

Before committing plugin-dependent configuration:

- [ ] Verify plugin is installed: `hyprctl plugin list`
- [ ] Test all custom dispatchers manually
- [ ] Document plugin version and Hyprland version in commit message
- [ ] Add installation instructions to README/docs
- [ ] Consider adding a system check script that validates plugin presence

### Recommended Documentation Standards

When adding plugin-dependent features:

1. **Create prerequisite section** in setup docs
2. **Version compatibility matrix** showing tested combinations
3. **Fallback configuration** for when plugin unavailable
4. **Installation verification steps** before applying config

---

## Related Documentation

- `docs/split-monitor-workspace.md` - Original setup guide (for ASUS Zenbook)
- `docs/split-monitor-workspaces-laptop-setup.md` - Laptop-specific guide
- Plugin repository: https://github.com/Duckonaut/split-monitor-workspaces
- Hyprland plugin guide: https://wiki.hyprland.org/Plugins/Using-Plugins/

---

## References

- **Hyprland version**: 0.52.0-1
- **Plugin repository**: https://github.com/Duckonaut/split-monitor-workspaces
- **hyprpm documentation**: https://wiki.hyprland.org/Plugins/Using-Plugins/#hyprpm
- **Arch Linux Hyprland package**: https://archlinux.org/packages/extra/x86_64/hyprland/
- **Issue search**: https://github.com/Duckonaut/split-monitor-workspaces/issues

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-11-10 | Remove plugin configuration | hyprpm incompatible with Arch package build, no clear workaround |
| 2025-11-10 | Revert to default Hyprland bindings | Stability and reliability over feature parity |
| 2025-11-10 | Keep documentation for future reference | May be useful when compatibility improves |
| 2025-11-10 | Document in postmortem | Help future troubleshooting and decision-making |

---

## Conclusion

The `split-monitor-workspaces` plugin installation failed due to fundamental incompatibilities between hyprpm's version-matching requirements and Arch Linux's reproducible package builds. While the feature would have provided a better multi-monitor workflow, system stability takes precedence.

**Recommendation**: Monitor the plugin repository for Arch Linux compatibility improvements, or consider Option 4 (script-based implementation) for a plugin-free solution.

**Next steps**:
1. Star the plugin repository on GitHub for updates
2. Check back after next Hyprland update (post-0.52.0)
3. Consider implementing script-based alternative if plugin remains incompatible

---

**Status**: Documented and closed
**Follow-up**: Check plugin compatibility quarterly or after major Hyprland updates
