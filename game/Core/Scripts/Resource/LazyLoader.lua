---@class Core.Resource.LazyLoader
local M = {}
Core.Resource.LazyLoader = M

M.ptr = 1
M.Queue = {}

function M.GetLeft()
    return #M.Queue - M.ptr + 1
end

function M.Add(func)
    table.insert(M.Queue, func)
end
function M.Do()
    if M.ptr > #M.Queue then
        return false
    end
    M.Queue[M.ptr]()
    M.ptr = M.ptr + 1
    return true
end

function M.DoAll()
    for _, func in ipairs(M.Queue) do
        func()
    end
    M.Clear()
end

function M.Clear()
    M.Queue = {}
    M.ptr = 1
end

function M.EnumFliesWithFunction(path, extend, func, prefix, suffix)
    prefix = prefix or ""
    suffix = suffix or ""
    for _, v in ipairs(Core.VFS.EnumFiles(path, extend, true)) do
        local name = v[1]:sub(#path + 1, -5)
        name = prefix .. name .. suffix
        M.Add(function()
            func(name, v[1])
        end)
    end

end