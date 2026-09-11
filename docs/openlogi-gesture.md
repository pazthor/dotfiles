# OpenLogi MX Master 3S gesture PoC

This PoC tests the MX Master 3S Gesture Button in separate stages so a failed
gesture is not confused with a failed Hyprland command.

The live OpenLogi file is `~/.config/openlogi/config.toml`. It stays outside
the repository: OpenLogi writes it atomically and may replace a symlink while
saving. The helper itself is linked from this repository to
`~/.local/bin/openlogi-gesture-poc`.

## Prepare the Linux device access

OpenLogi needs access to the mouse event node, HID raw device, and uinput. The
package-installed udev rule is preferred because it grants access only to the
active desktop user:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=hidraw
sudo udevadm trigger --subsystem-match=input
```

For a Bluetooth mouse, reconnect or power-cycle the mouse after reloading the
rules. Do not add the user to the broad `input` group unless the uaccess rule
cannot work on this system.

## Start and inspect the agent

After syncing this repository, enable the user service:

```bash
just sync
openlogi-gesture-poc service
openlogi-gesture-poc check
```

The check must report a readable Logitech `/dev/input/event*` node, readable
and writable HID access, an active user service, and an installed OS input
hook. The relevant agent log is under `~/.local/state/openlogi/`.

If the check reports `no mouse device found under /dev/input` or `Permission
denied`, fix device access before changing the gesture mapping.

## Run the PoC stages

Close the OpenLogi GUI before applying a stage. Each apply command creates a
backup such as `~/.config/openlogi/config.toml.poc.TIMESTAMP` and restarts the
agent when its user service is active.

First test that OpenLogi accepts and loads the gesture mapping:

```bash
openlogi-gesture-poc apply builtin
```

This assigns `ShowDesktop` to Click and all four directions. Once that works,
test event capture and shell-command execution:

```bash
openlogi-gesture-poc apply notify
tail -f ~/.local/state/openlogi-gesture-poc.log
```

Press the Gesture Button and hold it while swiping up, down, left, and right.
Each arm must produce a distinct notification and log entry.

## Test the Hyprland actions

Verify the commands manually inside the active Hyprland session:

```bash
/usr/bin/hyprctl dispatch workspace e+1
/usr/bin/hyprctl dispatch workspace e-1
/usr/bin/hyprctl dispatch movefocus l
/usr/bin/hyprctl dispatch movefocus r
/usr/bin/hyprctl dispatch togglespecialworkspace scratchpad
```

Then apply the final PoC stage:

```bash
openlogi-gesture-poc apply hyprland
```

The helper logs and notifies before dispatching the matching absolute
`/usr/bin/hyprctl` command. This also avoids relying on the service's login
shell `PATH`.

## Restore

List available PoC backups and restore one if needed:

```bash
ls -t ~/.config/openlogi/config.toml.poc.*
openlogi-gesture-poc restore ~/.config/openlogi/config.toml.poc.TIMESTAMP
```
