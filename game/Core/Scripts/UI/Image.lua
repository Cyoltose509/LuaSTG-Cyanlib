---@class Core.UI.Image : Core.UI.Child
local M = Core.Class(Core.UI.Child)
Core.UI.Image = M

M:addSerializeSimple(Core.UI.Child, "img_name", "_blend", "_color1", "_color2", "_color3", "_color4")
M:addDeserializeOrder("_color1", Core.Render.Color.Parse)
M:addDeserializeOrder("_color2", Core.Render.Color.Parse)
M:addDeserializeOrder("_color3", Core.Render.Color.Parse)
M:addDeserializeOrder("_color4", Core.Render.Color.Parse)
M:addDeserializeOrder("img_name", function(value, self)
    self:setImage(value)
    return value
end)

---@alias Core.UI.Image.New Core.UI.Image|fun(image:string):Core.UI.Image
function M:init(image)
    Core.UI.Child.init(self, "Image", 0)
    self:setImage(image)
    self._blend = Core.Render.BlendMode.Default
    self._color1 = Core.Render.Color.Default
    self._color2 = nil
    self._color3 = nil
    self._color4 = nil

end
---@overload fun(blend:lstg.BlendMode, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color):self
---@overload fun(blend:lstg.BlendMode, color:lstg.Color):self
---@overload fun(blend:lstg.BlendMode):self
function M:setState(blend, c1, c2, c3, c4)
    self._blend = blend or self._blend
    if c2 and c3 and c4 then
        self._color1 = c1
        self._color2 = c2
        self._color3 = c3
        self._color4 = c4
    else
        self._color1 = c1 or self._color1
        self._color2 = nil
        self._color3 = nil
        self._color4 = nil
    end
    return self
end
function M:setImage(image)
    self.img_name = image
    if self.img_name then
        ---@type Core.Resource.Image
        self.img = assert(Core.Resource.Image.Get(self.img_name), "Image not found: " .. self.img_name)
        self:setWH(self.img.width, self.img.height)
    end
    return self

end
function M:update()
    Core.UI.Child.update(self)
end
function M:draw()
    if self.img then
        self.img:setRotation(self.rot)
            :setState(self._blend, self._color1, self._color2, self._color3, self._color4)
            :setScale(self._hscale, self._vscale)
            :setPos(self._x, self._y)
            :draw()
    end
end