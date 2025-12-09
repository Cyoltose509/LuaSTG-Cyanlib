---@class Core.UI.Draw.HexRectOutline : Core.UI.Draw.Rect
local M = Core.Class(Core.UI.Draw.Rect)
Core.UI.Draw.HexRectOutline = M
function M:init()
    Core.UI.Draw.Rect.init(self)
    self.name = "Draw.HexRectOutline"
    self._name = "Draw.HexRectOutline"
    self.outline_width = 2
end
function M:setOutlineWidth(width)
    self.outline_width = width or self.outline_width
    self._need_update = true
    return self
end
local pos_map = {
    { 3, 4, 3, 4 },
    { 3, 4, 1, 2 },
    { 1, 2, 1, 2 },
    { 1, 2, 1, 2, },
    { 1, 2, 3, 4 },
    { 3, 4, 3, 4 },
}
function M:update()
    Core.UI.Draw.update(self)
    if self._need_update then
        local w, h = self.draw_width * self._hscale, self.draw_height * self._vscale
        local ang = 360 / 6
        local angle
        local r2 = h / SQRT3
        local r1 = r2 - self.outline_width
        local center = { -w / 2 + r2, 0, w / 2 - r2, 0 }
        local cosr, sinr = cos(self.rot), sin(self.rot)
        self.datas = {}
        for i = 1, 6 do
            angle = ang * i
            local x1, y1 = center[pos_map[i][1]] + r2 * cos(angle - ang), center[pos_map[i][2]] + r2 * sin(angle - ang)
            local x2, y2 = center[pos_map[i][1]] + r1 * cos(angle - ang), center[pos_map[i][2]] + r1 * sin(angle - ang)
            local x3, y3 = center[pos_map[i][3]] + r1 * cos(angle), center[pos_map[i][4]] + r1 * sin(angle)
            local x4, y4 = center[pos_map[i][3]] + r2 * cos(angle), center[pos_map[i][4]] + r2 * sin(angle)
            self.datas[i] = {
                x1 * cosr - y1 * sinr, y1 * cosr + x1 * sinr,
                x2 * cosr - y2 * sinr, y2 * cosr + x2 * sinr,
                x3 * cosr - y3 * sinr, y3 * cosr + x3 * sinr,
                x4 * cosr - y4 * sinr, y4 * cosr + x4 * sinr,
            }
        end
        self._need_update = false
    end
end

