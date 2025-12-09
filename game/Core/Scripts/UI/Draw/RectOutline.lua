---@class Core.UI.Draw.RectOutline : Core.UI.Draw.Rect
local M = Core.Class(Core.UI.Draw.Rect)
Core.UI.Draw.RectOutline = M

M:addSerializeSimple(Core.UI.Draw.Rect, "outline_width")

function M:init()
    Core.UI.Draw.Rect.init(self)
    self.name = "Draw.RectOutline"
    self._name = "Draw.RectOutline"
    self.outline_width = 2
end
function M:setOutlineWidth(width)
    self.outline_width = width or self.outline_width
    return self
end
function M:update()
    Core.UI.Draw.update(self)
    if self._need_update then
        local w, h = self.draw_width * self._hscale, self.draw_height * self._vscale
        local o = self.outline_width
        local rot = self.rot
        self.datas = {
            Core.Math.Geom.GetRectPoints(0, h / 2 - o / 2, w, o, rot),
            Core.Math.Geom.GetRectPoints(0, -h / 2 + o / 2, w, o, rot),
            Core.Math.Geom.GetRectPoints(w / 2 - o / 2, 0, o, h, rot),
            Core.Math.Geom.GetRectPoints(-w / 2 + o / 2, 0, o, h, rot),
        }
        self._need_update = false
    end
end

