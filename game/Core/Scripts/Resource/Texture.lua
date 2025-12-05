---@class Core.Resource.Texture
local M = {}
Core.Resource.Texture = M
M.__index = M
M.__type = "Texture"

---@type Core.Resource.Texture[]
M.res = {}

---@param name string
---@param path string
---@param mipmap boolean
---@return Core.Resource.Texture
function M.New(name, path, mipmap)
    if M.res[name] then
        M.Remove(name)
    end
    ---@type Core.Resource.Texture
    local self = setmetatable({}, M)
    self.path = path
    self.name = name
    self._blend = Core.Render.BlendMode.Default
    local white = Core.Render.Color.Default
    self._uv1 = { 0, 0, 0, 0, 0, white }
    self._uv2 = { 0, 0, 0, 0, 0, white }
    self._uv3 = { 0, 0, 0, 0, 0, white }
    self._uv4 = { 0, 0, 0, 0, 0, white }
    lstg.LoadTexture(name, path, mipmap)
    self.is_texture = true
    self.sampler_state = Core.Render.SamplerState.LinearClamp
    self.width, self.height = lstg.GetTextureSize(name)
    self.res_pool = Core.Resource.GetResourcePool()
    M.res[name] = self
    return self
end


function M.Remove(name)
    if M.res[name] then
        lstg.RemoveResource(M.res[name].res_pool, Core.Resource.ResType.Texture, name)
        M.res[name] = nil
    end
end

function M.Clear()
    for name in pairs(M.res) do
        M.Remove(name)
    end
end

---@return Core.Resource.Texture
function M.Get(name)
    return M.res[name]
end

function M:unload()
    M.Remove(self.name)
end
---@param known_sampler_state lstg.KnownSamplerState
function M:setSampler(known_sampler_state)
    lstg.SetTextureSamplerState(self.name, known_sampler_state)
    self.sampler_state = known_sampler_state
    return self
end
function M:getSize()
    if self.is_texture then
        return self.width, self.height
    end
end
function M:setBlend(blend)
    self._blend = blend
    return self
end
function M:setUV1(x, y, z, ux, uy, col)
    self._uv1[1] = x or self._uv1[1]
    self._uv1[2] = y or self._uv1[2]
    self._uv1[3] = z or self._uv1[3]
    self._uv1[4] = ux or self._uv1[4]
    self._uv1[5] = uy or self._uv1[5]
    self._uv1[6] = col or self._uv1[6]
    return self
end
function M:setUV2(x, y, z, ux, uy, col)
    self._uv2[1] = x or self._uv2[1]
    self._uv2[2] = y or self._uv2[2]
    self._uv2[3] = z or self._uv2[3]
    self._uv2[4] = ux or self._uv2[4]
    self._uv2[5] = uy or self._uv2[5]
    self._uv2[6] = col or self._uv2[6]
    return self
end
function M:setUV3(x, y, z, ux, uy, col)
    self._uv3[1] = x or self._uv3[1]
    self._uv3[2] = y or self._uv3[2]
    self._uv3[3] = z or self._uv3[3]
    self._uv3[4] = ux or self._uv3[4]
    self._uv3[5] = uy or self._uv3[5]
    self._uv3[6] = col or self._uv3[6]
    return self
end
function M:setUV4(x, y, z, ux, uy, col)
    self._uv4[1] = x or self._uv4[1]
    self._uv4[2] = y or self._uv4[2]
    self._uv4[3] = z or self._uv4[3]
    self._uv4[4] = ux or self._uv4[4]
    self._uv4[5] = uy or self._uv4[5]
    self._uv4[6] = col or self._uv4[6]
    return self
end
function M:draw()
    lstg.RenderTexture(self.name, self._blend, self._uv1, self._uv2, self._uv3, self._uv4)
    return self
end

