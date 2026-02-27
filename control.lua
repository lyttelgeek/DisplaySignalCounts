local display = require("scripts.display")

--------------------------------------------------
-- STORAGE
--------------------------------------------------

local function ensure_storage()
    storage.displays = storage.displays or {}
end

local function is_display_entity(e)
    return e
        and e.valid
        and e.unit_number
        and (e.type == "display-panel" or e.type == "programmable-speaker")
end

local function add_display(e)
    if not is_display_entity(e) then return end
    ensure_storage()

    local si = e.surface.index
    storage.displays[si] = storage.displays[si] or {}
    storage.displays[si][e.unit_number] = e
end

local function remove_display(e)
    if not is_display_entity(e) then return end
    if not storage.displays then return end

    local si = e.surface.index
    if storage.displays[si] then
        storage.displays[si][e.unit_number] = nil
    end
end

--------------------------------------------------
-- FULL RESCAN
--------------------------------------------------

local function rescan_all_surfaces()
    ensure_storage()

    local total = 0

    for _, surface in pairs(game.surfaces) do
        local si = surface.index
        storage.displays[si] = storage.displays[si] or {}

        local found = surface.find_entities_filtered{
            type = {"display-panel", "programmable-speaker"}
        }

        local added = 0

        for _, e in pairs(found) do
            if is_display_entity(e) and not storage.displays[si][e.unit_number] then
                storage.displays[si][e.unit_number] = e
                added = added + 1
            end
        end

        local count = 0
        for _, _ in pairs(storage.displays[si]) do
            count = count + 1
        end

        total = total + count

        log(("sigd: scan surface=%s idx=%d now=%d added=%d")
            :format(surface.name, si, count, added))
    end

    log(("sigd: scan done total_tracked=%d"):format(total))
end

--------------------------------------------------
-- SPACE AGE DETECTION (platform surface check)
--------------------------------------------------

local function detect_space_age()
    for _, surface in pairs(game.surfaces) do
        if surface.name and surface.name:find("^platform%-") then
            return true
        end
    end
    return false
end

--------------------------------------------------
-- INIT
--------------------------------------------------

script.on_init(function()
    ensure_storage()
    rescan_all_surfaces()
    storage._sigd_has_sa = detect_space_age()
    log(("sigd: detected_space_age=%s"):format(storage._sigd_has_sa and "yes" or "no"))
end)

script.on_configuration_changed(function()
    ensure_storage()
    rescan_all_surfaces()
    storage._sigd_has_sa = detect_space_age()
    log(("sigd: detected_space_age=%s"):format(storage._sigd_has_sa and "yes" or "no"))
end)

--------------------------------------------------
-- BUILD / REMOVE EVENTS
--------------------------------------------------

local filter = {
    { filter = "type", type = "display-panel" },
    { mode = "or", filter = "type", type = "programmable-speaker" }
}

local function on_created(event)
    add_display(event.destination or event.created_entity or event.entity)
end

local function on_removed(event)
    remove_display(event.entity)
end

script.on_event(defines.events.on_built_entity, on_created, filter)
script.on_event(defines.events.on_robot_built_entity, on_created, filter)
script.on_event(defines.events.on_entity_cloned, on_created, filter)
script.on_event(defines.events.script_raised_built, on_created, filter)
script.on_event(defines.events.script_raised_revive, on_created, filter)

script.on_event(defines.events.on_player_mined_entity, on_removed, filter)
script.on_event(defines.events.on_robot_mined_entity, on_removed, filter)
script.on_event(defines.events.on_entity_died, on_removed, filter)
script.on_event(defines.events.script_raised_destroy, on_removed, filter)

--------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------

script.on_nth_tick(30, function()
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
end)

--------------------------------------------------
-- PERIODIC RESCAN (Space Age only)
--------------------------------------------------

script.on_nth_tick(300, function()
    if storage._sigd_has_sa then
        rescan_all_surfaces()
    end
end)