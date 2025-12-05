---@class Core.Resource.TTF
local M = {}
Core.Resource.TTF = M
M.__index = M
M.__type = "TTF"

---@type Core.Resource.TTF[]
M.res = {}

function M.New(name, path, size)
    ---@type Core.Resource.TTF
    local self = setmetatable({}, M)
    self.name = name
    self.path = path
    self.size = size
    lstg.LoadTTF(name, path, 0, size)
    self.res_pool = Core.Resource.GetResourcePool()
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end
function M.Remove(name)
    if M.res[name] then
        lstg.RemoveResource(M.res[name].res_pool, Core.Resource.ResType.TTF, name)
        M.res[name] = nil
    end
end
function M:unload()
    M.Remove(self.name)
end
function M:getSize()
    return self.size
end