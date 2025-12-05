---@class Core.Resource.Model
local M = {}
Core.Resource.Model = M
M.__index = M
M.__type = "Model"

---@type Core.Resource.Model[]
M.res = {}

function M.New(name, path)
    ---@type Core.Resource.Model
    local self = setmetatable({}, M)
    self.name = name
    self.path = path
    self.x = 0
    self.y = 0
    self.z = 0
    self.roll = 0
    self.pitch = 0
    self.yaw = 0
    self.scaleX = 1
    self.scaleY = 1
    self.scaleZ = 1
    lstg.LoadModel(name, path)
    self.res_pool = Core.Resource.GetResourcePool()
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end
function M.Remove(name)
    if M.res[name] then
        lstg.RemoveResource(M.res[name].res_pool, Core.Resource.ResType.Model, name)
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
function M:getSize()
    return self.size
end
function M:setPosition(x, y, z)
    self.x = x or self.x
    self.y = y or self.y
    self.z = z or self.z
    return self
end
function M:setRotation(roll, pitch, yaw)
    self.roll = roll or self.roll
    self.pitch = pitch or self.pitch
    self.yaw = yaw or self.yaw
    return self
end
function M:setScale(scaleX, scaleY, scaleZ)
    self.scaleX = scaleX or self.scaleX
    self.scaleY = scaleY or self.scaleY
    self.scaleZ = scaleZ or self.scaleZ
    return self
end
function M:draw()
    lstg.RenderModel(self.name, self.x, self.y, self.z, self.roll, self.pitch, self.yaw, self.scaleX, self.scaleY, self.scaleZ)
end