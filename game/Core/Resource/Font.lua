---@class Core.Resource.Font
local M = {}
Core.Resource.Font = M
M.__index = M
M.__type = "Font"

---@type Core.Resource.Font[]
M.res = {}

function M.New(name, path, mipmap)
    ---@type Core.Resource.Font
    local self = setmetatable({}, M)
    self.name = name
    self.path = path
    self._blend = Core.Render.BlendMode.Default
    self._color = Core.Render.Color.Default
    lstg.LoadFont(name, path, mipmap)
    self.res_pool = Core.Resource.GetResourcePool()
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end
function M.Remove(name)
    if M.res[name] then
        lstg.RemoveResource(M.res[name].res_pool, Core.Resource.ResType.Font, name)
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
function M:setBlend(blend)
    if blend ~= self._blend then
        self._blend = blend
        lstg.SetFontState(self.name, self._blend)
    end
end
function M:setColor(color)
    if color ~= self._color then
        self._color = color
        lstg.SetFontState(self.name, self._blend, self._color)
    end
end
function M:setState(blend, color)
    if blend ~= self._blend or color ~= self._color then
        self._blend = blend
        self._color = color
        lstg.SetFontState(self.name, self._blend, self._color)
    end
end


