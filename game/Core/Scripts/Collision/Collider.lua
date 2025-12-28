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
local Vec2 = Core.Math.Vector2
---@param self Core.Collision._Collider
---@param other Core.Collision._Collider
---@param nx number
---@param ny number
---@param distance number 碰撞距离
---@param px number
---@param py number
function M.NewInfo(self, other, nx, ny, px, py, distance)
    ---@class Core.Collision.Info
    local info = {
        self = self,
        other = other,
        normal = Vec2.New(nx, ny),
        distance = distance,
        point = Vec2.New(px, py)
    }
    ---@return Core.Collision.Info
    local s, o, nnx, nny, ppx, ppy, dd = self, other, nx, ny, px, py, distance
    function info:reverse()
        return M.NewInfo(o, s, -nnx, -nny, ppx, ppy, dd)
    end
    return info
end

local function distance2(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy, dx, dy
end
local function normalize(dx, dy)
    local len = sqrt(dx * dx + dy * dy)
    if len > 1e-6 then
        return dx / len, dy / len, len
    else
        return 0, 0, 0
    end
end
local function rotate_point(px, py, cosr, sinr)
    return px * cosr - py * sinr, px * sinr + py * cosr
end

function M.CircleCircleCheck(c1, c2)
    local dist2, dx, dy = distance2(c1.x, c1.y, c2.x, c2.y)
    local r = c1.a + c2.a
    if dist2 < r * r then
        local nx, ny, dist = normalize(dx, dy)
        local penetration = r - dist
        local px = c1.x + nx * c1.a
        local py = c1.y + ny * c1.a
        return M.NewInfo(c1, c2, nx, ny, px, py, penetration)
    end
end

function M.RectCircleCheck(rect, circle)
    local px, py = circle.x - rect.x, circle.y - rect.y
    local cosr, sinr = cos(-rect.rot), sin(-rect.rot)
    local rx, ry = rotate_point(px, py, cosr, sinr)
    local hw, hh = rect.a, rect.b
    local cx, cy = clamp(rx, -hw, hw), clamp(ry, -hh, hh)
    local dx, dy = rx - cx, ry - cy
    local dist2 = dx * dx + dy * dy
    if dist2 < circle.a * circle.a then
        local dist = sqrt(dist2)
        local nx, ny
        if dist > 1e-6 then
            nx, ny = dx / dist, dy / dist
        else
            if abs(rx) > abs(ry) then
                nx, ny = (rx > 0) and 1 or -1, 0
            else
                nx, ny = 0, (ry > 0) and 1 or -1
            end
            dist = 0
        end
        local penetration = circle.a - dist
        local wx, wy = rotate_point(cx, cy, -cosr, -sinr) -- 反转到世界
        wx, wy = wx + rect.x, wy + rect.y
        local wn_x, wn_y = rotate_point(nx, ny, cos(rect.rot), sin(rect.rot))
        return M.NewInfo(rect, circle, wn_x, wn_y, wx, wy, penetration)
    end
end

function M.LineCircleCheck(line, circle)
    local px, py = circle.x, circle.y
    local r = circle.a
    local cosr, sinr = cos(line.rot), sin(line.rot)
    local ax, ay = line.x - line.w / 2 * cosr, line.y - line.w / 2 * sinr
    local bx, by = line.x + line.w / 2 * cosr, line.y + line.w / 2 * sinr
    local abx, aby = bx - ax, by - ay
    local apx, apy = px - ax, py - ay
    local t = clamp((apx * abx + apy * aby) / (abx * abx + aby * aby), 0, 1)
    local cx, cy = ax + t * abx, ay + t * aby
    local dx, dy = px - cx, py - cy
    local dist = sqrt(dx * dx + dy * dy)
    if dist < r then
        local nx, ny = normalize(dx, dy)
        return M.NewInfo(line, circle, nx, ny, cx, cy, r - dist)
    end
end

function M.RectRectCheck(r1, r2)
    local function get_axes(rect)
        local cosr, sinr = cos(rect.rot), sin(rect.rot)
        return { Vec2.New(cosr, sinr), Vec2.New(-sinr, cosr) }
    end
    local function project(rect, axis)
        local corners = {
            Vec2.New(-rect.a, -rect.b), Vec2.New(rect.a, -rect.b),
            Vec2.New(rect.a, rect.b), Vec2.New(-rect.a, rect.b)
        }
        local minp, maxp
        local cosr, sinr = cos(rect.rot), sin(rect.rot)
        for _, c in ipairs(corners) do
            local wx, wy = rotate_point(c.x, c.y, cosr, sinr)
            wx, wy = wx + rect.x, wy + rect.y
            local p = wx * axis.x + wy * axis.y
            if not minp or p < minp then
                minp = p
            end
            if not maxp or p > maxp then
                maxp = p
            end
        end
        return minp, maxp
    end

    -- SAT: 找到最小穿透轴
    local best_overlap = 1e9
    local best_axis = nil

    local axes = get_axes(r1)
    for _, axis in ipairs(axes) do
        local min1, max1 = project(r1, axis)
        local min2, max2 = project(r2, axis)
        if max1 < min2 or max2 < min1 then
            return nil
        end
        local overlap = min(max1, max2) - max(min1, min2)
        if overlap < best_overlap then
            best_overlap = overlap
            best_axis = axis
        end
    end

    axes = get_axes(r2)
    for _, axis in ipairs(axes) do
        local min1, max1 = project(r1, axis)
        local min2, max2 = project(r2, axis)
        if max1 < min2 or max2 < min1 then
            return nil
        end
        local overlap = min(max1, max2) - max(min1, min2)
        if overlap < best_overlap then
            best_overlap = overlap
            best_axis = axis
        end
    end

    if not best_axis then
        return nil
    end

    -- 法线方向：从 r1 指向 r2
    local dot = (r2.x - r1.x) * best_axis.x + (r2.y - r1.y) * best_axis.y
    local nx, ny = best_axis.x, best_axis.y
    if dot < 0 then
        nx, ny = -nx, -ny
    end

    -- 计算接触点（沿着轴的投影位置，返回世界坐标）
    local min1, max1 = project(r1, best_axis)
    local p1_center = (min1 + max1) * 0.5
    local r1_half = (max1 - min1) * 0.5
    local sign = (dot >= 0) and 1 or -1
    local contact_proj = p1_center + sign * (r1_half - best_overlap * 0.5)
    local cx, cy = best_axis.x * contact_proj, best_axis.y * contact_proj

    return M.NewInfo(r1, r2, nx, ny, cx, cy, best_overlap)
end

function M.EllipseEllipseCheck(e1, e2)
    local dx, dy = e2.x - e1.x, e2.y - e1.y
    local cosr, sinr = cos(-e1.rot), sin(-e1.rot)
    local lx, ly = rotate_point(dx, dy, cosr, sinr)
    local nx, ny = lx / e1.a, ly / e1.b
    local dist_unit = sqrt(nx * nx + ny * ny)
    if dist_unit < 1 then
        nx, ny = normalize(nx, ny)
        local penetration = (1 - dist_unit) * max(e1.a, e1.b)
        return M.NewInfo(e1, e2, nx, ny, e1.x + lx, e1.y + ly, penetration)
    end
end

function M.CircleEllipseCheck(circle, ellipse)
    local dx, dy = circle.x - ellipse.x, circle.y - ellipse.y
    local cosr, sinr = cos(-ellipse.rot), sin(-ellipse.rot)
    local lx, ly = rotate_point(dx, dy, cosr, sinr)
    local nx, ny = lx / ellipse.a, ly / ellipse.b
    local dist_unit = sqrt(nx * nx + ny * ny)
    if dist_unit < 1 then
        nx, ny = normalize(nx, ny)
        local penetration = (1 - dist_unit) * max(ellipse.a, ellipse.b) + circle.a
        return M.NewInfo(circle, ellipse, nx, ny, ellipse.x + lx, ellipse.y + ly, penetration)
    end
end

function M.LineRectCheck(line, rect)
    -- 把线段端点转到 rect 局部空间
    local cosr, sinr = cos(-rect.rot), sin(-rect.rot)

    local hx = (line.w * 0.5) * cos(line.rot)
    local hy = (line.w * 0.5) * sin(line.rot)

    -- 线段端点（世界）
    local axw, ayw = line.x - hx, line.y - hy
    local bxw, byw = line.x + hx, line.y + hy

    -- 转到 rect 局部
    local ax, ay = rotate_point(axw - rect.x, ayw - rect.y, cosr, sinr)
    local bx, by = rotate_point(bxw - rect.x, byw - rect.y, cosr, sinr)

    local hw, hh = rect.a, rect.b

    -- === 线段 vs AABB（slab 法）===
    local tmin, tmax = 0, 1
    local dx = bx - ax
    local dy = by - ay

    local function clip(p, q)
        if p == 0 then
            return q >= 0
        end
        local r = q / p
        if p < 0 then
            if r > tmax then
                return false
            end
            if r > tmin then
                tmin = r
            end
        else
            if r < tmin then
                return false
            end
            if r < tmax then
                tmax = r
            end
        end
        return true
    end

    if not clip(-dx, ax + hw) then
        return
    end
    if not clip(dx, hw - ax) then
        return
    end
    if not clip(-dy, ay + hh) then
        return
    end
    if not clip(dy, hh - ay) then
        return
    end

    -- 有交点，取进入点
    local ix = ax + dx * tmin
    local iy = ay + dy * tmin

    -- 计算法线（在 rect 局部）
    local nx, ny = 0, 0
    local eps = 1e-6
    if abs(ix - hw) < eps then
        nx = 1
    elseif abs(ix + hw) < eps then
        nx = -1
    elseif abs(iy - hh) < eps then
        ny = 1
    elseif abs(iy + hh) < eps then
        ny = -1
    end

    -- 转回世界
    local cosr2, sinr2 = cos(rect.rot), sin(rect.rot)
    local wx, wy = rotate_point(ix, iy, cosr2, sinr2)
    wx = wx + rect.x
    wy = wy + rect.y

    local wnx, wny = rotate_point(nx, ny, cosr2, sinr2)

    return M.NewInfo(
            line,
            rect,
            wnx, wny,
            wx, wy,
            0 -- 线段是 0 厚度，距离恒为 0
    )
end

function M.LineEllipseCheck(line, ellipse)
    local cosr, sinr = cos(-ellipse.rot), sin(-ellipse.rot)
    local lcosr, lsinr = cos(line.rot), sin(line.rot)
    local w2 = line.w / 2
    local ax, ay = rotate_point(line.x - w2 * lcosr - ellipse.x, line.y - w2 * lsinr - ellipse.y, cosr, sinr)
    local bx, by = rotate_point(line.x + w2 * lcosr - ellipse.x, line.y + w2 * lsinr - ellipse.y, cosr, sinr)
    local nx, ny = normalize((ax + bx) / 2 / ellipse.a, (ay + by) / 2 / ellipse.b)
    local dist_unit = sqrt((ax + bx) ^ 2 / (4 * ellipse.a ^ 2) + (ay + by) ^ 2 / (4 * ellipse.b ^ 2))
    if dist_unit < 1 then
        return M.NewInfo(line, ellipse, nx, ny, ellipse.x + (ax + bx) / 2, ellipse.y + (ay + by) / 2, (1 - dist_unit) * max(ellipse.a, ellipse.b))
    end
end

function M.RectEllipseCheck(rect, ellipse)
    -- 将椭圆中心映射到矩形局部坐标
    local cosr, sinr = cos(-rect.rot), sin(-rect.rot)
    local dx, dy = rotate_point(ellipse.x - rect.x, ellipse.y - rect.y, cosr, sinr)
    local hw, hh = rect.a, rect.b
    local closest_x, closest_y = clamp(dx, -hw, hw), clamp(dy, -hh, hh)
    local nx, ny = normalize(dx - closest_x, dy - closest_y)
    local penetration = sqrt((dx - closest_x) ^ 2 + (dy - closest_y) ^ 2)
    if penetration <= max(ellipse.a, ellipse.b) then
        return M.NewInfo(rect, ellipse, nx, ny, rect.x + closest_x, rect.y + closest_y, max(ellipse.a, ellipse.b) - penetration)
    end
end

M.CheckFuncs = {
    [M.Types.Circle] = {
        [M.Types.Circle] = M.CircleCircleCheck,
        [M.Types.Line] = function(c, l)
            local info = M.LineCircleCheck(l, c)
            return info and info:reverse()
        end,
        [M.Types.Rectangle] = function(c, r)
            local info = M.RectCircleCheck(r, c)
            return info and info:reverse()
        end,
        [M.Types.Ellipse] = M.CircleEllipseCheck,
    },
    [M.Types.Line] = {
        [M.Types.Circle] = M.LineCircleCheck,
        [M.Types.Line] = M.LineLineCheck,
        [M.Types.Rectangle] = M.LineRectCheck,
        [M.Types.Ellipse] = M.LineEllipseCheck,
    },
    [M.Types.Rectangle] = {
        [M.Types.Circle] = M.RectCircleCheck,
        [M.Types.Line] = function(r, l)
            local info = M.LineRectCheck(l, r)
            return info and info:reverse()
        end,
        [M.Types.Rectangle] = M.RectRectCheck,
        [M.Types.Ellipse] = M.RectEllipseCheck,
    },
    [M.Types.Ellipse] = {
        [M.Types.Circle] = function(e, c)
            local info = M.CircleEllipseCheck(c, e)
            return info and info:reverse()
        end,
        [M.Types.Line] = function(e, l)
            local info = M.LineEllipseCheck(l, e)
            return info and info:reverse()
        end,
        [M.Types.Rectangle] = function(e, r)
            local info = M.RectEllipseCheck(r, e)
            return info and info:reverse()
        end,
        [M.Types.Ellipse] = M.EllipseEllipseCheck,
    }
}

local function GetAABB(obj)
    if obj._collider_type == M.Types.Circle then
        return obj.x - obj.a, obj.y - obj.a, obj.x + obj.a, obj.y + obj.a
    elseif obj._collider_type == M.Types.Rectangle then
        -- 旋转矩形的包围盒
        local hw, hh = obj.a, obj.b
        local cosr, sinr = cos(obj.rot), sin(obj.rot)
        local dx = abs(hw * cosr) + abs(hh * sinr)
        local dy = abs(hw * sinr) + abs(hh * cosr)
        return obj.x - dx, obj.y - dy, obj.x + dx, obj.y + dy
    elseif obj._collider_type == M.Types.Ellipse then
        -- 旋转椭圆的包围盒
        local a, b = obj.a, obj.b
        local cosr, sinr = cos(obj.rot), sin(obj.rot)
        local dx = sqrt((a * cosr) ^ 2 + (b * sinr) ^ 2)
        local dy = sqrt((a * sinr) ^ 2 + (b * cosr) ^ 2)
        return obj.x - dx, obj.y - dy, obj.x + dx, obj.y + dy
    elseif obj._collider_type == M.Types.Line then
        -- 旋转线的包围盒
        local w2 = obj.w / 2
        local cosr, sinr = cos(obj.rot), sin(obj.rot)
        local dx = abs(w2 * cosr)
        local dy = abs(w2 * sinr)
        return obj.x - dx, obj.y - dy, obj.x + dx, obj.y + dy
    end
end

function M.CheckPair(obj1, obj2)

    -- 再调用精确碰撞函数
    return M.CheckFuncs[obj1._collider_type][obj2._collider_type](obj1, obj2)
end

---@param object lstg.GameObject|Core.Collision.Collider.Base
function M.GetObjectType(object)
    if object._is_custom_collider then
        return object._collider_type
    elseif object.rect then
        return M.Types.Rectangle
    elseif object.a == object.b then
        return M.Types.Circle
    else
        return M.Types.Ellipse
    end

end

---@class Core.Collision.Collider.Base
local Base = Core.Class()
function Base:init()
    self.master = nil
    self._is_custom_collider = true
    ---与lstg.GameObject通用
    self._not_collide_in_group = false
    ---与lstg.GameObject通用
    self._is_trigger = false
    ---与lstg.GameObject通用
    self._is_kinematic = false
    self._collider_type = M.Types.None
    self._x = 0
    self._y = 0
    self._rot = 0
    self.x = 0
    self.y = 0
    self.rot = 0
    self.colli = true
end
function Base:colliderUpdate()
    if self.master then
        local rot = self.master.rot or 0
        local cosr, sinr = cos(rot), sin(rot)
        local x, y = self._x * cosr - self._y * sinr, self._x * sinr + self._y * cosr
        self.x = self.master.x + x
        self.y = self.master.y + y
        self.rot = rot + self._rot
        self.colli = self.master.colli
    end
end

---@param info Core.Collision.Info
function Base:onCollide(info)
    if self.master then
        if self.master.onCollide then
            self.master:onCollide(info)
        end
    end
end
function Base:drawCollider()

end

---@class Core.Collision.Collider.Circle : Core.Collision.Collider.Base
local Circle = Core.Class(Base)
function Circle:drawCollider()
    Core.Render.SetImageState("pure_circle", "", 200, 255, 100, 100)
    Core.Render.Image("pure_circle", self.x, self.y, 0, self.a / 125)
end
M.Circle = Circle

---@class Core.Collision.Collider.Rectangle : Core.Collision.Collider.Base
local Rectangle = Core.Class(Base)
function Rectangle:drawCollider()
    Core.Render.Draw.SetState("", 200, 100, 200, 255)
    Core.Render.Draw.Line(self.x, self.y, self.rot, self.a * 2, self.b * 2)
end
M.Rectangle = Rectangle

---@class Core.Collision.Collider.Line : Core.Collision.Collider.Base
local Line = Core.Class(Base)
function Line:drawCollider()
    Core.Render.Draw.SetState("", 200, 100, 100, 255)
    Core.Render.Draw.Line(self.x, self.y, self.rot, self.w, 1)
end
M.Line = Line

---@class Core.Collision.Collider.Ellipse : Core.Collision.Collider.Base
local Ellipse = Core.Class(Base)
function Ellipse:drawCollider()
    Core.Render.SetImageState("pure_circle", "", 200, 100, 255, 100)
    Core.Render.Image("pure_circle", self.x, self.y, 0, self.a / 125, self.b / 125)
end
M.Ellipse = Ellipse

function M.NewCircle(master, r, x, y)
    local self = Circle()
    self.master = master
    self._collider_type = M.Types.Circle
    self._x, self._y = x or 0, y or 0
    ---用这个参数是为了和底层统一
    self.a = r or 15
    self.b = self.a
    return self
end

function M.NewLine(master, w, rot, x, y)
    local self = Line()
    self.master = master
    self._collider_type = M.Types.Line
    self._x, self._y = x or 0, y or 0
    self._rot = rot or 0
    self.w = w or 100
    return self
end

function M.NewRectangle(master, w, h, rot, x, y)
    local self = Rectangle()
    self.master = master
    self._collider_type = M.Types.Rectangle
    self._x, self._y = x or 0, y or 0
    self._rot = rot or 0
    self.a = w and (w / 2) or 50
    self.b = h and (h / 2) or 50
    return self
end

function M.NewEllipse(master, a, b, rot, x, y)
    local self = Ellipse()
    self.master = master
    self._collider_type = M.Types.Ellipse
    self._x, self._y = x or 0, y or 0
    self._rot = rot or 0
    self.a = a or 10
    self.b = b or 5
    return self
end
