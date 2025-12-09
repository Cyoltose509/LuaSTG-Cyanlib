---@class Core.UI.Draw.HexRect : Core.UI.Draw.Rect
local M = Core.Class(Core.UI.Draw.Rect)
Core.UI.Draw.HexRect = M
function M:init()
    Core.UI.Draw.Rect.init(self)
    self.name = "Draw.HexRect"
    self._name = "Draw.HexRect"
end

function M:update()
    Core.UI.Draw.update(self)
    if self._need_update then
        local w, h = self.draw_width * self._hscale, self.draw_height * self._vscale
        local r = h / SQRT3/2
        local x1, x2 = -w / 2, w / 2
        local y1, y2 = -h / 2, h / 2
        self.datas = {
            Core.Math.Geom.RotateQuad(0, 0, x1, 0, x1 + r, y1, x2 - r, y1, x2, 0, self.rot),
            Core.Math.Geom.RotateQuad(0, 0, x1, 0, x1 + r, y2, x2 - r, y2, x2, 0, self.rot)
        }
        self._need_update = false
    end
end

