local display = require("scripts.display")

--- @class sigd_events
local sigd_events = {}

-- Set to true if you ONLY want to update surfaces that have connected players on them.
-- Set to false to update all tracked displays regardless of player presence (safer for platforms if tracking is correct).
local ONLY_ACTIVE_SURFACES = false

local function ensure_storage()
    storage.displays = storage.displays or {}
    storage.display_index = storage.display_index or {}
    storage.surface_index = storage.surface_index or nil
    storage.surfaces = storage.surfaces or {} -- map surface_index -> active bool
    storage.updates_per_tick = storage.updates_per_tick or 1
    storage.update_nth_tick = storage.update_nth_tick or 30
end

-- Refresh which surfaces are "active" (player present/connected)
local function refresh_active_surfaces()
    storage.surfaces = storage.surfaces or {}
    for idx, _ in pairs(storage.surfaces) do
        storage.surfaces[idx] = false
    end
    for _, player in pairs(game.players) do
        if player and player.valid and player.connected and player.surface then
            storage.surfaces[player.surface.index] = true
        end
    end
end

-- Pick next surface to process.
local function next_surface()
    if not storage.displays then return nil end
    local surface_index, surface_displays

    while true do
        surface_index, surface_displays = next(storage.displays, storage.surface_index)
        storage.surface_index = surface_index
        if surface_index == nil then
            -- wrap around
            storage.surface_index = nil
            return nil
        end

        if surface_displays ~= nil then
            if not ONLY_ACTIVE_SURFACES then
                return surface_index, surface_displays
            end
            if storage.surfaces and storage.surfaces[surface_index] then
                return surface_index, surface_displays
            end
        end
    end
end

-- Pick next display on a surface to process.
local function next_display(surface_index, surface_displays)
    storage.display_index[surface_index] = storage.display_index[surface_index] or nil

    while true do
        local unit_number, ent = next(surface_displays, storage.display_index[surface_index])
        storage.display_index[surface_index] = unit_number

        if unit_number == nil then
            -- wrap this surface
            storage.display_index[surface_index] = nil
            return nil
        end

        if ent and ent.valid then
            return ent
        else
            -- drop invalids on sight
            surface_displays[unit_number] = nil
        end
    end
end

--- @param e EventData.on_tick
local function on_tick(e)
    ensure_storage()

    if ONLY_ACTIVE_SURFACES then
        -- cheap enough and avoids stale "active" states
        refresh_active_surfaces()
    end

    local updates = storage.updates_per_tick or 1
    if updates < 1 then updates = 1 end

    for _ = 1, updates do
        local surface_index, surface_displays = next_surface()
        if not surface_index then
            return
        end

        local ent = next_display(surface_index, surface_displays)
        if ent then
            display.update_display(ent)
        end
    end
end

function sigd_events.register_events()
    ensure_storage()
    script.on_nth_tick(nil)
    script.on_nth_tick(storage.update_nth_tick, on_tick)
end

function sigd_events.on_init()
    ensure_storage()

    -- Pull settings if they exist; otherwise keep defaults
    if settings and settings.global then
        local ok

        ok = pcall(function() storage.updates_per_tick = settings.global["sigd-updates-per-tick"].value end)
        if not ok then storage.updates_per_tick = 1 end

        ok = pcall(function() storage.update_nth_tick = settings.global["sigd-update-nth-tick"].value end)
        if not ok then storage.update_nth_tick = 30 end
    end

    sigd_events.register_events()
end

function sigd_events.on_load()
    if not storage then return end
    sigd_events.register_events()
end

return sigd_events