---@class Core.UI.Draw.RoundedRectOutline : Core.UI.Draw.RoundedRect
local M = Core.Class(Core.UI.Draw.RoundedRect)
Core.UI.Draw.RoundedRectOutline = M

M:addSerializeSimple(Core.UI.Draw.RoundedRect, "outline_width")

function M:init()
    Core.UI.Draw.RoundedRect.init(self)
    self.name = "Draw.RoundedRectOutline"
    self._name = "Draw.RoundedRectOutline"
    self.outline_width = 2
end
function M:setOutlineWidth(width)
    width = width or 2
    if self.outline_width ~= width then
        self.outline_width = width
        self._need_update = true
    end
    return self
end
function M:update()
    Core.UI.Draw.update(self)
    if self._need_update then
        local cosr, sinr = cos(self.rot), sin(self.rot)
        local hscale, vscale = self._hscale, self._vscale
        local w = self.draw_width * self._hscale
        local h = self.draw_height * self._vscale
        local rh = self.round_size * hscale
        local rv = self.round_size * vscale
        local o = self.outline_width
        if self.lock_round_aspect then
            local m = min(rh, rv)
            rh, rv = m, m
        end
        local rh2 = rh - o
        local rv2 = rv - o
        local ox, oy
        self.datas = {}
        table.insert(self.datas, Core.Math.Geom.GetRectPoints(0, -h / 2 + o / 2, w - rh * 2, o, self.rot))
        table.insert(self.datas, Core.Math.Geom.GetRectPoints(0, h / 2 - o / 2, w - rh * 2, o, self.rot))
        table.insert(self.datas, Core.Math.Geom.GetRectPoints(-w / 2 + o / 2, 0, o, h - rv * 2, self.rot))
        table.insert(self.datas, Core.Math.Geom.GetRectPoints(w / 2 - o / 2, 0, o, h - rv * 2, self.rot))
        local pos = {
            w / 2 - rh, h / 2 - rv,
            -w / 2 + rh, h / 2 - rv,
            -w / 2 + rh, -h / 2 + rv,
            w / 2 - rh, -h / 2 + rv
        }
        local angle
        local ang_step = 90 / self.round_seg
        for m = 1, 4 do
            local p = m * 2 - 1
            ox, oy = pos[p] * cosr - pos[p + 1] * sinr, pos[p] * sinr + pos[p + 1] * cosr
            for i = 1, self.round_seg do
                angle = 90 * (m - 1) + ang_step * i
                local x1, y1 = rh * cos(angle - ang_step), rv * sin(angle - ang_step)
                local x2, y2 = rh2 * cos(angle - ang_step), rv2 * sin(angle - ang_step)
                local x3, y3 = rh2 * cos(angle), rv2 * sin(angle)
                local x4, y4 = rh * cos(angle), rv * sin(angle)
                table.insert(self.datas, {
                    ox + x1 * cosr - y1 * sinr, oy + x1 * sinr + y1 * cosr,
                    ox + x2 * cosr - y2 * sinr, oy + x2 * sinr + y2 * cosr,
                    ox + x3 * cosr - y3 * sinr, oy + x3 * sinr + y3 * cosr,
                    ox + x4 * cosr - y4 * sinr, oy + x4 * sinr + y4 * cosr
                })
            end
        end
        self._need_update = false
    end
end
