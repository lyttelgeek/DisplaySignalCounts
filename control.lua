local dsc_events = require("scripts.events")

--------------------------------------------------
-- ENTITY TRACKING
--------------------------------------------------

local function is_display_entity(e)
    return e
        and e.valid
        and e.unit_number
        and (e.type == "display-panel" or e.type == "programmable-speaker")
end

local function add_display(e)
    if not is_display_entity(e) then return end
    storage.displays = storage.displays or {}
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
-- SPACE AGE DETECTION
--------------------------------------------------

local function detect_space_age()
    if script.active_mods and script.active_mods["space-age"] then
        return true
    end
    for _, surface in pairs(game.surfaces) do
        if surface.name and surface.name:find("^platform%-") then
            return true
        end
    end
    return false
end

--------------------------------------------------
-- STORAGE MIGRATION (sigd -> dsc)
--------------------------------------------------

local MIGRATE_KEYS = {
    "_sigd_stats",
    "_sigd_has_sa",
    "_sigd_last_rendered",
    "_sigd_wdp_last_rendered",
    "_sigd_speaker_last_rendered",
    "_sigd_panel_edit_grace",
    "_sigd_wdp_edit_grace",
    "_sigd_speaker_edit_grace",
}

local function migrate_storage()
    local migrated = 0
    for _, old_key in pairs(MIGRATE_KEYS) do
        if storage[old_key] ~= nil then
            local new_key = old_key:gsub("^_sigd", "_dsc")
            if storage[new_key] == nil then
                storage[new_key] = storage[old_key]
                migrated = migrated + 1
            end
            storage[old_key] = nil
        end
    end
    -- Wipe any stale round-robin keys from earlier development versions
    storage.surface_index  = nil
    storage.display_index  = nil
    storage.surfaces       = nil
    storage.updates_per_tick = nil
    if migrated > 0 then
        log(("dsc: migrated %d storage keys from sigd prefix"):format(migrated))
    end
end

--------------------------------------------------
-- LIFECYCLE
--------------------------------------------------

script.on_init(function()
    storage._dsc_has_sa = detect_space_age()
    dsc_events.on_init()
    dsc_events.rescan()
end)

script.on_load(function()
    dsc_events.on_load()
end)

script.on_configuration_changed(function()
    migrate_storage()
    storage._dsc_has_sa = detect_space_age()
    dsc_events.on_init()
    dsc_events.rescan()
end)

--------------------------------------------------
-- SETTINGS CHANGED
--------------------------------------------------

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting and event.setting:find("^dsc%-") then
        dsc_events.on_init()
    end
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

script.on_event(defines.events.on_built_entity,        on_created, filter)
script.on_event(defines.events.on_robot_built_entity,  on_created, filter)
script.on_event(defines.events.on_entity_cloned,       on_created, filter)
script.on_event(defines.events.script_raised_built,    on_created, filter)
script.on_event(defines.events.script_raised_revive,   on_created, filter)

script.on_event(defines.events.on_player_mined_entity, on_removed, filter)
script.on_event(defines.events.on_robot_mined_entity,  on_removed, filter)
script.on_event(defines.events.on_entity_died,         on_removed, filter)
script.on_event(defines.events.script_raised_destroy,  on_removed, filter)
