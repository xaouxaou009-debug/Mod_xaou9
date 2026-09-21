-- Xaou Multi Pet Probe v0.1
-- Purpose: observe LingShouMgr state changes when a pet statue is activated.
-- This version does NOT intentionally remove the one-active-pet limit.

local mod = GameMain:NewMod("XaouMultiPetProbe")

local PREFIX = "[XaouMultiPetProbe] "
local dumpedStructure = false

local function log(msg)
    print(PREFIX .. tostring(msg))
end

local function safe_tostring(v)
    if v == nil then return "<nil>" end
    local ok, s = pcall(function() return tostring(v) end)
    if ok then return s end
    return "<unprintable>"
end

local function get_type()
    local ok, t = pcall(function()
        return typeof(CS.XiaWorld.LingShouMgr)
    end)
    if ok then return t end
    return nil
end

local function get_instance()
    local ok, inst = pcall(function()
        return CS.XiaWorld.LingShouMgr.Instance
    end)
    if ok then return inst end
    return nil
end

local function get_flags()
    local ok, flags = pcall(function()
        -- Instance(4) + Static(8) + Public(16) + NonPublic(32) = 60
        return CS.System.Enum.ToObject(typeof(CS.System.Reflection.BindingFlags), 60)
    end)
    if ok then return flags end
    return nil
end

local function get_fields()
    local t = get_type()
    if t == nil then return nil end

    local flags = get_flags()
    local ok, fields
    if flags ~= nil then
        ok, fields = pcall(function() return t:GetFields(flags) end)
    else
        ok, fields = pcall(function() return t:GetFields() end)
    end
    if ok then return fields end
    return nil
end

local function snapshot_fields()
    local values = {}
    local inst = get_instance()
    local fields = get_fields()
    if inst == nil or fields == nil then return values end

    for i = 0, fields.Length - 1 do
        local f = fields[i]
        local name = safe_tostring(f.Name)
        local ok, value = pcall(function() return f:GetValue(inst) end)
        if ok then
            values[name] = safe_tostring(value)
        else
            values[name] = "<read-error>"
        end
    end
    return values
end

local function dump_structure_once()
    if dumpedStructure then return end
    dumpedStructure = true

    local t = get_type()
    if t == nil then
        log("ERROR: typeof(CS.XiaWorld.LingShouMgr) unavailable")
        return
    end

    log("=== LingShouMgr structure dump begin ===")

    local fields = get_fields()
    if fields ~= nil then
        for i = 0, fields.Length - 1 do
            local f = fields[i]
            local ft = "?"
            pcall(function() ft = safe_tostring(f.FieldType) end)
            log("FIELD " .. safe_tostring(f.Name) .. " :: " .. ft)
        end
    else
        log("WARN: could not enumerate fields")
    end

    local flags = get_flags()
    local ok, methods
    if flags ~= nil then
        ok, methods = pcall(function() return t:GetMethods(flags) end)
    else
        ok, methods = pcall(function() return t:GetMethods() end)
    end

    if ok and methods ~= nil then
        for i = 0, methods.Length - 1 do
            local m = methods[i]
            local n = safe_tostring(m.Name)
            local low = string.lower(n)
            if string.find(low, "active", 1, true)
                or string.find(low, "ling", 1, true)
                or string.find(low, "pet", 1, true)
                or string.find(low, "build", 1, true)
                or string.find(low, "call", 1, true)
                or string.find(low, "remove", 1, true)
                or string.find(low, "leave", 1, true)
                or string.find(low, "save", 1, true)
                or string.find(low, "load", 1, true) then
                log("METHOD " .. n)
            end
        end
    else
        log("WARN: could not enumerate methods")
    end

    log("=== LingShouMgr structure dump end ===")
end

local function log_changes(before, after)
    local changed = 0

    for k, oldv in pairs(before) do
        local newv = after[k]
        if newv ~= oldv then
            changed = changed + 1
            log("CHANGED " .. k .. " : " .. oldv .. " -> " .. safe_tostring(newv))
        end
    end

    for k, newv in pairs(after) do
        if before[k] == nil then
            changed = changed + 1
            log("ADDED " .. k .. " : " .. safe_tostring(newv))
        end
    end

    if changed == 0 then
        log("No reflected LingShouMgr field changed (or private fields were not visible).")
    else
        log("Changed fields: " .. tostring(changed))
    end
end

function mod:ActivePetStatue(it)
    dump_structure_once()

    local mgr = get_instance()
    if mgr == nil then
        log("ERROR: LingShouMgr.Instance is nil")
        return
    end

    local statueName = "<unknown>"
    pcall(function()
        if it ~= nil and it.def ~= nil and it.def.Name ~= nil then
            statueName = tostring(it.def.Name)
        elseif it ~= nil and it.Def ~= nil and it.Def.Name ~= nil then
            statueName = tostring(it.Def.Name)
        end
    end)

    log("=== Activate pet statue: " .. statueName .. " ===")
    local before = snapshot_fields()

    local ok, err = pcall(function()
        mgr:ActiveLcBuild(it)
    end)

    if not ok then
        log("ERROR calling original ActiveLcBuild: " .. safe_tostring(err))
        return
    end

    local after = snapshot_fields()
    log_changes(before, after)
    log("=== Activation complete ===")
end

function mod:OnInit()
    log("v0.1 loaded")
end

function mod:OnAfterLoad()
    log("save/map loaded; waiting for pet statue activation")
    dump_structure_once()
end
