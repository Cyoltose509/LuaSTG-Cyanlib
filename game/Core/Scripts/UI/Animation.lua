---@class Core.UI.Animation : Core.UI.Child
local M = Core.Class(Core.UI.Child)
Core.UI.Animation = M

M:addSerializeSimple(Core.UI.Child, "ani_name", "_blend", "_color1", "_color2", "_color3", "_color4", "lock_animation")
M:addDeserializeOrder("_color1", Core.Render.Color.Parse)
M:addDeserializeOrder("_color2", Core.Render.Color.Parse)
M:addDeserializeOrder("_color3", Core.Render.Color.Parse)
M:addDeserializeOrder("_color4", Core.Render.Color.Parse)
M:addDeserializeOrder("ani_name", function(value, self)
    self:setAnimation(value)
    return value
end)

---@alias Core.UI.Animation.New Core.UI.Animation|fun(animation:string):Core.UI.Animation
function M:init(animation)
    Core.UI.Child.init(self, "Animation", 0)
    self.ani_timer = 0
    self.lock_animation = false
    self:setAnimation(animation)
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
function M:setAnimation(animation)
    self.ani_name = animation
    if self.ani_name then
        ---@type Core.Resource.Animation
        self.ani = assert(Core.Resource.Animation.Get(self.ani_name), "Animation not found: " .. self.ani_name)
        self:setWH(self.ani.width, self.ani.height)
    end
    return self
end
function M:update()
    Core.UI.Child.update(self)
    if not self.lock_animation then
        self.ani_timer = self.ani_timer + 1
    end
end
function M:lockAnimation(enable)
    self.lock_animation = enable
end
function M:draw()
    if self.ani then
        self.ani:setRotation(self.rot)
            :setState(self._blend, self._color1, self._color2, self._color3, self._color4)
            :setScale(self._hscale, self._vscale)
            :setPos(self._x, self._y)
            :draw(self.ani_timer)
    end
end