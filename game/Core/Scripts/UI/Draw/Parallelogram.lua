---@class Core.UI.Draw.Parallelogram : Core.UI.Draw.Rect
local M = Core.Class(Core.UI.Draw.Rect)
Core.UI.Draw.Parallelogram = M
function M:init()
    Core.UI.Draw.Rect.init(self)
    self.name = "Draw.Parallelogram"
    self._name = "Draw.Parallelogram"
    self.skew_angle = 90
end

function M:setSkewAngle(angle)
    self.skew_angle = angle
    self._need_update = true
    return self
end

function M:update()
    Core.UI.Draw.update(self)
    if self._need_update then
        local w, h = self.draw_width * self._hscale, self.draw_height * self._vscale
        local ts = abs(tan(self.skew_angle))
        local x1, y1 = -w / 2, h / 2
        local x2, y2 = w / 2, h / 2
        local x3, y3 = w / 2, -h / 2
        local x4, y4 = -w / 2, -h / 2
        local a = self.skew_angle % 180
        if a < 90 then
            if h / ts > w then
                y1 = y1 - w * ts
                y3 = y3 + w * ts
            else
                x1 = x1 + h / ts
                x3 = x3 - h / ts
            end
        elseif a < 180 then
            if h / ts > w then
                y2 = y2 - w * ts
                y4 = y4 + w * ts
            else
                x2 = x2 - h / ts
                x4 = x4 + h / ts
            end
        end

        self.datas = {
            Core.Math.Geom.RotateQuad(0, 0, x1, y1, x2, y2, x3, y3, x4, y4, self.rot),
        }
        self._need_update = false
    end
end

