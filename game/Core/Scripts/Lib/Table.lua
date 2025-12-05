---@class Core.Lib.Table
local M = {}
Core.Lib.Table = M

---@generic T
---@param t T
---@return T
function M.Copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

---@generic T
---@param t T
---@return T
function M.DeepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = M.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return setmetatable(copy, getmetatable(t))
end

---@param list any[] @目标表
---@param n number @截取最大长度
---@param pos number @选择位标
---@param s number @锁定位标
---@return any[], number
function M.Section(list, n, pos, s)
    n = int(n or #list)
    s = clamp(int(s or n), 1, n)
    local cut, c, m = {}, #list, pos
    if c <= n then
        cut = list
    elseif pos < s then
        for i = 1, n do
            table.insert(cut, list[i])
        end
    else
        local t = clamp(pos + (n - s), pos, c)
        for i = t - n + 1, t do
            table.insert(cut, list[i])
        end
        m = clamp(n - (t - pos), s, n)
    end
    return cut, m
end

---@generic T
---@param t1 T[]
---@param t2 T[]
---@return T[]
function M.Merge(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

---@generic T
---@param t1 T[]
---@param t2 T[]
---@return T[]
function M.Concat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end