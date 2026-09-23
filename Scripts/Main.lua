-- Xaou Multi Pet Probe v0.10
-- Observes LingShouMgr when a pet statue is activated.
-- v0.10 restores the previous pet shortly after a switch without waiting for the new pet's Key, which stays 0 on Android.
-- Experimental Multi Pet test: uses the game's own running-pet API; no direct HashSet writes.

local mod = GameMain:NewMod("XaouMultiPetProbe")

local PREFIX = "[XaouMultiPetProbe] "
local MAX_COLLECTION_ITEMS = 32
local dumpedStructure = false
local logFilePath = nil
local logFileReady = false
local WATCH_INTERVAL = 0.5
local watchElapsed = 0
local watchSnapshot = nil
local lastMainNpc = nil
local MULTIPET_EXPERIMENT = true
local pendingPreviousNpc = nil
local pendingNewNpc = nil
local pendingRestoreElapsed = 0
local PENDING_RESTORE_TIMEOUT = 8.0
local RESTORE_DELAY = 1.0

local WATCH_FIELDS = {
    ["runningLss"] = true,
    ["SortedRunningLss"] = true,
    ["<runningLs>k__BackingField"] = true,
    ["waitSwitchNpc"] = true,
    ["<waitBornNpc>k__BackingField"] = true,
    ["bd2Npc"] = true,
    ["raceLs"] = true,
    ["LsNpcs"] = true,
    ["lsData"] = true,
    ["raceLsData"] = true,
    ["CLAER_T_IF_CHANGE_BUILD"] = true,
    ["ForceStepImmediately"] = true,
}

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
                "Xaou Multi Pet Probe v0.10\r\n"
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

    -- On the Android build used for testing, WriteAllText works while
    -- AppendAllText may fail through the Lua/C# binding. Read + rewrite
    -- is slower but reliable for this small diagnostic log.
    pcall(function()
        local IO = CS.System.IO
        local current = ""
        if IO.File.Exists(path) then
            current = tostring(IO.File.ReadAllText(path))
        end
        IO.File.WriteAllText(path, current .. line .. "\r\n")
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

local function method_signature(m)
    local parts = {}
    local okParams, params = pcall(function() return m:GetParameters() end)
    if okParams and params ~= nil then
        for i = 0, params.Length - 1 do
            local p = params[i]
            local pt = "?"
            local pn = "?"
            pcall(function() pt = safe_tostring(p.ParameterType) end)
            pcall(function() pn = safe_tostring(p.Name) end)
            parts[#parts + 1] = pt .. " " .. pn
        end
    end

    local rt = "?"
    pcall(function() rt = safe_tostring(m.ReturnType) end)
    return safe_tostring(m.Name) .. "(" .. table.concat(parts, ", ") .. ") -> " .. rt
end

local function dump_runtime_type(label, value)
    if value == nil then
        log("RUNTIME " .. label .. " = <nil>")
        return
    end

    local okType, t = pcall(function() return value:GetType() end)
    if not okType or t == nil then
        log("RUNTIME " .. label .. " type unavailable")
        return
    end

    log("=== RUNTIME TYPE " .. label .. " :: " .. safe_tostring(t.FullName) .. " ===")

    local flags = get_flags()

    local okFields, fields
    if flags ~= nil then
        okFields, fields = pcall(function() return t:GetFields(flags) end)
    else
        okFields, fields = pcall(function() return t:GetFields() end)
    end

    if okFields and fields ~= nil then
        for i = 0, fields.Length - 1 do
            local f = fields[i]
            local fv = "<unread>"
            pcall(function() fv = snapshot_value(f:GetValue(value)) end)
            log("RUNTIME FIELD " .. safe_tostring(f.Name) .. " :: " .. safe_tostring(f.FieldType) .. " = " .. fv)
        end
    end

    local okProps, props
    if flags ~= nil then
        okProps, props = pcall(function() return t:GetProperties(flags) end)
    else
        okProps, props = pcall(function() return t:GetProperties() end)
    end

    if okProps and props ~= nil then
        for i = 0, props.Length - 1 do
            local p = props[i]
            local pv = "<unread>"
            if p:GetIndexParameters().Length == 0 then
                pcall(function() pv = snapshot_value(p:GetValue(value, nil)) end)
            end
            log("RUNTIME PROP " .. safe_tostring(p.Name) .. " :: " .. safe_tostring(p.PropertyType) .. " = " .. pv)
        end
    end

    local okMethods, methods
    if flags ~= nil then
        okMethods, methods = pcall(function() return t:GetMethods(flags) end)
    else
        okMethods, methods = pcall(function() return t:GetMethods() end)
    end

    if okMethods and methods ~= nil then
        local seen = {}
        for i = 0, methods.Length - 1 do
            local m = methods[i]
            local n = string.lower(safe_tostring(m.Name))
            if string.find(n, "add", 1, true)
                or string.find(n, "remove", 1, true)
                or string.find(n, "clear", 1, true)
                or string.find(n, "count", 1, true)
                or string.find(n, "contains", 1, true)
                or string.find(n, "get", 1, true)
                or string.find(n, "set", 1, true)
                or string.find(n, "sort", 1, true)
                or string.find(n, "enum", 1, true) then
                local sig = method_signature(m)
                if not seen[sig] then
                    seen[sig] = true
                    log("RUNTIME METHOD " .. sig)
                end
            end
        end
    end

    log("=== RUNTIME TYPE END " .. label .. " ===")
end

local function dump_lingshou_method_signatures()
    local t = get_type()
    if t == nil then return end

    local flags = get_flags()
    local ok, methods
    if flags ~= nil then
        ok, methods = pcall(function() return t:GetMethods(flags) end)
    else
        ok, methods = pcall(function() return t:GetMethods() end)
    end
    if not ok or methods == nil then return end

    log("=== LingShouMgr relevant method signatures ===")
    local seen = {}
    for i = 0, methods.Length - 1 do
        local m = methods[i]
        local n = string.lower(safe_tostring(m.Name))
        if string.find(n, "run", 1, true)
            or string.find(n, "active", 1, true)
            or string.find(n, "switch", 1, true)
            or string.find(n, "born", 1, true)
            or string.find(n, "stone", 1, true)
            or string.find(n, "build", 1, true)
            or string.find(n, "remove", 1, true) then
            local sig = method_signature(m)
            if not seen[sig] then
                seen[sig] = true
                log("SIG " .. sig)
            end
        end
    end
    log("=== LingShouMgr relevant signatures end ===")
end

local function dump_active_container_api()
    local inst = get_instance()
    if inst == nil then
        log("ERROR: cannot inspect active container; LingShouMgr.Instance is nil")
        return
    end

    local t = get_type()
    local flags = get_flags()
    local fields = nil
    pcall(function()
        if flags ~= nil then fields = t:GetFields(flags) else fields = t:GetFields() end
    end)
    if fields == nil then return end

    for i = 0, fields.Length - 1 do
        local f = fields[i]
        local name = safe_tostring(f.Name)
        if name == "runningLss"
            or name == "SortedRunningLss"
            or name == "<runningLs>k__BackingField"
            or name == "waitSwitchNpc"
            or name == "<waitBornNpc>k__BackingField" then
            local okValue, value = pcall(function() return f:GetValue(inst) end)
            if okValue then
                dump_runtime_type(name, value)
            end
        end
    end

    dump_lingshou_method_signatures()
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

local function get_field_value(fieldName)
    local inst = get_instance()
    local fields = get_fields()
    if inst == nil or fields == nil then return nil end

    for i = 0, fields.Length - 1 do
        local f = fields[i]
        if safe_tostring(f.Name) == fieldName then
            local ok, value = pcall(function() return f:GetValue(inst) end)
            if ok then return value end
            return nil
        end
    end
    return nil
end

local function get_running_set()
    local hashList = get_field_value("runningLss")
    if hashList == nil then return nil end

    local okType, t = pcall(function() return hashList:GetType() end)
    if not okType or t == nil then return nil end

    local flags = get_flags()
    local okField, vf
    if flags ~= nil then
        okField, vf = pcall(function() return t:GetField("v", flags) end)
    else
        okField, vf = pcall(function() return t:GetField("v") end)
    end
    if not okField or vf == nil then return nil end

    local okValue, set = pcall(function() return vf:GetValue(hashList) end)
    if okValue then return set end
    return nil
end

local function running_count()
    local set = get_running_set()
    if set == nil then return -1 end
    local ok, count = pcall(function() return tonumber(set.Count) end)
    if ok and count ~= nil then return count end
    return -1
end

local function running_contains(npc)
    if npc == nil then return false end
    local set = get_running_set()
    if set == nil then return false end

    local ok, yes = pcall(function() return set:Contains(npc) end)
    return ok and yes == true
end

local function get_main_running()
    local mgr = get_instance()
    if mgr == nil then return nil end

    local ok, npc = pcall(function() return mgr.runningLs end)
    if ok then return npc end

    return get_field_value("<runningLs>k__BackingField")
end

local function npc_id(npc)
    if npc == nil then return "<nil>" end
    local id = safe_member(npc, "ID")
    if id == nil then id = safe_member(npc, "Id") end
    if id == nil then id = safe_member(npc, "id") end
    return safe_tostring(id)
end

local function find_mgr_method(methodName, paramCount)
    local t = get_type()
    if t == nil then return nil end

    local flags = get_flags()
    local ok, methods
    if flags ~= nil then
        ok, methods = pcall(function() return t:GetMethods(flags) end)
    else
        ok, methods = pcall(function() return t:GetMethods() end)
    end
    if not ok or methods == nil then return nil end

    for i = 0, methods.Length - 1 do
        local m = methods[i]
        if safe_tostring(m.Name) == methodName then
            local okp, params = pcall(function() return m:GetParameters() end)
            if okp and params ~= nil and params.Length == paramCount then
                return m
            end
        end
    end
    return nil
end

local function invoke_mgr_method(methodName, args)
    local mgr = get_instance()
    if mgr == nil then
        return false, nil, "LingShouMgr.Instance is nil"
    end

    args = args or {}
    local m = find_mgr_method(methodName, #args)
    if m == nil then
        return false, nil, "method not found: " .. methodName .. "/" .. tostring(#args)
    end

    local ok, result = pcall(function()
        local arr = CS.System.Array.CreateInstance(typeof(CS.System.Object), #args)
        for i = 1, #args do
            arr:SetValue(args[i], i - 1)
        end
        return m:Invoke(mgr, arr)
    end)

    if ok then
        return true, result, nil
    end
    return false, nil, safe_tostring(result)
end

local function npc_key(npc)
    if npc == nil then return 0 end
    local k = safe_member(npc, "Key")
    if k == nil then k = safe_member(npc, "key") end
    return tonumber(k) or 0
end

local function schedule_previous_restore(previousNpc, newNpc)
    pendingPreviousNpc = previousNpc
    pendingNewNpc = newNpc
    pendingRestoreElapsed = 0

    log("=== MULTIPET switch detected; restore scheduled ===")
    log("  previous = " .. object_identity(previousNpc))
    log("  new      = " .. object_identity(newNpc))
    log("  previous key = " .. tostring(npc_key(previousNpc)))
    log("  new key      = " .. tostring(npc_key(newNpc)))
    log("  restoring previous pet after short switch delay; Android keeps selected new pet Key=0")
end

local function clear_pending_restore()
    pendingPreviousNpc = nil
    pendingNewNpc = nil
    pendingRestoreElapsed = 0
end

local function process_pending_restore()
    if not MULTIPET_EXPERIMENT then return end
    if pendingPreviousNpc == nil or pendingNewNpc == nil then return end

    pendingRestoreElapsed = pendingRestoreElapsed + WATCH_INTERVAL

    if pendingRestoreElapsed < RESTORE_DELAY then
        return
    end

    local previous = pendingPreviousNpc
    local newNpc = pendingNewNpc

    log("=== MULTIPET restore begin ===")
    log("  previous = " .. object_identity(previous))
    log("  new      = " .. object_identity(newNpc))
    log("  running count before = " .. tostring(running_count()))

    if npc_key(previous) <= 0 then
        local okFind, stoneData, findErr = invoke_mgr_method("FindStoneData", { previous })
        if not okFind or stoneData == nil then
            if pendingRestoreElapsed >= PENDING_RESTORE_TIMEOUT then
                log("MULTIPET ERROR FindStoneData timeout: " .. safe_tostring(findErr))
                clear_pending_restore()
            else
                log("MULTIPET FindStoneData not ready yet; retrying")
            end
            return
        end

        log("MULTIPET FindStoneData OK: " .. object_identity(stoneData))

        local okReborn, _, rebornErr = invoke_mgr_method("RebornFromStone", { stoneData })
        if not okReborn then
            log("MULTIPET ERROR RebornFromStone: " .. safe_tostring(rebornErr))
            clear_pending_restore()
            return
        end

        log("MULTIPET RebornFromStone(previous) OK; key now=" .. tostring(npc_key(previous)))
    else
        log("MULTIPET previous pet is still on map; RebornFromStone not needed")
    end

    if not running_contains(previous) then
        local okAdd, _, addErr = invoke_mgr_method("AddNpc2Running", { previous, false })
        if okAdd then
            log("MULTIPET reflection AddNpc2Running(previous, false) OK; npcID=" .. npc_id(previous))
        else
            log("MULTIPET ERROR reflection AddNpc2Running: " .. safe_tostring(addErr))
        end
    else
        log("MULTIPET previous pet already exists in runningLss")
    end

    -- RebornFromStone can change the manager's main pet. Put the newly selected
    -- pet back as main while keeping the previous one in runningLss.
    local okMain, _, mainErr = invoke_mgr_method("set_runningLs", { newNpc })
    if okMain then
        log("MULTIPET main pet restored to newly selected npcID=" .. npc_id(newNpc))
    else
        log("MULTIPET WARN set_runningLs failed: " .. safe_tostring(mainErr))
    end

    log("  previous key after = " .. tostring(npc_key(previous)))
    log("  new key after      = " .. tostring(npc_key(newNpc)))
    log("  running count after = " .. tostring(running_count()))
    log("  previous running    = " .. tostring(running_contains(previous)))
    log("  new running         = " .. tostring(running_contains(newNpc)))

    local sorted = get_field_value("SortedRunningLss")
    if sorted ~= nil then
        log("  SortedRunningLss after = " .. snapshot_value(sorted))
    end

    log("=== MULTIPET restore end ===")
    clear_pending_restore()
end

local function multi_pet_step()
    if not MULTIPET_EXPERIMENT then return end

    local current = get_main_running()
    if current ~= nil then
        if lastMainNpc == nil then
            lastMainNpc = current
            log("MULTIPET main initialized: " .. object_identity(current))
        elseif current ~= lastMainNpc and pendingPreviousNpc == nil then
            local previous = lastMainNpc
            lastMainNpc = current
            schedule_previous_restore(previous, current)
        end
    end

    process_pending_restore()
end

local function snapshot_watch_fields()
    local values = {}
    local inst = get_instance()
    local fields = get_fields()
    if inst == nil or fields == nil then return values end

    for i = 0, fields.Length - 1 do
        local f = fields[i]
        local name = safe_tostring(f.Name)
        if WATCH_FIELDS[name] then
            local ok, value = pcall(function() return f:GetValue(inst) end)
            if ok then
                values[name] = snapshot_value(value)
            else
                values[name] = "<read-error>"
            end
        end
    end

    return values
end

local function log_watch_snapshot(prefix, snap)
    local names = {
        "runningLss",
        "SortedRunningLss",
        "<runningLs>k__BackingField",
        "waitSwitchNpc",
        "<waitBornNpc>k__BackingField",
        "bd2Npc",
        "raceLs",
        "LsNpcs",
        "lsData",
        "raceLsData",
        "CLAER_T_IF_CHANGE_BUILD",
        "ForceStepImmediately",
    }

    log(prefix)
    for _, name in ipairs(names) do
        if snap[name] ~= nil then
            log("  " .. name .. " = " .. safe_tostring(snap[name]))
        end
    end
end

local function poll_active_pet_watch()
    local now = snapshot_watch_fields()

    if watchSnapshot == nil then
        watchSnapshot = now
        log_watch_snapshot("=== WATCH INITIAL active-pet state ===", now)
        return
    end

    local changed = false
    for name, oldv in pairs(watchSnapshot) do
        local newv = now[name]
        if newv ~= oldv then
            if not changed then
                log("=== WATCH CHANGE detected ===")
                changed = true
            end
            log("WATCH CHANGED " .. name)
            log("  BEFORE: " .. safe_tostring(oldv))
            log("  AFTER : " .. safe_tostring(newv))
        end
    end

    for name, newv in pairs(now) do
        if watchSnapshot[name] == nil then
            if not changed then
                log("=== WATCH CHANGE detected ===")
                changed = true
            end
            log("WATCH ADDED " .. name .. " = " .. safe_tostring(newv))
        end
    end

    if changed then
        log("=== WATCH CHANGE end ===")
    end

    watchSnapshot = now
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
    log("v0.10 loaded")
    if logFilePath ~= nil then
        log("Writing probe output to: " .. tostring(logFilePath))
    else
        log("WARN: file logging unavailable; console logging will still work")
    end
end

function mod:OnAfterLoad()
    log("save/map loaded; v0.10 direct active-pet watch + immediate stone restore enabled")
    dump_structure_once()
    dump_active_container_api()
    watchSnapshot = nil
    watchElapsed = 0
    lastMainNpc = nil
    clear_pending_restore()
    poll_active_pet_watch()
    multi_pet_step()
end

function mod:OnStep(dt)
    local n = tonumber(dt) or 0
    watchElapsed = watchElapsed + n
    if watchElapsed < WATCH_INTERVAL then return end
    watchElapsed = 0

    local ok, err = pcall(function()
        poll_active_pet_watch()
        multi_pet_step()
    end)
    if not ok then
        log("WATCH/MULTIPET ERROR: " .. safe_tostring(err))
    end
end
