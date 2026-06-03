---@class Core.Lib.YAML
local M = {}
Core.Lib.YAML = M

---@param t any
---@param indent number
---@param seen table
---@param depth number
---@return string
function M.Encode(t, indent, seen, depth)
    indent = indent or 0
    seen = seen or {}
    depth = depth or 0
    local pad = string.rep("  ", indent)
    local lines = {}

    local max_depth = 100 -- 防止太深递归

    local function is_array(tbl)
        local n = #tbl
        if n == 0 then
            return false
        end
        for k in pairs(tbl) do
            if type(k) ~= "number" then
                return false
            end
        end
        return true
    end

    local function serialize_value(v, ind)
        ind = ind or 0
        local ttype = type(v)

        if ttype == "table" then
            local mt = getmetatable(v)
            if mt and mt.__tostring then
                return '"' .. tostring(v) .. '"'
            end

            if seen[v] then
                return "<recursive>"
            end
            if depth >= max_depth then
                return "<too deep>"
            end

            seen[v] = true
            return M.Encode(v, indent + 1, seen, depth + 1)

        elseif ttype == "string" then
            return '"' .. v .. '"'
        elseif ttype == "boolean" then
            return v and "true" or "false"
        else
            return tostring(v)
        end
    end

    if type(t) ~= "table" then
        return serialize_value(t)
    end

    if is_array(t) then
        for _, v in ipairs(t) do
            if type(v) == "table" and not (getmetatable(v) and getmetatable(v).__tostring) then
                local encoded = M.Encode(v, indent + 1, seen, depth + 1)
                lines[#lines + 1] = pad .. "- " .. encoded:gsub("^%s+", "")
            else
                lines[#lines + 1] = pad .. "- " .. serialize_value(v)
            end
        end
    else
        for k, v in pairs(t) do
            if type(v) == "table" and not (getmetatable(v) and getmetatable(v).__tostring) then
                lines[#lines + 1] = pad .. tostring(k) .. ":\n" .. M.Encode(v, indent + 1, seen, depth + 1)
            else
                lines[#lines + 1] = pad .. tostring(k) .. ": " .. serialize_value(v)
            end
        end
    end

    return table.concat(lines, "\n")
end
