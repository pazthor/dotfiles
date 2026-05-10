# Hyprland Lua migration draft

This directory contains the **first migration target** for moving your Hyprland config toward Lua **without touching the current live setup yet**.

## Current live authority

These files are still active on this machine:

- `~/.config/hypr/hyprland.conf`
- `~/.config/hypr/bindings.conf`
- `~/.config/hypr/monitors.conf`

## Why this is only a draft right now

Your current runtime is:

- `Hyprland 0.54.3`

The current upstream wiki documents Lua as the primary config model for **0.55+**.

After verification, the safe conclusion for your machine is:

- keep the current `.conf` setup live
- prepare Lua in parallel
- activate Lua only when you intentionally switch to a real `hyprland.lua` entrypoint on a compatible Hyprland version

## Important correction

You asked to keep `hyprland.conf` as the entrypoint.

For an **active** Lua migration, that is not the right end state.
The Lua-based setup should use:

- `~/.config/hypr/hyprland.lua`

So the practical path is:

1. keep `hyprland.conf` active now
2. draft Lua modules now
3. switch entrypoint later when you upgrade and are ready

## What is already drafted

- `workspace_migration.lua`

That file is the first Lua migration unit and is intended to replace only:

- the `split-monitor-workspaces` plugin block in `hyprland.conf`
- the local workspace bindings in `bindings.conf`

It preserves your current behavior goal:

- 3 workspaces per monitor
- `eDP-1` first
- `HDMI-A-1` second
- local `SUPER+1..3`
- local `SUPER+SHIFT+1..3`
- local `SUPER+TAB` / `SUPER+SHIFT+TAB`
- local `SUPER+ALT+H/L`

## Activation later

When you decide to switch for real:

1. upgrade/confirm a Lua-capable Hyprland workflow
2. create `~/.config/hypr/hyprland.lua`
3. require this module from that Lua entrypoint
4. remove duplicate workspace/plugin definitions from `.conf`
5. reload and validate

## Not part of this Lua migration

These should stay in their native formats:

- `~/.config/waybar/config.jsonc`
- `~/.config/waybar/style.css`
- `~/.config/hypr/hypridle.conf`
- `~/.config/hypr/hyprlock.conf`

## Git / commit note

`~/.config/hypr` is **not currently inside a git repository**, so I did not create a commit from this live config directory.
If you want, the next safe step is to either:

- sync these files into your dotfiles repo, then commit there, or
- initialize a dedicated git repo for `~/.config/hypr`
