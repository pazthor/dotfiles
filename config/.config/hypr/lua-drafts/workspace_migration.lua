-- Future Hyprland >= 0.55 Lua migration target for split-monitor-workspaces.
--
-- This is intentionally NOT active yet on this machine.
-- Current live config remains:
--   ~/.config/hypr/hyprland.conf
--   ~/.config/hypr/bindings.conf
--
-- Once you switch to a real Hyprland Lua entrypoint (hyprland.lua), this file
-- can be required from that entrypoint and should replace the current
-- split-monitor-workspaces block plus the local workspace binds.

local count = 3
local monitor_priority = { "eDP-1", "HDMI-A-1" }

hl.config({
    plugin = {
        split_monitor_workspaces = {
            count                        = count,
            keep_focused                 = 0,
            enable_notifications         = 0,
            enable_persistent_workspaces = 1,
            enable_wrapping              = 1,
            link_monitors                = 0,
        },
    },
})

local function bind_workspace_keys(smw)
    for i = 1, count do
        local key = tostring(i)

        hl.bind("SUPER + " .. key, function()
            return smw.workspace(i)
        end, { description = "Focus local workspace " .. key })

        hl.bind("SUPER + SHIFT + " .. key, function()
            return smw.move_to_workspace_silent(i)
        end, { description = "Move window to local workspace " .. key })
    end

    hl.bind("SUPER + Tab", function()
        return smw.cycle_workspaces("next")
    end, { description = "Next local workspace" })

    hl.bind("SUPER + SHIFT + Tab", function()
        return smw.cycle_workspaces("prev")
    end, { description = "Previous local workspace" })

    hl.bind("SUPER + ALT + H", function()
        return smw.cycle_workspaces("prev")
    end, { description = "Previous local workspace" })

    hl.bind("SUPER + ALT + L", function()
        return smw.cycle_workspaces("next")
    end, { description = "Next local workspace" })
end

local bootstrap_done = false
local bootstrap_timer

local function bootstrap_split_monitor_workspaces()
    if bootstrap_done then
        return
    end

    local smw = hl.plugin.split_monitor_workspaces
    if smw == nil then
        return
    end

    smw.monitor_priority(monitor_priority)
    bind_workspace_keys(smw)

    bootstrap_done = true
    if bootstrap_timer ~= nil then
        bootstrap_timer:set_enabled(false)
    end
end

-- hyprpm may load the plugin slightly after the initial config parse.
-- Retry until the plugin API becomes available.
bootstrap_timer = hl.timer(bootstrap_split_monitor_workspaces, {
    timeout = 1000,
    type = "repeat",
})

hl.on("hyprland.start", bootstrap_split_monitor_workspaces)
hl.on("config.reloaded", bootstrap_split_monitor_workspaces)

return true
