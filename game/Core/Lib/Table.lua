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

function M.Merge(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

function M.DeepMerge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k]) ~= "table" then
                t1[k] = {}
            end
            M.DeepMerge(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

function M.MergeIf(t1, t2)
    for k, v in pairs(t2) do
        if t1[k] == nil then
            t1[k] = v
        end
    end
    return t1

end

function M.DeepMergeIf(t1, t2)
    for k, v in pairs(t2) do
        local v1 = t1[k]
        if v1 == nil then
            if type(v) == "table" then
                t1[k] = M.DeepMergeIf({}, v)
            else
                t1[k] = v
            end
        elseif type(v1) == "table" and type(v) == "table" then
            M.DeepMergeIf(v1, v)
        end
    end
    return t1
end

---@generic T
---@param t1 T[]
---@param t2 T[]
---@return T[]
function M.Concat(t1, t2)
    local j = #t1 + 1
    for i = 1, #t2 do
        t1[j] = t2[i]
        j = j + 1
    end
    return t1
end