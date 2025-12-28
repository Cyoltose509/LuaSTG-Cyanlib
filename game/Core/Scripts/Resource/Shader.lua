---@class Core.Resource.Shader
local M = {}
Core.Resource.Shader = M
M.__index = M
M.__type = "Shader"

---@type Core.Resource.Shader[]
M.res = {}

function M.New(name, path)
    ---@type Core.Resource.Shader
    local self = {}
    setmetatable(self, M)
    self.main = lstg.CreatePostEffectShader(path)
    self.name = name
    self.path = path
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end
function M.Remove(name)
    if M.res[name] then
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

function M:setFloat(name, value)
    self.main:setFloat(name, value)
    return self
end
function M:setFloat2(name, x, y)
    self.main:setFloat2(name, x, y)
    return self
end
function M:setFloat3(name, x, y, z)
    self.main:setFloat3(name, x, y, z)
    return self
end
function M:setFloat4(name, x, y, z, w)
    self.main:setFloat4(name, x, y, z, w)
    return self
end
function M:setTexture(name, resource_name)
    self.main:setTexture(name, resource_name)
    return self
end
---@param blend lstg.BlendMode
function M:post(blend)
    lstg.PostEffect(self.main, blend)
    return self
end