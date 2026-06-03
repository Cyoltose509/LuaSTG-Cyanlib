---@class Core.Data.Config
local M = {}
Core.Data.Config = M

local config_list = {}

function M.Get()
    return config_list
end

local function parseValue(v)
    if v == "true" then
        return true
    elseif v == "false" then
        return false
    end

    local n = tonumber(v)
    if n then
        return n
    end

    return v
end

function M.Save()
    local configfile_dir = Core.Data.GetPath()
    local configfile = configfile_dir .. "/config.ini"
    Core.VFS.CreateDirectory(configfile_dir)
    local f = assert(io.open(configfile, 'w'))
    local lines = {}
    for k, v in pairs(config_list) do
        table.insert(lines, k .. "=" .. tostring(v))
    end
    f:write(table.concat(lines, "\n"))
    f:close()
end

function M.Load()
    local f, msg
    local configfile_dir = Core.Data.GetPath()
    local configfile = configfile_dir .. "/config.ini"
    f, msg = io.open(configfile, 'r')
    if f then
        for line in f:lines() do
            local key, value = line:match("^([^=]+)=(.+)$")
            if key and value then
                config_list[key] = parseValue(value)
            end
        end
        f:close()
    end
end

---设置值
---@param key string
function M.SetValue(key, value)
    local obj = config_list
    obj[key] = value
end

---获取值
---@param key string
---@param default any
function M.GetValue(key, default)
    local obj = config_list
    obj[key] = obj[key] or default
    return obj[key]
end
