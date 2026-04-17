# How Your Monitor Setup Works (Explained Simply!)

## What Is This About?

Imagine you have LEGO blocks (your monitors) and you want them to connect together in different ways. Sometimes you only have your laptop, sometimes you plug in a big external screen, and sometimes both!

**hyprdynamicmonitors** is like a smart robot that:
- 🤖 Watches which monitors you have plugged in
- 🔌 Checks if your laptop is plugged into power or running on battery
- 📝 Automatically arranges your screens the way you want
- ✨ Makes everything work without you doing anything!

## The Two Important Folders

### 1. `.config/hyprdynamicmonitors/` - The Robot's Brain

This folder tells the robot **what to do** when it sees different situations.

#### `config.toml` - The Main Instructions
This is like the robot's rulebook. It says:
- "When you see the laptop screen only, use laptop-only setup"
- "When you see laptop + external monitor, arrange them vertically"
- "When power is unplugged, use battery-saving mode"

**Important settings:**
```toml
destination = "$HOME/.config/hypr/monitors.conf"
```
☝️ This tells the robot where to write the final instructions

```toml
post_apply_exec = "hyprctl reload"
```
☝️ This tells Hyprland "Hey! The monitors changed, look again!"

#### `hyprconfigs/` Folder - Different Recipes

Think of these like recipe cards. Each one describes how to arrange monitors in a specific situation:

**`laptop-ac.go.tmpl`** 📱⚡
- Used when: Only laptop screen, plugged into power
- Does: Shows laptop screen at full brightness/speed

**`laptop-battery.go.tmpl`** 📱🔋
- Used when: Only laptop screen, running on battery
- Does: Saves power by using lower settings

**`dual-external-top.go.tmpl`** 📺📱
- Used when: Laptop + external monitor, plugged into power
- Does: **Puts external monitor on top, laptop below** (like stacking two screens!)

### 2. `.config/hypr/` - Hyprland's Settings

This folder has settings for Hyprland (your window manager - the thing that draws windows on screen).

#### `autostart.conf` - What Runs When You Login
```bash
exec-once = hyprdynamicmonitors run
```
☝️ This starts the monitor robot when you log in!

#### `input.conf` - Keyboard & Mouse Settings
- How your keyboard and mouse work
- Not related to monitors, just other input stuff

## How It All Works Together

Let's follow what happens when you plug in an external monitor:

1. **🔌 You plug in the monitor**
   ```
   [Physical action] → Monitor connects via HDMI
   ```

2. **👀 The robot notices**
   ```
   hyprdynamicmonitors: "Oh! I see a new monitor: HDMI-A-1"
   ```

3. **📖 The robot reads its rulebook**
   ```
   config.toml says: "laptop + HDMI-A-1 + on AC power = use dual-external-top"
   ```

4. **✍️ The robot writes new instructions**
   ```
   Reads: hyprconfigs/dual-external-top.go.tmpl
   Writes to: ~/.config/hypr/monitors.conf

   The template says:
   - External monitor: position 0,0 (top)
   - Laptop monitor: position 390,864 (centered below)
   ```

5. **🔄 The robot tells Hyprland to reload**
   ```
   Runs: hyprctl reload
   ```

6. **✨ Your screens are now stacked!**
   ```
   Move your mouse up from laptop → reaches external monitor!
   ```

## The Big Fix We Just Made

### What Was Wrong?
When you moved your mouse up from the laptop, it wouldn't reach the external monitor. It was like having two pieces of paper that don't touch!

### Why It Was Wrong?
The robot was measuring using **physical pixels** (the real screen size) instead of **logical pixels** (how big things look after zoom/scaling).

Think of it like this:
- If you zoom in on a picture (scaling = 1.67x), and someone asks "how tall is it?"
- ❌ Wrong: "1440 pixels" (the original unzoomed size)
- ✅ Right: "863 pixels" (how tall it looks when zoomed: 1440÷1.67≈862.87, rounds to 863)

### The Fix
Changed `dual-external-top.go.tmpl`:
```
Before: monitor=eDP-1,...,760x1440,...  ❌ (used physical pixels)
After:  monitor=eDP-1,...,390x864,...   ✅ (uses logical pixels + 1 to avoid overlap)
```

Now the laptop is positioned **exactly below** the external monitor using the correct zoomed measurements!

## How to Make Changes

### Want to change monitor positions?

1. **Open the template file:**
   ```bash
   nano .config/hyprdynamicmonitors/hyprconfigs/dual-external-top.go.tmpl
   ```

2. **Change the numbers:**
   ```
   monitor=eDP-1,1920x1080@60,X-position,Y-position,scale,vrr,0
                              ↑          ↑
                              Left/Right Up/Down
   ```

3. **Save and wait ~1 second** - the robot automatically reloads!

### Want to add a new monitor setup?

1. **Add to `config.toml`:**
   ```toml
   [profiles.my_new_setup]
   config_file = "hyprconfigs/my-setup.go.tmpl"
   config_file_type = "template"

   [[profiles.my_new_setup.conditions.required_monitors]]
   name = "DP-1"  # Your new monitor
   monitor_tag = "mynewmonitor"
   ```

2. **Create the template:**
   ```bash
   nano .config/hyprdynamicmonitors/hyprconfigs/my-setup.go.tmpl
   ```

3. **The robot will use it automatically!**

## Important Rules (Don't Break These!)

### ⚠️ Rule #1: Use Logical Pixels With Scaling
If your monitor has scaling (like 1.67x or 1.5x), divide the real size by the scale:
```
Real height: 1440 pixels
Scale: 1.67
Logical height: 1440 ÷ 1.67 = 862.87 → rounds to 863 pixels
Next monitor Y position: 864 pixels ← Use this to avoid overlap!
```

### ⚠️ Rule #2: Always Test After Changes
After editing templates:
```bash
# Force reload if it doesn't auto-detect
kill -SIGHUP $(pgrep -f hyprdynamicmonitors)

# Check what got written
cat ~/.config/hypr/monitors.conf
```

### ⚠️ Rule #3: Keep Templates Simple
Templates use Go template syntax. Keep variable definitions at the top:
```go
{{- $laptop := index .MonitorsByTag "laptop" -}}
{{- $external := index .MonitorsByTag "external" }}

# Now use them below
monitor={{$external.Name}},preferred,0x0,1.67,vrr,0
```

## Troubleshooting

### "My cursor won't move between monitors!"
- Check if monitors are positioned correctly (they need to touch!)
- Make sure you're using logical pixels if you have scaling
- **Important**: If you get overlap warnings, add 1 pixel gap (e.g., Y=864 instead of 863)

### "The robot isn't detecting changes!"
```bash
# Check if it's running
pgrep -f hyprdynamicmonitors

# Check the logs
journalctl --user -f | grep hyprdynamic
```

### "My monitors are stacked wrong!"
Look at your template and check the Y positions:
- Top monitor should be at Y=0
- Bottom monitor Y = (top monitor height ÷ scale)

## Quick Reference

| File | What It Does |
|------|--------------|
| `config.toml` | Main rulebook - tells robot which template to use when |
| `hyprconfigs/*.go.tmpl` | Template recipes - how to arrange monitors |
| `autostart.conf` | Starts the robot when you login |
| `monitors.conf` | **Auto-generated** - don't edit directly! Robot writes this |

## Need More Help?

- 📚 Read the full docs: `commands/hyprdynamicmonitors/README_upstream.md`
- 🎨 Use the visual tool: `hyprdynamicmonitors tui`
- 🔍 Check current setup: `hyprctl monitors`

---

**Remember:** The robot is your friend! It watches for changes and fixes things automatically. You just need to teach it the rules once, and it'll remember forever! 🤖✨
