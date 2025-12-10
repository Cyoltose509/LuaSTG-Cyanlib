---@class Core.UI.Draw.Sector : Core.UI.Draw
local M = Core.Class(Core.UI.Draw)
Core.UI.Draw.Sector = M

M:addSerializeSimple(Core.UI.Draw, "radius1", "radius2", "angle1", "angle2", "seg")

function M:init()
    Core.UI.Draw.init(self, "Draw.Sector", 0)
    self.radius1 = 0
    self.radius2 = 50
    self.angle1 = 0
    self.angle2 = 360
    self.seg = 4
end
function M:setRadius(radius1, radius2)
    radius1 = radius1 or self.radius1
    radius2 = radius2 or self.radius2
    if self.radius1 ~= radius1 or self.radius2 ~= radius2 then
        self.radius1 = radius1
        self.radius2 = radius2
        self:setWH(self.radius1 * 2, self.radius2 * 2)
        self._need_update = true
    end
    return self
end
function M:setAngle(angle1, angle2)
    angle1 = angle1 or self.angle1
    angle2 = angle2 or self.angle2
    if self.angle1 ~= angle1 or self.angle2 ~= angle2 then
        self.angle1 = angle1
        self.angle2 = angle2
        self._need_update = true
    end
    return self
end
function M:setSeg(seg)
    seg = seg or 3
    seg = max(3, seg)
    if self.seg ~= seg then
        self.seg = seg
        self._need_update = true
    end
    return self
end
function M:update()
    Core.UI.Draw.update(self)
    if self._need_update then
        local cosr, sinr = cos(self.rot), sin(self.rot)
        local r1, r2 = self.radius1, self.radius2
        local hscale, vscale = self._hscale, self._vscale
        local ang_step = (self.angle2 - self.angle1) / self.seg
        local angle
        self.datas = {}
        for i = 1, self.seg do
            angle = self.angle1 + ang_step * i
            local x1, y1 = r2 * cos(angle - ang_step) * hscale, r2 * sin(angle - ang_step) * vscale
            local x2, y2 = r1 * cos(angle - ang_step) * hscale, r1 * sin(angle - ang_step) * vscale
            local x3, y3 = r1 * cos(angle) * hscale, r1 * sin(angle) * vscale
            local x4, y4 = r2 * cos(angle) * hscale, r2 * sin(angle) * vscale
            self.datas[i] = {
                x1 * cosr - y1 * sinr, x1 * sinr + y1 * cosr,
                x2 * cosr - y2 * sinr, x2 * sinr + y2 * cosr,
                x3 * cosr - y3 * sinr, x3 * sinr + y3 * cosr,
                x4 * cosr - y4 * sinr, x4 * sinr + y4 * cosr
            }
        end
        self._need_update = false
    end
end

