---@class Core.Lib.Json
local M = {}
Core.Lib.Json = M

function M.Format(str)
    local ret = ''
    local indent = '	'
    local level = 0
    local in_string = false
    for i = 1, #str do
        local s = string.sub(str, i, i)
        if s == '{' and (not in_string) then
            level = level + 1
            ret = ret .. '{\n' .. string.rep(indent, level)
        elseif s == '}' and (not in_string) then
            level = level - 1
            ret = string.format(
                    '%s\n%s}', ret, string.rep(indent, level))
        elseif s == '"' then
            in_string = not in_string
            ret = ret .. '"'
        elseif s == ':' and (not in_string) then
            ret = ret .. ': '
        elseif s == ',' and (not in_string) then
            ret = ret .. ',\n'
            ret = ret .. string.rep(indent, level)
        elseif s == '[' and (not in_string) then
            level = level + 1
            ret = ret .. '[\n' .. string.rep(indent, level)
        elseif s == ']' and (not in_string) then
            level = level - 1
            ret = string.format(
                    '%s\n%s]', ret, string.rep(indent, level))
        else
            ret = ret .. s
        end
    end
    return ret
end

local function print_value(t, indent, no_lead_indent)
    local T = type(t)
    if T == "table" then
        local n = 0
        local s = {}

        local i = string.rep("  ", indent)

        if not no_lead_indent then
            n = n + 1
            s[n] = i
        end

        n = n + 1
        s[n] = "{\n"

        local h = string.rep("  ", indent + 1)

        for k, v in pairs(t) do
            n = n + 1
            s[n] = h

            n = n + 1
            s[n] = "["

            n = n + 1
            s[n] = print_value(k, 0, true)

            n = n + 1
            s[n] = "] = "

            n = n + 1
            s[n] = print_value(v, indent + 1, true)

            n = n + 1
            s[n] = ","

            n = n + 1
            s[n] = "\n"
        end

        n = n + 1
        s[n] = i

        n = n + 1
        s[n] = "}"

        return table.concat(s)
    elseif T == "string" then
        return string.format("%q", t)
    elseif T == "number" or T == "boolean" then
        return tostring(t)
    else
        return string.format("%q", tostring(t))
    end
end

function M.Encode(t)
    local b, s = pcall(cjson.encode, t)
    if b then
        return s
    else
        lstg.Log(4, string.format("contant to encode = %s", print_value(t, 0, false)))
        assert(b, s)
    end
end
function M.Decode(s)
    local b, t = pcall(cjson.decode, s)
    if b then
        return t
    else
        lstg.Log(4, string.format("json contant %q", s))
        assert(b, t)
    end
end

function M.Serialize(t)
    return M.Format(M.Encode(t))
end