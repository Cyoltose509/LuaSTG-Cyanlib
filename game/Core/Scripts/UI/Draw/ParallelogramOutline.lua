---@class Core.UI.Draw.ParallelogramOutline : Core.UI.Draw.Parallelogram
local M = Core.Class(Core.UI.Draw.Parallelogram)
Core.UI.Draw.ParallelogramOutline = M
function M:init()
    Core.UI.Draw.Parallelogram.init(self)
    self.name = "Draw.ParallelogramOutline"
    self._name = "Draw.ParallelogramOutline"
    self.outline_width = 2
end

function M:setOutlineWidth(width)
    self.outline_width = width or self.outline_width
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
        local o = self.outline_width
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
        local dir12 = Core.Math.Vector2.New(x2 - x1, y2 - y1):normalize() * o
        local dir14 = Core.Math.Vector2.New(x4 - x1, y4 - y1):normalize() * o
        local dir32 = Core.Math.Vector2.New(x2 - x3, y2 - y3):normalize() * o
        local dir34 = Core.Math.Vector2.New(x4 - x3, y4 - y3):normalize() * o
        self.datas = {
            Core.Math.Geom.RotateQuad(0, 0,
                    x1, y1,
                    x2, y2,
                    x2 - dir32.x, y2 - dir32.y,
                    x1 + dir14.x, y1 + dir14.y,
                    self.rot),
            Core.Math.Geom.RotateQuad(0, 0,
                    x2 - dir32.x, y2 - dir32.y,
                    x3 + dir32.x, y3 + dir32.y,
                    x3 + dir32.x + dir34.x, y3 + dir32.y + dir34.y,
                    x2 - dir32.x - dir12.x, y2 - dir32.y - dir12.y,
                    self.rot),
            Core.Math.Geom.RotateQuad(0, 0,
                    x4, y4,
                    x3, y3,
                    x3 + dir32.x, y3 + dir32.y,
                    x4 - dir14.x, y4 - dir14.y,
                    self.rot),
            Core.Math.Geom.RotateQuad(0, 0,
                    x1 + dir14.x, y1 + dir14.y,
                    x4 - dir14.x, y4 - dir14.y,
                    x4 - dir14.x - dir34.x, y4 - dir14.y - dir34.y,
                    x1 + dir14.x + dir12.x, y1 + dir14.y + dir12.y,
                    self.rot),

        }
        self._need_update = false
    end
end

