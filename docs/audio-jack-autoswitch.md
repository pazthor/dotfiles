# Audio Jack Auto-Switch on sof-essx8336

How and why the 3.5mm audio jack stopped auto-switching output on this Huawei
NBD-WXX9 laptop, how it was diagnosed, and what was done to fix it.

---

## The Problem

Plugging a speaker or headphones into the 3.5mm jack produced no sound. Audio
kept playing through HDMI (the external monitor) or the internal speaker. The
jack wasn't broken — the system actually detected it — but nothing switched.

---

## The Linux Audio Stack (what you need to know)

```
Physical hardware
      │
   Kernel driver  (sof-essx8336 → Intel SOF + ES8336 codec)
      │
    ALSA          (kernel's audio interface)
      │
   UCM profiles   (Use Case Manager: defines what "profiles" exist)
      │
  PipeWire        (modern audio server, replaces PulseAudio)
      │
 WirePlumber      (session manager: decides which sink/profile is active)
      │
  pactl / apps    (user-facing control)
```

Each layer has its own job. Most audio problems live in WirePlumber or UCM.

### ALSA and UCM

ALSA is the kernel's audio interface. UCM (Use Case Manager) is a config layer
on top: it tells ALSA what logical profiles, verbs, and sequences exist for each
codec. Files live in `/usr/share/alsa/ucm2/`.

### PipeWire

PipeWire is the audio server. It wraps ALSA devices into "sinks" (outputs) and
"sources" (inputs). It replaced PulseAudio but exposes a PulseAudio-compatible
API (which is why `pactl` still works).

### WirePlumber

WirePlumber is the *session manager* for PipeWire. It decides:
- Which card profile is active
- Which sink is the default
- Which app stream goes to which sink

It runs a chain of Lua hooks to pick a profile whenever a "select-profile" event
fires. The hooks run in this order:

```
find-stored-profile    ← reads ~/.local/state/wireplumber/default-profile
find-preferred-profile ← applies device.profile.priority.rules from config
find-best-profile      ← picks highest-priority available profile
apply-profile          ← applies the selected profile
```

Each hook skips if a previous hook already set a profile. **The stored profile
always wins.**

---

## What Made This Laptop Special

Most audio cards expose Speaker and Headphones as two *routes* (ports) within
one card profile — switching between them just means selecting a different port.
WirePlumber handles that automatically.

The ES8336 codec (via the `sof-essx8336` SOF driver) exposes them as two
**separate card profiles**:

| Profile | Priority | Outputs |
|---|---|---|
| `HiFi (HDMI1, HDMI2, HDMI3, Headphones, Headset, Mic)` | 10500 | Headphones |
| `HiFi (HDMI1, HDMI2, HDMI3, Headset, Mic, Speaker)` | 10300 | Internal speaker |

Plugging in headphones requires switching the entire card profile, not just a
port. WirePlumber doesn't do this automatically for ALSA cards the way it does
for Bluetooth.

---

## Diagnosis: What to Look At

### 1. Check what sinks exist

```bash
pactl list sinks short
```

Look for a Headphone or Headset sink. If only HDMI and Speaker sinks are
present when headphones are plugged in, the card is on the wrong profile.

### 2. Check card profiles and port availability

```bash
pactl list cards
```

Key things to look for:

- **Active Profile** — which profile is currently in use
- **Available profiles** — what profiles exist and their `available:` state
- **Port availability** — find `[Out] Headphones:` and check whether it says
  `available)` or `not available)`

If the Headphones port shows `available` but the active profile doesn't include
headphones, you've found the problem: the profile isn't switching.

### 3. Check what WirePlumber saved

```bash
cat ~/.local/state/wireplumber/default-profile
```

This file is the stored profile per device. If it shows the Speaker profile for
your card while headphones are plugged in, WirePlumber is locked on the wrong
profile.

### 4. Check system info

```bash
fastfetch --no-logo   # hardware overview
aplay -l              # ALSA playback devices
```

The card name in `aplay -l` tells you the UCM config to look at:
`/usr/share/alsa/ucm2/Intel/sof-essx8336/`.

### 5. Check WirePlumber hook scripts

```
/usr/share/wireplumber/scripts/device/
  find-stored-profile → actually in state-profile.lua
  find-preferred-profile.lua
  find-best-profile.lua
  apply-profile.lua
```

Reading these shows the hook priority order and where stored state is loaded.

---

## The Fix

A script that watches PipeWire card events and switches the profile based on
headphone port availability:

**`~/.local/bin/audio-jack-switch`** (tracked in dotfiles):

```bash
#!/usr/bin/env bash
CARD="alsa_card.pci-0000_00_1f.3-platform-sof-essx8336"
HP_PROFILE="HiFi (HDMI1, HDMI2, HDMI3, Headphones, Headset, Mic)"
SP_PROFILE="HiFi (HDMI1, HDMI2, HDMI3, Headset, Mic, Speaker)"

switch_profile() {
    if pactl list cards 2>/dev/null | grep -A6 "\[Out\] Headphones:" | grep -q ", available)"; then
        pactl set-card-profile "$CARD" "$HP_PROFILE" 2>/dev/null
    else
        pactl set-card-profile "$CARD" "$SP_PROFILE" 2>/dev/null
    fi
}

switch_profile  # run on startup

pactl subscribe 2>/dev/null | grep --line-buffered "card" | while read -r _; do
    switch_profile
done
```

**`~/.config/systemd/user/audio-jack-switch.service`** (tracked in dotfiles):
runs the script as a user service after PipeWire starts, restarts on failure.

Enable once:
```bash
systemctl --user enable --now audio-jack-switch.service
```

---

## Why Not Fix WirePlumber Directly?

The stored profile mechanism (`device.restore-profile` setting) can be disabled:

```conf
# ~/.config/wireplumber/wireplumber.conf.d/50-disable-restore.conf
wireplumber.settings = {
  device.restore-profile = false
}
```

With it disabled, `find-best-profile` always wins and would pick the Headphones
profile (priority 10500 > 10300). But this has a downside: when no headphones
are plugged in, *both* profiles still show `available: yes` (availability is
about digital readiness, not jack detection), so WirePlumber would always pick
the Headphones profile — even with nothing plugged in. Whether that's a problem
depends on the card, but it's less predictable than an explicit switch.

The script approach is explicit and observable.

---

## Useful Commands for Debugging Audio

```bash
# Full card info (profiles, ports, availability)
pactl list cards

# All sinks (outputs) and their state
pactl list sinks

# Current default sink
pactl info | grep "Default Sink"

# Manually switch card profile
pactl set-card-profile <card-name> "<profile-name>"

# Switch default sink
pactl set-default-sink <sink-name>

# Watch PipeWire events in real time
pactl subscribe

# WirePlumber status (sinks, sources, streams)
wpctl status

# Inspect a specific node
wpctl inspect <id>

# ALSA cards and devices
aplay -l

# ALSA mixer controls for a card
alsamixer -c 0

# UCM config for this card
ls /usr/share/alsa/ucm2/Intel/sof-essx8336/

# WirePlumber hook scripts
ls /usr/share/wireplumber/scripts/device/

# WirePlumber saved state
cat ~/.local/state/wireplumber/default-profile
cat ~/.local/state/wireplumber/default-routes

# Service logs
journalctl --user -u audio-jack-switch -f
journalctl --user -u wireplumber -f
```

---

## Where Problems Tend to Live

| Symptom | Where to look |
|---|---|
| No sound at all | `aplay -l`, `pactl list sinks`, WirePlumber service running? |
| Wrong output device | `pactl list cards` → active profile and port availability |
| Jack not switching | `~/.local/state/wireplumber/default-profile`, UCM profile split |
| Profile switches but no audio | Muted? `pactl list sinks` → Mute field; `alsamixer` |
| Regression after update | WirePlumber, PipeWire, or kernel/SOF driver update changed behavior |
| App routing to wrong sink | `wpctl status` → Streams section shows which sink each app uses |
