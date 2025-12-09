---@class Core.UI.Draw : Core.UI.Child
---@field Sector Core.UI.Draw.Sector
---@field Rect Core.UI.Draw.Rect
---@field RectOutline Core.UI.Draw.RectOutline
---@field RoundedRect Core.UI.Draw.RoundedRect
---@field RoundedRectOutline Core.UI.Draw.RoundedRectOutline
---@field HexRect Core.UI.Draw.HexRect
---@field HexRectOutline Core.UI.Draw.HexRectOutline
---@field Parallelogram Core.UI.Draw.Parallelogram
---@field ParallelogramOutline Core.UI.Draw.ParallelogramOutline
local M = Core.Class(Core.UI.Child)
Core.UI.Draw = M

M:addSerializeSimple(Core.UI.Child, "_blend", "_color1", "_color2", "_color3", "_color4")
M:addDeserializeOrder("_color1", Core.Render.Color.Parse)
M:addDeserializeOrder("_color2", Core.Render.Color.Parse)
M:addDeserializeOrder("_color3", Core.Render.Color.Parse)
M:addDeserializeOrder("_color4", Core.Render.Color.Parse)

function M:init(name, layer)
    Core.UI.Child.init(self, name or "Draw", layer or 0)
    self._blend = Core.Render.BlendMode.Default
    self._color1 = Core.Render.Color.Default
    self._color2 = nil
    self._color3 = nil
    self._color4 = nil
    self._need_update = true
    self._ignore_pos_update = true
    self.datas = {}
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

function M:draw()
    local Draw = Core.Render.Draw
    Draw.SetState(self._blend, self._color1, self._color2, self._color3, self._color4)
    local x, y = self._x, self._y
    local z = 0.5
    for _, p in ipairs(self.datas) do
        Draw.Quad(x + p[1], y + p[2], z,
                x + p[3], y + p[4], z,
                x + p[5], y + p[6], z,
                x + p[7], y + p[8], z)
    end
    Core.UI.Child.draw(self)
end

require("Core.Scripts.UI.Draw.Sector")
require("Core.Scripts.UI.Draw.Rect")
require("Core.Scripts.UI.Draw.RectOutline")
require("Core.Scripts.UI.Draw.RoundedRect")
require("Core.Scripts.UI.Draw.RoundedRectOutline")
require("Core.Scripts.UI.Draw.HexRect")
require("Core.Scripts.UI.Draw.HexRectOutline")
require("Core.Scripts.UI.Draw.Parallelogram")
require("Core.Scripts.UI.Draw.ParallelogramOutline")