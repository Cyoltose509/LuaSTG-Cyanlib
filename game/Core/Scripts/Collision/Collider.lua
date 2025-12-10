---@class Core.Collision.Collider
local M = {}
Core.Collision.Collider = M

M.Types = {
    None = 1,
    Circle = 2,
    Line = 3,
    Rectangle = 4,
    Ellipse = 5,
}

---@param object lstg.GameObject
function M.GetObjectType(object)
    if object.rect then
        return M.Types.Rectangle
    elseif object.a == object.b then
        return M.Types.Circle
    else
        return M.Types.Ellipse
    end
end

---@class Core.Collision.Collider.Base
local Base = Core.Class()
function Base:init(master)
    self.master = master
    self.type = M.Types.None
    self._x = 0
    self._y = 0
    self.x = 0
    self.y = 0
    self.colli = true
end
function Base:update()
    if self.master then
        local rot = self.master.rot or 0
        local cosr, sinr = cos(rot), sin(rot)
        local x, y = self._x * cosr - self._y * sinr, self._x * sinr + self._y * cosr
        self.x = self.master.x + x
        self.y = self.master.y + y
        self.colli = self.master.colli
    end
end
function Base:check(other)

end
---@param info Core.Collision.Info
function Base:onCollide(info)
    if self.master and self.master.class then
        self.master.class.colli(self.master, info.other)
    end
end

---@class Core.Collision.Collider.Circle : Core.Collision.Collider.Base
local Circle = Core.Class(Base)
function Circle:init(master, r, x, y)
    Base.init(self, master)
    self.type = M.Types.Circle
    self._x, self._y = x or 0, y or 0
    self.r = r or 15
end

---@class Core.Collision.Collider.Line : Core.Collision.Collider.Base
local Line = Core.Class(Base)
function Line:init(master, w, rotation, x, y)
    Base.init(self, master)
    self.type = M.Types.Line
    self._x, self._y = x or 0, y or 0
    self.w = w or 100
    self.rotation = rotation or 0
end

---@return Core.Collision.Info|nil
function Line:check(other, type)
    type = type or other.type
    if type == M.Types.Circle then
        local r = other.r
        local px, py = other.x, other.y
        local cosr, sinr = cos(self.rotation), sin(self.rotation)
        local w2 = self.w / 2
        local ax, ay = self.x - w2 * cosr, self.y - w2 * sinr
        local bx, by = self.x + w2 * cosr, self.y + w2 * sinr
        local abx = bx - ax
        local aby = by - ay
        local apx = px - ax
        local apy = py - ay
        local t = clamp((apx * abx + apy * aby) / (abx * abx + aby * aby), 0, 1)
        local cx = ax + t * abx
        local cy = ay + t * aby
        local dx = px - cx
        local dy = py - cy
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < r then
            return Core.Collision.NewInfo(self, other, cx, cy, dx / dist, dy / dist,r - dist)
        end
    end
end

---@return Core.Collision.Collider.Circle
function M.NewCircle(master, r, x, y)
    return Circle(master, r, x, y)
end

---@return Core.Collision.Collider.Line
function M.NewLine(master, w, rotation, x, y)
    return Line(master, w, rotation, x, y)
end