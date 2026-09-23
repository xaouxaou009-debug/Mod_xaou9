-- Xaou Multi Pet Probe v0.4
-- Observes LingShouMgr when a pet statue is activated.
-- v0.4 prioritizes Android/Unity writable storage, with desktop paths only as fallback.
-- This probe does NOT intentionally remove the one-active-pet limit.

local mod = GameMain:NewMod("XaouMultiPetProbe")

local PREFIX = "[XaouMultiPetProbe] "
local MAX_COLLECTION_ITEMS = 32
local dumpedStructure = false
local logFilePath = nil
local logFileReady = false

local function safe_tostring(v)
    if v == nil then return "<nil>" end
    local ok, s = pcall(function() return tostring(v) end)
    if ok then return s end
    return "<unprintable>"
end

local function timestamp()
    local ok, value = pcall(function()
        return CS.System.DateTime.Now:ToString("yyyy-MM-dd HH:mm:ss.fff")
    end)
    if ok then return tostring(value) end
    return "time?"
end

local function info_matches_mod(dir)
    local ok, matched = pcall(function()
        local IO = CS.System.IO
        local infoPath = IO.Path.Combine(dir, "Info.json")
        if not IO.File.Exists(infoPath) then return false end

        local info = IO.File.ReadAllText(infoPath)
        return info ~= nil
            and string.find(tostring(info), "\"Name\"", 1, true) ~= nil
            and string.find(tostring(info), "XaouMultiPetProbe", 1, true) ~= nil
    end)

    return ok and matched == true
end

local function find_matching_child(root)
    local ok, result = pcall(function()
        local IO = CS.System.IO
        if root == nil or not IO.Directory.Exists(root) then return nil end

        local dirs = IO.Directory.GetDirectories(root)
        for i = 0, dirs.Length - 1 do
            if info_matches_mod(dirs[i]) then
                return dirs[i]
            end
        end
        return nil
    end)

    if ok then return result end
    return nil
end

local function get_log_candidates()
    local result = {}

    pcall(function()
        local IO = CS.System.IO

        -- Mobile/Android first: Unity guarantees this is the app's writable data folder.
        local persistent = CS.UnityEngine.Application.persistentDataPath
        if persistent ~= nil and tostring(persistent) ~= "" then
            result[#result + 1] = tostring(persistent)
        end

        -- Secondary writable Unity location.
        local cache = CS.UnityEngine.Application.temporaryCachePath
        if cache ~= nil and tostring(cache) ~= "" then
            result[#result + 1] = tostring(cache)
        end

        -- Desktop/local-mod fallbacks are kept so the same probe still works on PC.
        local gameRoot = IO.Path.GetDirectoryName(CS.UnityEngine.Application.dataPath)
        local modsRoot = IO.Path.Combine(gameRoot, "Mods")

        local localMod = find_matching_child(modsRoot)
        if localMod ~= nil then
            result[#result + 1] = localMod
        end

        if IO.Directory.Exists(modsRoot) then
            result[#result + 1] = modsRoot
        end

        result[#result + 1] = gameRoot
    end)

    return result
end

local function ensure_log_file()
    if logFileReady then return logFilePath end
    logFileReady = true

    local candidates = get_log_candidates()
    for _, dir in ipairs(candidates) do
        local ok, path = pcall(function()
            local IO = CS.System.IO
            if dir == nil or not IO.Directory.Exists(dir) then return nil end

            local p = IO.Path.Combine(dir, "XaouMultiPetProbe.log")
            IO.File.WriteAllText(
                p,
                "Xaou Multi Pet Probe v0.4\r\n"
                .. "Started: " .. timestamp() .. "\r\n"
                .. "LogPath: " .. tostring(p) .. "\r\n"
                .. "PersistentDataPath: " .. safe_tostring(CS.UnityEngine.Application.persistentDataPath) .. "\r\n"
                .. "DataPath: " .. safe_tostring(CS.UnityEngine.Application.dataPath) .. "\r\n"
                .. "============================================================\r\n"
            )
            return p
        end)

        if ok and path ~= nil then
            logFilePath = path
            return logFilePath
        end
    end

    return nil
end

local function append_log_line(line)
    local path = ensure_log_file()
    if path == nil then return end

    pcall(function()
        CS.System.IO.File.AppendAllText(path, line .. "\r\n")
    end)
end

local function log(msg)
    local line = PREFIX .. "[" .. timestamp() .. "] " .. safe_tostring(msg)
    print(line)
    append_log_line(line)
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

local function runtime_type_name(v)
    if v == nil then return "<nil>" end

    local ok, name = pcall(function()
        local t = v:GetType()
        if t.FullName ~= nil then return tostring(t.FullName) end
        return tostring(t)
    end)

    if ok and name ~= nil then return name end
    return type(v)
end

local function safe_member(v, memberName)
    if v == nil then return nil end
    local ok, value = pcall(function() return v[memberName] end)
    if ok then return value end
    return nil
end

local function object_identity(v)
    if v == nil then return "<nil>" end

    local vt = type(v)
    if vt == "string" or vt == "number" or vt == "boolean" then
        return safe_tostring(v)
    end

    local pieces = {}
    local names = {
        "ID", "Id", "id",
        "Name", "name",
        "Key", "key",
        "ThingID", "ThingId", "thingID", "thingId",
        "UID", "Uid", "uid"
    }

    for _, memberName in ipairs(names) do
        local value = safe_member(v, memberName)
        if value ~= nil then
            pieces[#pieces + 1] = memberName .. "=" .. safe_tostring(value)
        end
    end

    local def = safe_member(v, "def")
    if def == nil then def = safe_member(v, "Def") end
    if def ~= nil then
        local defName = safe_member(def, "Name")
        if defName ~= nil then
            pieces[#pieces + 1] = "Def.Name=" .. safe_tostring(defName)
        end
    end

    if #pieces > 0 then
        return runtime_type_name(v) .. "{" .. table.concat(pieces, ",") .. "}"
    end

    return runtime_type_name(v) .. "{" .. safe_tostring(v) .. "}"
end

local function collection_count(v)
    if v == nil then return nil end

    local ok, count = pcall(function() return v.Count end)
    if ok and count ~= nil then
        local n = tonumber(count)
        if n ~= nil then return n end
    end

    ok, count = pcall(function() return v.Length end)
    if ok and count ~= nil then
        local n = tonumber(count)
        if n ~= nil then return n end
    end

    return nil
end

local function describe_collection_item(item)
    if item == nil then return "<nil>" end

    local key = safe_member(item, "Key")
    local value = safe_member(item, "Value")
    if key ~= nil or value ~= nil then
        return "[" .. object_identity(key) .. "]=" .. object_identity(value)
    end

    return object_identity(item)
end

local function snapshot_collection(v, count)
    local parts = {
        "type=" .. runtime_type_name(v),
        "count=" .. tostring(count)
    }

    local okEnum, enum = pcall(function() return v:GetEnumerator() end)
    if not okEnum or enum == nil then
        parts[#parts + 1] = "value=" .. safe_tostring(v)
        return table.concat(parts, "|")
    end

    local i = 0
    while i < MAX_COLLECTION_ITEMS do
        local okMove, hasNext = pcall(function() return enum:MoveNext() end)
        if not okMove or not hasNext then break end

        local okCurrent, current = pcall(function() return enum.Current end)
        if not okCurrent then
            parts[#parts + 1] = "<current-read-error>"
            break
        end

        parts[#parts + 1] = tostring(i) .. ":" .. describe_collection_item(current)
        i = i + 1
    end

    if count > MAX_COLLECTION_ITEMS then
        parts[#parts + 1] = "...+" .. tostring(count - MAX_COLLECTION_ITEMS)
    end

    return table.concat(parts, "|")
end

local function snapshot_value(v)
    if v == nil then return "<nil>" end

    local count = collection_count(v)
    if count ~= nil then
        local ok, result = pcall(function()
            return snapshot_collection(v, count)
        end)
        if ok then return result end
    end

    return object_identity(v)
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
            values[name] = snapshot_value(value)
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
            log("CHANGED " .. k)
            log("  BEFORE: " .. safe_tostring(oldv))
            log("  AFTER : " .. safe_tostring(newv))
        end
    end

    for k, newv in pairs(after) do
        if before[k] == nil then
            changed = changed + 1
            log("ADDED " .. k .. " : " .. safe_tostring(newv))
        end
    end

    if changed == 0 then
        log("No reflected LingShouMgr field/collection content changed.")
    else
        log("Changed fields/collections: " .. tostring(changed))
    end
end

local function get_statue_name(it)
    local statueName = "<unknown>"
    pcall(function()
        if it ~= nil and it.def ~= nil and it.def.Name ~= nil then
            statueName = tostring(it.def.Name)
        elseif it ~= nil and it.Def ~= nil and it.Def.Name ~= nil then
            statueName = tostring(it.Def.Name)
        end
    end)
    return statueName
end

function mod:ActivePetStatue(it)
    dump_structure_once()

    local mgr = get_instance()
    if mgr == nil then
        log("ERROR: LingShouMgr.Instance is nil")
        return
    end

    log("=== Activate pet statue: " .. get_statue_name(it) .. " ===")
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
    ensure_log_file()
    log("v0.4 loaded")
    if logFilePath ~= nil then
        log("Writing probe output to: " .. tostring(logFilePath))
    else
        log("WARN: file logging unavailable; console logging will still work")
    end
end

function mod:OnAfterLoad()
    log("save/map loaded; waiting for pet statue activation")
    dump_structure_once()
end
