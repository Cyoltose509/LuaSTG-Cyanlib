---@class Core.UI.TextureRect : Core.UI.Child
local M = Core.Class(Core.UI.Child)
Core.UI.TextureRect = M

M:addSerializeSimple(Core.UI.Child, "tex_name", "_blend", "_color1", "_color2", "_color3", "_color4", "uvX", "uvY", "uvW", "uvH")
M:addDeserializeOrder("_color1", Core.Render.Color.Parse)
M:addDeserializeOrder("_color2", Core.Render.Color.Parse)
M:addDeserializeOrder("_color3", Core.Render.Color.Parse)
M:addDeserializeOrder("_color4", Core.Render.Color.Parse)
M:addDeserializeOrder("tex_name", function(value, self)
    self:setTexture(value, true)
    return value
end)

---@alias Core.UI.TextureRect.New Core.UI.TextureRect.New|fun(tex:string):Core.UI.TextureRect
function M:init(tex)
    Core.UI.Child.init(self, "TextureRect", 0)
    self:setTexture(tex)

    self._blend = Core.Render.BlendMode.Default
    self._color1 = Core.Render.Color.Default
    self._color2 = nil
    self._color3 = nil
    self._color4 = nil
    self._needUpdate = true
    self.uv_data = {
        { 0, 0, 0, 0, },
        { 0, 0, 0, 0, },
        { 0, 0, 0, 0, },
        { 0, 0, 0, 0, },
    }
end
function M:setState(blend, c1, c2, c3, c4)
    self._blend = blend or self._blend
    self._color1 = c1 or self._color1
    self._color2 = c2 or self._color2 or self._color1
    self._color3 = c3 or self._color3 or self._color2
    self._color4 = c4 or self._color4 or self._color3
    return self
end
function M:setUV(x, y, width, height)
    self.uvX = x
    self.uvY = y
    self.uvW = width
    self.uvH = height
    self:setWH(width, height)
    self._needUpdate = true
    return self
end
function M:setTexture(tex, notSetUV)
    self.tex_name = tex
    if self.tex_name then
        ---@type Core.Resource.Texture
        self.tex = assert(Core.Resource.Texture.Get(self.tex_name), "Texture not found: " .. self.tex_name)
        if not notSetUV then
            self:setUV(0, 0, self.tex:getSize())
        end
    end
    return self
end
function M:setRotation(rot)
    self.rot = rot
    self._needUpdate = true
    return self
end
function M:update()
    local _x, _y, _h, _v = self._x, self._y, self._hscale, self._vscale
    Core.UI.Child.update(self)
    if self._needUpdate or self._x ~= _x or self._y ~= _y or self._hscale ~= _h or self._vscale ~= _v then
        local cosr, sinr = cos(self.rot), sin(self.rot)
        local w, h = self.width * self._hscale / 2, self.height * self._vscale / 2
        self.uv_data[1][1], self.uv_data[1][2] = self._x - cosr * w - sinr * h, self._y - sinr * w + cosr * h
        self.uv_data[2][1], self.uv_data[2][2] = self._x + cosr * w - sinr * h, self._y + sinr * w + cosr * h
        self.uv_data[3][1], self.uv_data[3][2] = self._x + cosr * w + sinr * h, self._y + sinr * w - cosr * h
        self.uv_data[4][1], self.uv_data[4][2] = self._x - cosr * w + sinr * h, self._y - sinr * w - cosr * h
        self.uv_data[1][3], self.uv_data[1][4] = self.uvX, self.uvY
        self.uv_data[2][3], self.uv_data[2][4] = self.uvX + self.uvW, self.uvY
        self.uv_data[3][3], self.uv_data[3][4] = self.uvX + self.uvW, self.uvY + self.uvH
        self.uv_data[4][3], self.uv_data[4][4] = self.uvX, self.uvY + self.uvH
        self._needUpdate = false
    end
end
function M:draw()
    if self.tex then
        self.tex:setBlend(self._blend)
            :setUV1(self.uv_data[1][1], self.uv_data[1][2], 0.5, self.uv_data[1][3], self.uv_data[1][4], self._color1)
            :setUV2(self.uv_data[2][1], self.uv_data[2][2], 0.5, self.uv_data[2][3], self.uv_data[2][4], self._color2)
            :setUV3(self.uv_data[3][1], self.uv_data[3][2], 0.5, self.uv_data[3][3], self.uv_data[3][4], self._color3)
            :setUV4(self.uv_data[4][1], self.uv_data[4][2], 0.5, self.uv_data[4][3], self.uv_data[4][4], self._color4)
            :draw()
    end
end