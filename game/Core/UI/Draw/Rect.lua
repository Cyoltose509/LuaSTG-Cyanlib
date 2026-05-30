---@class Core.UI.Draw.Rect : Core.UI.Draw
local M = Core.Class(Core.UI.Draw)
Core.UI.Draw.Rect = M

M:addSerializeSimple(Core.UI.Draw, "left", "top", "right", "bottom", "draw_width", "draw_height")

function M:init()
    Core.UI.Draw.init(self, "Draw.Rect", 0)
    self.left = 0
    self.top = 0
    self.right = 0
    self.bottom = 0
    self.draw_width = self.width
    self.draw_height = self.height
end

---@return self
function M:setRect(left, right, bottom, top)
    left=left or self.left
    right=right or self.right
    bottom=bottom or self.bottom
    top=top or self.top
    if self.left ~= left or self.right ~= right or self.bottom ~= bottom or self.top ~= top then
        self.left = left
        self.right = right
        self.bottom = bottom
        self.top = top
        self.draw_width = self.right - self.left
        self.draw_height = self.top - self.bottom
        self:setPos((self.left + self.right) / 2, (self.bottom + self.top) / 2)
        self:setWH(self.draw_width, self.draw_height)
        self._need_update = true
    end
    return self
end

---@return self
function M:setDrawSize(width, height)
    width = width or self.width
    height = height or self.height
    if self.draw_width ~= width or self.draw_height ~= height then
        self.draw_width = width
        self.draw_height = height
        self.left = self._x - self.draw_width / 2
        self.right = self._x + self.draw_width / 2
        self.bottom = self._y - self.draw_height / 2
        self.top = self._y + self.draw_height / 2
        self:setWH(self.draw_width, self.draw_height)
        self._need_update = true
    end
    return self
end

function M:update()
    Core.UI.Draw.update(self)
    if self._need_update then
        self.datas={
            Core.Math.Geom.GetRectPoints(0,0,self.draw_width * self._hscale, self.draw_height * self._vscale, self.rot)
        }
        self._need_update = false
    end
end

