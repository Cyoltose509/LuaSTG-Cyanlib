---@class Core.Resource.Image
local M = {}
Core.Resource.Image = M
M.__index = M
M.__type = "Image"

---@type Core.Resource.Image[]
M.res = {}
---@type Core.Resource.Image[][]
M.res_group = {}

---@param name string
---@param tex Core.Resource.Texture|string
---@param x number?
---@param y number?
---@param width number?
---@param height number?
---@param a number?
---@param b number?
---@param rect boolean?
---@return Core.Resource.Image
function M.New(name, tex, x, y, width, height, a, b, rect)
    if type(tex) == "string" then
        tex = Core.Resource.Texture.Get(tex)
    end
    assert(tex and tex.__type == "Texture", "Invalid texture.")
    if M.res[name] then
        M.Remove(name)
    end
    x = x or 0
    y = y or 0
    width = width or tex.width
    height = height or tex.height
    a = a or 0
    b = b or 0
    rect = rect or false
    ---@type Core.Resource.Image
    local self = setmetatable({}, M)
    self.name = name
    self.texture = tex
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.a = a
    self.b = b
    self.rect = rect
    ------
    self.cx = x + width / 2
    self.cy = y + height / 2
    self.scaling = 1
    self._blend = Core.Render.BlendMode.Default
    self._color1 = Core.Render.Color.Default
    self._color2 = nil
    self._color3 = nil
    self._color4 = nil
    self._x, self._y = 0, 0
    self._rot = 0
    self._hscale = 0
    self._vscale = 0
    self._z = 0.5
    lstg.LoadImage(name, tex.name, x, y, width, height, a, b, rect)
    self.res_pool = Core.Resource.GetResourcePool()
    M.res[name] = self

    return self
end

---@param name string
---@param path string
---@param mipmap boolean?
---@param a number?
---@param b number?
---@param rect boolean?
---@return Core.Resource.Image
function M.NewFromFile(name, path, mipmap, a, b, rect)
    local tex = Core.Resource.Texture.New(name, path, mipmap)
    return M.New(name, tex, 0, 0, tex.width, tex.height, a, b, rect)
end

function M.Remove(name)
    if M.res[name] then
        lstg.RemoveResource(M.res[name].res_pool, Core.Resource.ResType.Image, name)
        M.res[name] = nil
    end
end
function M.Clear()
    for name in pairs(M.res) do
        M.Remove(name)
    end
end

---@return Core.Resource.Image
function M.Get(name)
    return M.res[name]
end

function M:unload()
    M.Remove(self.name)
end

---@param newname string
---@return Core.Resource.Image
function M:copy(newname)
    return M.New(newname, self.texture, self.x, self.y, self.width, self.height, self.a, self.b, self.rect)
end
---@param x number
---@param y number
function M:setCenter(x, y)
    lstg.SetImageCenter(self.name, x, y)
    self.cx = x
    self.cy = y
    return self
end
function M:getCenter()
    return self.cx, self.cy
end
---@param s number
function M:setScaling(s)
    lstg.SetImageScale(self.name, s)
    self.scaling = s
    return self
end
function M:getScaling()
    return self.scaling or lstg.GetImageScale(self.name)
end

---@private
function M:_applyState()
    if self._color2 then
        lstg.SetImageState(self.name, self._blend, self._color1, self._color2, self._color3, self._color4)
    else
        lstg.SetImageState(self.name, self._blend, self._color1)
    end
end

---@param blend lstg.BlendMode
function M:setBlend(blend)
    if blend ~= self._blend then
        self._blend = blend
        self:_applyState()
    end
    return self
end

---@overload fun(color:lstg.Color)
---@param c1 lstg.Color
---@param c2 lstg.Color
---@param c3 lstg.Color
---@param c4 lstg.Color
function M:setColor(c1, c2, c3, c4)
    if c2 then
        -- 四色版本
        if c1 ~= self._color1 or c2 ~= self._color2 or c3 ~= self._color3 or c4 ~= self._color4 then
            self._color1, self._color2, self._color3, self._color4 = c1, c2, c3, c4
            self:_applyState()
        end
    else
        -- 单色版本
        if c1 ~= self._color1 then
            self._color1 = c1
            self._color2 = nil  -- 标记为单色模式
            self._color3 = nil
            self._color4 = nil
            self:_applyState()
        end
    end
    return self
end

---@overload fun(blend:lstg.BlendMode)
---@overload fun(blend:lstg.BlendMode, color:lstg.Color)
---@overload fun(blend:lstg.BlendMode, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color)
function M:setState(blend, c1, c2, c3, c4)
    local changed = false
    if blend ~= self._blend then
        self._blend = blend
        changed = true
    end

    if c2 then
        if c1 ~= self._color1 or c2 ~= self._color2 or c3 ~= self._color3 or c4 ~= self._color4 then
            self._color1, self._color2, self._color3, self._color4 = c1, c2, c3, c4
            changed = true
        end
    elseif c1 then
        if c1 ~= self._color1 then
            self._color1 = c1
            self._color2 = nil
            self._color3 = nil
            self._color4 = nil
            changed = true
        end
    end

    if changed then
        self:_applyState()
    end
    return self
end

---@param x number
---@param y number
---@param z number
function M:setPos(x, y, z)
    self._x = x or self._x
    self._y = y or self._y
    self._z = z or self._z
    return self
end

---@param rot number
function M:setRotation(rot)
    self._rot = rot or self._rot
    return self
end
---@param hscale number
---@param vscale number
function M:setScale(hscale, vscale)
    self._hscale = hscale or self._hscale
    self._vscale = vscale or hscale or self._vscale
    return self
end
function M:draw()
    lstg.Render(self.name, self._x, self._y, self._rot, self._hscale, self._vscale, self._z)
    return self
end

---@param groupName string
---@param tex string|Core.Resource.Texture
---@param x number
---@param y number
---@param w number
---@param h number
---@param cols number
---@param rows number
---@param a number?
---@param b number?
---@param rect boolean?
---@return Core.Resource.Image[]
function M.NewGroup(groupName, tex, x, y, w, h, cols, rows, a, b, rect)
    local group = {}
    M.res_group[groupName] = group
    for i = 0, cols * rows - 1 do
        local img = M.New(groupName .. (i + 1), tex, x + w * (i % cols), y + h * (math.floor(i / cols)), w, h, a, b, rect)
        table.insert(group, img)
    end
    return group
end
function M.GetGroup(groupName)
    return M.res_group[groupName]
end
function M.RemoveGroup(groupName)
    for _, img in ipairs(M.res_group[groupName]) do
        img:unload()
    end
    M.res_group[groupName] = nil
end
function M.ClearGroup()
    for groupName in pairs(M.res_group) do
        M.RemoveGroup(groupName)
    end
end