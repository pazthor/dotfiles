# Touchpad Fix: Goodix GXTP7863 (Huawei MateBook)

## Summary

The touchpad is a **Goodix GXTP7863** (common in Huawei MateBook devices). The hardware is detected at the I2C/ACPI level but **no driver is currently bound** to it. This is a known kernel regression.

## Diagnostic Findings

**System Info:**
- Device: NBD-WXX9 (M1010) - Huawei MateBook
- Kernel: 6.18.3-arch1-1
- OS: Omarchy 3.3.3 (Arch-based)

**Hardware Detection:**
- Touchpad ACPI ID: `GXTP7863:00`
- Modalias: `acpi:GXTP7863:PNP0C50:`
- I2C Bus: Connected via `i2c-0` (Intel Tiger Lake I2C controller)
- Driver Status: **NO DRIVER BOUND** (probe likely failing with error -110 timeout)

**Root Cause:**
The `i2c_hid_acpi` driver should bind via `PNP0C50:` but probe is failing. This is a known kernel bug affecting 6.17.9+ kernels.

---

## Solution 1: Module Reload (Try First)

Reload the I2C HID driver to retry probe:

```bash
sudo modprobe -r i2c_hid_acpi
sudo modprobe i2c_hid_acpi
```

Check if touchpad appears:

```bash
cat /proc/bus/input/devices | grep -A 5 -i touchpad
libinput list-devices | grep -A 10 -i touchpad
```

---

## Solution 2: Kernel Downgrade (Most Reliable)

Downgrade to a working kernel version:

```bash
# List available kernels
pacman -Ss linux | grep "^core"

# Install LTS kernel as alternative
sudo pacman -S linux-lts linux-lts-headers

# Reboot and select LTS kernel from bootloader
```

**Known working kernels:**
- linux-lts (6.12.x series)
- Kernel 6.17.8.arch1-1

---

## Solution 3: libinput Quirks (After Touchpad Detected)

If touchpad starts working but behaves incorrectly, add a quirks file:

**Create:** `/etc/libinput/local-overrides.quirks`

```ini
[Huawei MateBook Touchpad Fix]
MatchName=GXTP7863*
AttrEventCode=-BTN_RIGHT
ModelPressurePad=1
```

---

## Solution 4: External USB Touchpad/Mouse (Alternative)

If touchpad cannot be fixed, use an external input device:

**Recommended USB touchpads for Linux:**
- Apple Magic Trackpad 2 (works via `hid-magicmouse` driver)
- Logitech T650 Wireless Touchpad
- Any standard USB mouse

These are plug-and-play on Linux via `usbhid` driver.

---

## Verification Steps

1. After applying solution, verify touchpad is detected:
   ```bash
   libinput list-devices | grep -A 10 Touchpad
   ```

2. Test touchpad functionality in Hyprland:
   ```bash
   hyprctl devices
   ```

3. Verify Hyprland config at `.config/hypr/input.conf` has touchpad settings

---

## Sources

- [Arch Forum - Touchpad not working after kernel update](https://bbs.archlinux.org/viewtopic.php?id=301467)
- [Arch Forum - Touchpad doesn't work after kernel update](https://bbs.archlinux.org/viewtopic.php?id=310589)
- [linux-hardware.org - GXTP7863 Touchpad](https://linux-hardware.org/?id=ps/2:01e0-01e0-gxtp7863-00-27c6-touchpad)
- [Kernel Bugzilla - Issue 220783](https://bugzilla.kernel.org/show_bug.cgi?id=220783)
