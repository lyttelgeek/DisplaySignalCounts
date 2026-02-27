local util = require("util")

local display = {}

--------------------------------------------------
-- SETTINGS / FORMATTING
--------------------------------------------------

local function get_setting_bool(name, default)
    local ok, s = pcall(function() return settings.global[name] end)
    if ok and s and s.value ~= nil then return s.value end
    return default
end

-- force_mode: nil | "si" | "exact"
local function format_value(v, force_mode)
    local want_si
    if force_mode == "si" then
        want_si = true
    elseif force_mode == "exact" then
        want_si = false
    else
        want_si = get_setting_bool("sigd-show-formatted-number", true)
    end

    if want_si then
        local ok, res = pcall(function()
            if util and util.format_number then
                return util.format_number(v, true)
            end
            return nil
        end)
        if ok and res ~= nil then
            return res
        end
    end

    return tostring(v)
end

--------------------------------------------------
-- EDIT GRACE WINDOW
--------------------------------------------------

local EDIT_GRACE_TICKS = 90 -- ~1.5s at 60 UPS

local function grace_store(table_name)
    storage[table_name] = storage[table_name] or {}
    return storage[table_name]
end

local function in_grace(grace_tbl, unit, idx)
    local t = (game and game.tick) or 0
    local u = grace_tbl[unit]
    if not u then return false end
    local start = u[idx]
    if not start then return false end
    if (t - start) <= EDIT_GRACE_TICKS then
        return true
    end
    u[idx] = nil
    return false
end

local function start_grace(grace_tbl, unit, idx)
    local t = (game and game.tick) or 0
    grace_tbl[unit] = grace_tbl[unit] or {}
    grace_tbl[unit][idx] = t
end

--------------------------------------------------
-- UNICODE SPACE HELPERS
--------------------------------------------------

local NBSP  = "\194\160"      -- U+00A0
local NNBSP = "\226\128\175"  -- U+202F
local IDEO  = "\227\128\128"  -- U+3000

local function strip_weird_spaces(s)
    if not s or s == "" then return s end
    s = s:gsub("%s+", "")
    s = s:gsub(NBSP, "")
    s = s:gsub(NNBSP, "")
    s = s:gsub("\226\128[\128-\138]", "") -- U+2000..U+200A
    s = s:gsub("\226\128\139", "")        -- U+200B
    s = s:gsub(IDEO, "")
    return s
end

local function is_blank_like(s)
    if s == nil then return true end
    if s == "" then return true end
    return strip_weird_spaces(s) == ""
end

local function contains_blank_brackets(text)
    if type(text) ~= "string" then return false end
    local i = 1
    while true do
        local lb = text:find("[", i, true)
        if not lb then return false end
        local rb = text:find("]", lb + 1, true)
        if not rb then return false end
        local inside = text:sub(lb + 1, rb - 1)
        if is_blank_like(inside) then
            return true
        end
        i = rb + 1
    end
end

local function normalize_directive_token(s)
    if not s then return "" end
    s = s:gsub(NBSP, ""):gsub(NNBSP, ""):gsub("\226\128[\128-\138]", ""):gsub("\226\128\139", ""):gsub(IDEO, "")
    s = (s:match("^%s*(.-)%s*$") or s)
    s = s:lower()
    s = s:gsub("[\128-\255]", "")
    s = s:gsub("%s+", " ")
    s = (s:match("^%s*(.-)%s*$") or s)
    return s
end

-- letters-only key from RAW bracket content (bulletproof)
local function raw_letters_only_key(raw)
    if not raw then return "" end
    local s = raw:lower()
    s = s:gsub("[^a-z]", "")
    return s
end

local function first_word_letters_only_key(norm)
    if not norm or norm == "" then return "" end
    local first = norm:match("^(%S+)") or norm
    first = first:gsub("[^a-z]", "")
    return first
end

--------------------------------------------------
-- PLACEHOLDERS / SIGNAL KEYS
--------------------------------------------------

local function has_placeholder(text)
    if type(text) ~= "string" then return false end
    if contains_blank_brackets(text) then return true end
    return (text:find("%[abs%]") ~= nil)
        or (text:find("%[delta%]") ~= nil)
        or (text:find("%[rate%]") ~= nil)
        or (text:find("%[avg%]") ~= nil)
        or (text:find("%[min%]") ~= nil)
        or (text:find("%[max%]") ~= nil)
        or (text:find("%[prec") ~= nil)
        or (text:find("%[clamp") ~= nil)
        or (text:find("%[sign%]") ~= nil)
        or (text:find("%[pct%]") ~= nil)
        or (text:find("%[sig") ~= nil)
        or (text:find("%[floor%]") ~= nil)
        or (text:find("%[ceil%]") ~= nil)
        or (text:find("%[round%]") ~= nil)
        or (text:find("%[color") ~= nil)
        or (text:find("%[colour") ~= nil)
        or (text:find("%[dz") ~= nil)
        or (text:find("%[si%]") ~= nil)
        or (text:find("%[exact%]") ~= nil)
end

local function normalize_signal_type(t)
    if t == nil then return "item" end
    if t == "virtual-signal" then return "virtual" end
    return t
end

local function normalize_quality(q)
    if q == nil or q == "" or q == "normal" then return "" end
    return q
end

local function make_sigkey_from_parts(type_, name, quality)
    if not name or name == "" then return nil end
    type_ = normalize_signal_type(type_ or "item")
    quality = normalize_quality(quality)
    return tostring(type_) .. "|" .. tostring(name) .. "|" .. tostring(quality or "")
end

local function make_sigkey(sig)
    if not sig or not sig.name then return nil end
    return make_sigkey_from_parts(sig.type, sig.name, sig.quality)
end

--------------------------------------------------
-- SIGNAL COLLECTION (single-source)
--------------------------------------------------

local function merge_row(map, row)
    if not (row and row.signal and row.signal.name) then return end
    local k = make_sigkey(row.signal)
    if not k then return end
    map[k] = (map[k] or 0) + (row.count or 0)
end

local function merge_net(map, net)
    if not (net and net.valid) then return 0 end
    local ok_sigs, sigs = pcall(function() return net.signals end)
    if not ok_sigs or type(sigs) ~= "table" then return 0 end
    local n = 0
    for i = 1, #sigs do
        local row = sigs[i]
        if row and row.signal and row.signal.name then
            n = n + 1
            merge_row(map, row)
        end
    end
    return n
end

local function build_signal_map_single_source(entity, behavior)
    local map = {}

    local ok_r, net_r = pcall(function() return behavior and behavior.get_circuit_network(defines.wire_connector_id.circuit_red) end)
    local ok_g, net_g = pcall(function() return behavior and behavior.get_circuit_network(defines.wire_connector_id.circuit_green) end)
    local rcc = (ok_r and net_r and net_r.connected_circuit_count) or 0
    local gcc = (ok_g and net_g and net_g.connected_circuit_count) or 0
    if (rcc + gcc) > 0 then
        if ok_r and net_r then merge_net(map, net_r) end
        if ok_g and net_g then merge_net(map, net_g) end
        return map
    end

    ok_r, net_r = pcall(function() return entity.get_circuit_network(defines.wire_connector_id.circuit_red) end)
    ok_g, net_g = pcall(function() return entity.get_circuit_network(defines.wire_connector_id.circuit_green) end)
    rcc = (ok_r and net_r and net_r.connected_circuit_count) or 0
    gcc = (ok_g and net_g and net_g.connected_circuit_count) or 0
    if (rcc + gcc) > 0 then
        if ok_r and net_r then merge_net(map, net_r) end
        if ok_g and net_g then merge_net(map, net_g) end
        return map
    end

    local ok, sigs = pcall(entity.get_signals, entity, defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green)
    if ok and type(sigs) == "table" then
        for i = 1, #sigs do merge_row(map, sigs[i]) end
    end

    return map
end

--------------------------------------------------
-- SIGNAL PICKERS
--------------------------------------------------

local function parse_signal_from_text(template)
    if type(template) ~= "string" then return nil end
    local name

    name = template:match("%[virtual%-signal=([^%]]+)%]")
    if name then return { type = "virtual", name = name } end

    name = template:match("%[item=([^%]]+)%]")
    if name then return { type = "item", name = name } end

    name = template:match("%[fluid=([^%]]+)%]")
    if name then return { type = "fluid", name = name } end

    return nil
end

local function pick_panel_default_signal(message, template)
    if message and message.condition and message.condition.first_signal and message.condition.first_signal.name then
        return message.condition.first_signal
    end
    local from_text = parse_signal_from_text(template)
    if from_text and from_text.name then
        return from_text
    end
    return nil
end

local function pick_speaker_signal_def(entity, behavior)
    local ok_ap, ap = pcall(function() return entity.alert_parameters end)
    if ok_ap and type(ap) == "table" and ap.icon_signal_id and ap.icon_signal_id.name then
        return ap.icon_signal_id
    end

    local ok_cc, cc = pcall(function() return behavior and behavior.circuit_condition end)
    if ok_cc and type(cc) == "table" and cc.first_signal and cc.first_signal.name then
        return cc.first_signal
    end

    return nil
end

--------------------------------------------------
-- STATS
--------------------------------------------------

local AVG_TAU_SECONDS = 5
local MINMAX_WINDOW_SECONDS = 10

local function stats_root()
    storage._sigd_stats = storage._sigd_stats or {}
    return storage._sigd_stats
end

local function get_stat_slot(root, unit, idx, key)
    root[unit] = root[unit] or {}
    root[unit][idx] = root[unit][idx] or {}
    local slot = root[unit][idx][key]
    if not slot then
        slot = {
            last_tick = nil,
            last_value = 0,
            avg = nil,
            min = nil,
            max = nil,
            minmax_start_tick = nil,
        }
        root[unit][idx][key] = slot
    end
    return slot
end

local function update_metrics(unit, idx, key, value)
    local root = stats_root()
    local slot = get_stat_slot(root, unit, idx, key)

    local t = (game and game.tick) or 0
    local last_t = slot.last_tick
    local last_v = slot.last_value or 0

    local dt_ticks = (last_t and (t - last_t)) or 0
    if dt_ticks < 0 then dt_ticks = 0 end
    if dt_ticks == 0 then dt_ticks = 1 end
    local dt_sec = dt_ticks / 60

    local delta = value - last_v
    local rate = delta / dt_sec

    local avg = slot.avg
    if avg == nil then
        avg = value
    else
        local alpha = (AVG_TAU_SECONDS <= 0) and 1 or (1 - math.exp(-dt_sec / AVG_TAU_SECONDS))
        avg = avg + alpha * (value - avg)
    end

    local w_ticks = MINMAX_WINDOW_SECONDS * 60
    local w_start = slot.minmax_start_tick
    local mn = slot.min
    local mx = slot.max

    if w_start == nil or (t - w_start) > w_ticks then
        w_start = t
        mn = value
        mx = value
    else
        if mn == nil or value < mn then mn = value end
        if mx == nil or value > mx then mx = value end
    end

    slot.last_tick = t
    slot.last_value = value
    slot.avg = avg
    slot.min = mn
    slot.max = mx
    slot.minmax_start_tick = w_start

    return delta, rate, avg, mn, mx
end

--------------------------------------------------
-- RENDER
--------------------------------------------------

local COLOR_DEADZONE_DEFAULT = 1e-6

local function clamp_value(v, a, b)
    if a ~= nil and v < a then return a end
    if b ~= nil and v > b then return b end
    return v
end

local function format_with_prec(v, prec)
    prec = tonumber(prec)
    if prec == nil then return format_value(v) end
    if prec < 0 then prec = 0 end
    if prec > 12 then prec = 12 end
    return string.format("%." .. tostring(prec) .. "f", v)
end

local function parse_sig_modifier(norm)
    if norm == "sig" then
        return "reset", nil
    end
    local t, name, q = norm:match("^sig%s+(%S+)%s+(%S+)%s*(%S*)$")
    if not t or not name then return nil, nil end
    if q == "" then q = nil end
    t = normalize_signal_type(t)
    local key = make_sigkey_from_parts(t, name, q)
    return "set", key
end

local function parse_color_modifier(norm)
    local head, rest = norm:match("^(colou?r)%s*(.*)$")
    if not head then return nil end
    rest = rest or ""
    rest = rest:match("^%s*(.-)%s*$") or rest

    if rest == "" then
        return { mode = "auto" }
    end

    local dz = rest:match("^deadzone%s+(-?%d+%.?%d*)$")
    if dz then
        return { mode = "auto", deadzone = tonumber(dz) }
    end

    dz = rest:match("^dz%s+(-?%d+%.?%d*)$")
    if dz then
        return { mode = "auto", deadzone = tonumber(dz) }
    end

    local col = rest:match("^(%S+)$")
    if col then
        return { mode = "manual", color = col }
    end

    return { mode = "auto" }
end

-- Allow Factorio rich-text [colour=...] and [/colour] by converting to [color=...] and [/color]
local function normalize_rich_text_tag(tag_inside)
    if type(tag_inside) ~= "string" then return tag_inside end
    if tag_inside:sub(1, 6) == "colour" then
        return "color" .. tag_inside:sub(7)
    end
    if tag_inside:sub(1, 7) == "/colour" then
        return "/color" .. tag_inside:sub(8)
    end
    return tag_inside
end

local function render_template(template, unit, msg_idx, sigmap, default_sigkey)
    if type(template) ~= "string" then return template end

    local out = {}
    local i = 1
    local len = #template

    -- modifiers (apply to NEXT numeric placeholder only)
    local pending_prec = nil
    local pending_clamp_a = nil
    local pending_clamp_b = nil
    local pending_sign = false
    local pending_round = nil       -- "floor" / "ceil" / "round"
    local pending_fmt = nil         -- nil | "si" | "exact"
    local pending_pct = false       -- clamp 0..100 + append %

    local pending_color_mode = nil  -- nil | "auto" | "manual"
    local pending_color_value = nil
    local pending_color_deadzone = nil -- only used for auto

    local current_sigkey = default_sigkey
    local metrics_cache = {}

    local function reset_mods()
        pending_prec = nil
        pending_clamp_a = nil
        pending_clamp_b = nil
        pending_sign = false
        pending_round = nil
        pending_fmt = nil
        pending_pct = false
        pending_color_mode = nil
        pending_color_value = nil
        pending_color_deadzone = nil
    end

    local function get_metrics_for(sigkey)
        sigkey = sigkey or "__none__"
        local m = metrics_cache[sigkey]
        if m then return m end

        local v = 0
        if sigkey ~= "__none__" then
            v = sigmap[sigkey] or 0
        end

        local d, r, a, mn, mx = update_metrics(unit, msg_idx, sigkey, v)
        m = { value = v, delta = d, rate = r, avg = a, min = mn, max = mx }
        metrics_cache[sigkey] = m
        return m
    end

    local function apply_round(vnum)
        if pending_round == "floor" then
            return math.floor(vnum)
        elseif pending_round == "ceil" then
            return math.ceil(vnum)
        elseif pending_round == "round" then
            if vnum >= 0 then return math.floor(vnum + 0.5) end
            return math.ceil(vnum - 0.5)
        end
        return vnum
    end

    local function apply_color_wrap(s, vnum)
        if not pending_color_mode then return s end

        local c
        if pending_color_mode == "manual" then
            c = pending_color_value or "yellow"
        else
            local dz = pending_color_deadzone
            if dz == nil then dz = COLOR_DEADZONE_DEFAULT end
            if dz < 0 then dz = -dz end

            if math.abs(vnum) < dz then
                c = "yellow"
            elseif vnum > 0 then
                c = "green"
            else
                c = "red"
            end
        end

        return "[color=" .. c .. "]" .. s .. "[/color]"
    end

    local function emit_number(vnum)
        vnum = tonumber(vnum) or 0

        -- pct helper: clamp 0..100 + append %
        if pending_pct then
            pending_clamp_a = 0
            pending_clamp_b = 100
        end

        vnum = clamp_value(vnum, pending_clamp_a, pending_clamp_b)
        vnum = apply_round(vnum)

        local num_str
        if pending_prec ~= nil then
            num_str = format_with_prec(vnum, pending_prec)
        else
            num_str = format_value(vnum, pending_fmt)
        end

        local already_negative = (num_str:sub(1, 1) == "-")

        -- [sign]: prepend + for positives, ± for zero. negatives already show "-".
        local sign_prefix = ""
        if pending_sign and not already_negative then
            if vnum > 0 then
                sign_prefix = " +"
            elseif vnum == 0 then
                sign_prefix = " ±"
            end
        end

        local final_str = sign_prefix .. num_str
        if pending_pct then
            final_str = final_str .. "%"
        end

        local colored = apply_color_wrap(final_str, vnum)

        reset_mods()
        out[#out + 1] = colored
    end

    local function emit_from_kind(kind)
        local sigkey = current_sigkey or "__none__"
        local m = get_metrics_for(sigkey)

        if kind == "value" then emit_number(m.value)
        elseif kind == "abs" then emit_number(math.abs(m.value))
        elseif kind == "delta" then emit_number(m.delta)
        elseif kind == "rate" then emit_number(m.rate)
        elseif kind == "avg" then emit_number(m.avg)
        elseif kind == "min" then emit_number(m.min)
        elseif kind == "max" then emit_number(m.max)
        else emit_number(0)
        end
    end

    while i <= len do
        local lb = template:find("[", i, true)
        if not lb then
            out[#out + 1] = template:sub(i)
            break
        end
        if lb > i then
            out[#out + 1] = template:sub(i, lb - 1)
        end

        local rb = template:find("]", lb + 1, true)
        if not rb then
            out[#out + 1] = template:sub(lb)
            break
        end

        local inside_raw = template:sub(lb + 1, rb - 1)

        -- Factorio rich-text ([color=...], [/color], etc): preserve literally.
        -- Also rewrite [colour=...] and [/colour] to Factorio's [color=...] / [/color].
        if inside_raw:find("=", 1, true) or inside_raw:find("^/") then
            out[#out + 1] = "[" .. normalize_rich_text_tag(inside_raw) .. "]"
            i = rb + 1
            goto continue
        end

        if is_blank_like(inside_raw) then
            emit_from_kind("value")
            i = rb + 1
            goto continue
        end

        local rawkey = raw_letters_only_key(inside_raw)
        local norm = normalize_directive_token(inside_raw)
        local key = first_word_letters_only_key(norm)

        -- [sig] or [sig ...] (IMPORTANT: do NOT swallow [sign])
        if norm == "sig" or norm:find("^sig%s") then
            local mode, sigkey = parse_sig_modifier(norm)
            if mode == "reset" then
                current_sigkey = default_sigkey
            elseif mode == "set" then
                current_sigkey = sigkey
            end
            i = rb + 1
            goto continue
        end

        -- standalone deadzone modifier: [dz 0.01]
        local dz_only = norm:match("^dz%s+(-?%d+%.?%d*)$")
        if dz_only then
            pending_color_deadzone = tonumber(dz_only)
            i = rb + 1
            goto continue
        end

        -- modifiers
        local nprec = norm:match("^prec%s*(-?%d+)$")
        if nprec then pending_prec = tonumber(nprec) or 0; i = rb + 1; goto continue end

        local a, b = norm:match("^clamp%s*(-?%d+%.?%d*)%s+(-?%d+%.?%d*)$")
        if a and b then
            pending_clamp_a = tonumber(a)
            pending_clamp_b = tonumber(b)
            if pending_clamp_a and pending_clamp_b and pending_clamp_a > pending_clamp_b then
                pending_clamp_a, pending_clamp_b = pending_clamp_b, pending_clamp_a
            end
            i = rb + 1
            goto continue
        end

        if rawkey == "sign" or key == "sign" then pending_sign = true; i = rb + 1; goto continue end
        if rawkey == "pct" or key == "pct" then pending_pct = true; i = rb + 1; goto continue end

        if rawkey == "floor" or key == "floor" then pending_round = "floor"; i = rb + 1; goto continue end
        if rawkey == "ceil"  or key == "ceil"  then pending_round = "ceil";  i = rb + 1; goto continue end
        if rawkey == "round" or key == "round" then pending_round = "round"; i = rb + 1; goto continue end

        if rawkey == "color" or rawkey == "colour" or key == "color" or key == "colour" then
            local spec = parse_color_modifier(norm)
            if spec then
                if spec.mode == "manual" then
                    pending_color_mode = "manual"
                    pending_color_value = spec.color
                else
                    pending_color_mode = "auto"
                    -- allow prior [dz N] to apply if set
                    if spec.deadzone ~= nil then
                        pending_color_deadzone = spec.deadzone
                    end
                end
            else
                pending_color_mode = "auto"
            end
            i = rb + 1
            goto continue
        end

        if rawkey == "si" or key == "si" then pending_fmt = "si"; i = rb + 1; goto continue end
        if rawkey == "exact" or key == "exact" then pending_fmt = "exact"; i = rb + 1; goto continue end

        -- outputs
        if rawkey == "abs" or key == "abs" then emit_from_kind("abs"); i = rb + 1; goto continue end
        if rawkey == "delta" or key == "delta" then emit_from_kind("delta"); i = rb + 1; goto continue end
        if rawkey == "rate" or key == "rate" then emit_from_kind("rate"); i = rb + 1; goto continue end
        if rawkey == "avg" or key == "avg" then emit_from_kind("avg"); i = rb + 1; goto continue end
        if rawkey == "min" or key == "min" then emit_from_kind("min"); i = rb + 1; goto continue end
        if rawkey == "max" or key == "max" then emit_from_kind("max"); i = rb + 1; goto continue end

        -- unknown: keep literal
        out[#out + 1] = "[" .. inside_raw .. "]"
        i = rb + 1

        ::continue::
    end

    local rendered = table.concat(out)
    if rendered == "" then return template end
    return rendered
end

--------------------------------------------------
-- UPDATE: DISPLAY PANEL
--------------------------------------------------

local function update_display_panel(entity)
    if not (entity and entity.valid) then return end
    if entity.type ~= "display-panel" then return end

    local behavior = entity.get_or_create_control_behavior()
    if not behavior then return end

    local ok_msgs, messages = pcall(function() return behavior.messages end)
    if not ok_msgs or type(messages) ~= "table" then return end

    storage.display_templates = storage.display_templates or {}
    storage._sigd_last_rendered = storage._sigd_last_rendered or {}

    local grace = grace_store("_sigd_panel_edit_grace")

    local unit = entity.unit_number

    storage.display_templates[unit] = storage.display_templates[unit] or {}
    storage._sigd_last_rendered[unit] = storage._sigd_last_rendered[unit] or {}

    local templates = storage.display_templates[unit]
    local last_rendered = storage._sigd_last_rendered[unit]

    local sigmap = build_signal_map_single_source(entity, behavior)

    local changed_any = false

    for idx, message in pairs(messages) do
        if not message then goto continue end

        local current_text = message.text
        if current_text == nil or type(current_text) ~= "string" then
            last_rendered[idx] = current_text
            goto continue
        end

        local lr = last_rendered[idx]

        -- detect user edit and adopt template (with grace window)
        if lr ~= nil and current_text ~= lr then
            start_grace(grace, unit, idx)
            if has_placeholder(current_text) then
                templates[idx] = current_text
            else
                templates[idx] = nil
            end
            last_rendered[idx] = current_text
            goto continue
        end

        if in_grace(grace, unit, idx) then
            last_rendered[idx] = current_text
            goto continue
        end

        -- adopt initial template only when placeholders exist
        if templates[idx] == nil then
            if has_placeholder(current_text) then
                templates[idx] = current_text
            else
                last_rendered[idx] = current_text
                goto continue
            end
        end

        local template = templates[idx]
        if type(template) ~= "string" then
            templates[idx] = current_text
            template = templates[idx]
        end

        if not has_placeholder(template) then
            templates[idx] = nil
            last_rendered[idx] = current_text
            goto continue
        end

        local default_sig = pick_panel_default_signal(message, template)
        local default_sigkey = default_sig and make_sigkey(default_sig) or nil

        local rendered = render_template(template, unit, idx, sigmap, default_sigkey)

        if message.text ~= rendered then
            message.text = rendered
            changed_any = true
        end

        last_rendered[idx] = rendered
        ::continue::
    end

    if changed_any then
        pcall(function() behavior.messages = messages end)
    end
end

--------------------------------------------------
-- UPDATE: PROGRAMMABLE SPEAKER
--------------------------------------------------

local function update_speaker(entity)
    if not (entity and entity.valid) then return end
    if entity.type ~= "programmable-speaker" then return end

    local behavior = entity.get_or_create_control_behavior()
    if not behavior then return end

    local ok_ap, ap = pcall(function() return entity.alert_parameters end)
    if not ok_ap or type(ap) ~= "table" then return end

    local current_text = ap.alert_message
    if current_text == nil or type(current_text) ~= "string" then return end

    local grace = grace_store("_sigd_speaker_edit_grace")

    local unit = entity.unit_number

    storage.speaker_templates = storage.speaker_templates or {}
    storage._sigd_speaker_last_rendered = storage._sigd_speaker_last_rendered or {}

    local template = storage.speaker_templates[unit]
    local lr = storage._sigd_speaker_last_rendered[unit]

    -- detect user edit and adopt template (with grace window)
    if lr ~= nil and current_text ~= lr then
        start_grace(grace, unit, 1)
        if has_placeholder(current_text) then
            storage.speaker_templates[unit] = current_text
            template = current_text
        else
            storage.speaker_templates[unit] = nil
            template = nil
        end
        storage._sigd_speaker_last_rendered[unit] = current_text
        return
    end

    if in_grace(grace, unit, 1) then
        storage._sigd_speaker_last_rendered[unit] = current_text
        return
    end

    if template == nil then
        if has_placeholder(current_text) then
            storage.speaker_templates[unit] = current_text
            template = current_text
        else
            storage._sigd_speaker_last_rendered[unit] = current_text
            return
        end
    end

    if type(template) ~= "string" then
        storage.speaker_templates[unit] = current_text
        template = current_text
    end

    if not has_placeholder(template) then
        storage.speaker_templates[unit] = nil
        storage._sigd_speaker_last_rendered[unit] = current_text
        return
    end

    local sigmap = build_signal_map_single_source(entity, behavior)

    local sig_def = pick_speaker_signal_def(entity, behavior)
    local default_sigkey = sig_def and make_sigkey(sig_def) or nil

    local rendered = render_template(template, unit, 1, sigmap, default_sigkey)

    if ap.alert_message ~= rendered then
        ap.alert_message = rendered
        pcall(function() entity.alert_parameters = ap end)
    end

    storage._sigd_speaker_last_rendered[unit] = rendered
end

--------------------------------------------------
-- PUBLIC ENTRY POINT
--------------------------------------------------

function display.update_display(entity)
    if not (entity and entity.valid) then return end
    if entity.type == "display-panel" then
        return update_display_panel(entity)
    elseif entity.type == "programmable-speaker" then
        return update_speaker(entity)
    end
end

return display