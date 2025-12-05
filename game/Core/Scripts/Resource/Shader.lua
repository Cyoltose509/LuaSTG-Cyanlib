

---@class Core.Resource.Shader : lstg.PostEffectShader
local M = {}
Core.Resource.Shader = M
M.__index = M
M.__type = "Shader"

---@type Core.Resource.Shader[]
M.res = {}

function M.New(name, path)
    ---@type Core.Resource.Shader
    local self = lstg.CreatePostEffectShader(path)
    setmetatable(self, M)
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end
function M.Remove(name)
    if M.res[name] then
        --TODO：我真不知道了
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
---@param blend lstg.BlendMode
function M:post(blend)
    lstg.PostEffect(self.name, blend)
    return self
end