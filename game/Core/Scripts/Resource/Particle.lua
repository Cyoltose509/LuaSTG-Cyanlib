---@class Core.Resource.Particle
local M = {}
Core.Resource.Particle = M
M.__index = M
M.__type = "Particle"

---@type Core.Resource.Particle[]
M.res = {}

---@param name string
---@param path string
---@param sprite Core.Resource.Image|string
---@param a number?
---@param b number?
---@param rect boolean?
function M.New(name, path, sprite, a, b, rect)
    if type(sprite) == "string" then
        sprite = Core.Resource.Image.Get(sprite)
    end
    assert(sprite and sprite.__type == "Image", "Invalid sprite.")
    ---@type Core.Resource.Particle
    local self = setmetatable({}, M)
    self.name = name
    self.path = path
    self.sprite = sprite
    self.a = a or 0
    self.b = b or 0
    self.rect = rect or false
    lstg.LoadPS(path, name, sprite.name, a, b, rect)
    self.res_pool = Core.Resource.GetResourcePool()
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end
function M.Remove(name)
    if M.res[name] then
        lstg.RemoveResource(M.res[name].res_pool, Core.Resource.ResType.Particle, name)
        M.res[name] = nil
    end
end
function M.Clear()
    for name in pairs(M.res) do
        M.Remove(name)
    end
end
function M:unload()
    M.Remove(self.name)
end