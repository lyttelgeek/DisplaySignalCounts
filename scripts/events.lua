local display = require("scripts.display")

--- @class dsc_events
local dsc_events = {}

--------------------------------------------------
-- STORAGE
--------------------------------------------------

local function ensure_storage()
    storage.displays        = storage.displays        or {}
    storage.updates_per_tick = storage.updates_per_tick or 1
    storage.update_nth_tick  = storage.update_nth_tick  or 2
end

--------------------------------------------------
-- RESCAN
--------------------------------------------------

local function is_display_entity(e)
    return e
        and e.valid
        and e.unit_number
        and (e.type == "display-panel" or e.type == "programmable-speaker")
end

local function rescan_all_surfaces()
    storage.displays = storage.displays or {}
    for _, surface in pairs(game.surfaces) do
        local si = surface.index
        storage.displays[si] = storage.displays[si] or {}
        local found = surface.find_entities_filtered{
            type = {"display-panel", "programmable-speaker"}
        }
        for _, e in pairs(found) do
            if is_display_entity(e) and not storage.displays[si][e.unit_number] then
                storage.displays[si][e.unit_number] = e
            end
        end
    end
end

--------------------------------------------------
-- TICK HANDLER
--------------------------------------------------

local function on_tick()
    local displays = storage.displays
    if not displays then return end

    for _, surface_displays in pairs(displays) do
        for unit, entity in pairs(surface_displays) do
            if entity and entity.valid then
                display.update_display(entity)
            else
                surface_displays[unit] = nil
            end
        end
    end
end

local function on_rescan_tick()
    if storage._dsc_has_sa then
        rescan_all_surfaces()
    end
end

--------------------------------------------------
-- PUBLIC API
--------------------------------------------------

-- register_events: called from both on_init and on_load.
function dsc_events.register_events()
    local nth = (storage and storage.update_nth_tick) or 2
    -- Clear and re-register both handlers together so neither wipes the other.
    script.on_nth_tick(nil)
    script.on_nth_tick(nth, on_tick)
    script.on_nth_tick(300, on_rescan_tick)
end

function dsc_events.on_init()
    ensure_storage()

    if settings and settings.global then
        local ok
        ok = pcall(function()
            storage.updates_per_tick = settings.global["dsc-updates-per-tick"].value
        end)
        if not ok then storage.updates_per_tick = 1 end

        ok = pcall(function()
            storage.update_nth_tick = settings.global["dsc-update-nth-tick"].value
        end)
        if not ok then storage.update_nth_tick = 2 end
    end

    dsc_events.register_events()
end

function dsc_events.on_load()
    dsc_events.register_events()
end

function dsc_events.rescan()
    rescan_all_surfaces()
end

return dsc_events
