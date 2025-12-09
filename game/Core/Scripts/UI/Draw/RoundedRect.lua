---@class Core.UI.Draw.RoundedRect : Core.UI.Draw.Rect
local M = Core.Class(Core.UI.Draw.Rect)
Core.UI.Draw.RoundedRect = M

M:addSerializeSimple(Core.UI.Draw.Rect, "round_size", "round_seg", "lock_round_aspect")

function M:init()
    Core.UI.Draw.Rect.init(self)
    self.name = "Draw.RoundedRect"
    self._name = "Draw.RoundedRect"
    self.round_size = 10
    self.round_seg = 1
    self.lock_round_aspect = false
end
---@return self
function M:lockRoundAspect(enable)
    self.lock_round_aspect = enable
    self._need_update = true
    return self
end
---@return self
function M:setRoundSize(size)
    self.round_size = size
    self._need_update = true
    return self
end
---@return self
function M:setRoundSeg(seg)
    self.round_seg = seg
    self._need_update = true
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
        if self.lock_round_aspect then
            local m = min(rh, rv)
            rh, rv = m, m
        end
        self.datas = {}
        table.insert(self.datas, Core.Math.Geom.GetRectPoints(0, 0, w - rh * 2, h, self.rot))
        table.insert(self.datas, Core.Math.Geom.GetRectPoints(-w / 2 + rh / 2, 0, rh, h - rv * 2, self.rot, true))
        table.insert(self.datas, Core.Math.Geom.GetRectPoints(w / 2 - rh / 2, 0, rh, h - rv * 2, self.rot, true))
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
            local ox, oy = pos[p] * cosr - pos[p + 1] * sinr, pos[p] * sinr + pos[p + 1] * cosr
            for i = 1, self.round_seg do
                angle = 90 * (m - 1) + ang_step * i
                local x1, y1 = rh * cos(angle - ang_step), rv * sin(angle - ang_step)
                local x4, y4 = rh * cos(angle), rv * sin(angle)
                table.insert(self.datas, {
                    ox + x1 * cosr - y1 * sinr, oy + x1 * sinr + y1 * cosr,
                    ox, oy,
                    ox, oy,
                    ox + x4 * cosr - y4 * sinr, oy + x4 * sinr + y4 * cosr
                })
            end
        end
        self._need_update = false
    end
end

