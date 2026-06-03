---@class Core.Math.Ray2
---@field origin Core.Math.Point2
---@field direction Core.Math.Vector2
local Ray2 = {}
Ray2.__index = Ray2
Core.Math.Ray2 = Ray2

---@param origin Core.Math.Point2
---@param direction Core.Math.Vector2
function Ray2.New(origin, direction)
    return setmetatable({ origin = origin, direction = direction:normalized() }, Ray2)
end

---@param t number
---@return Core.Math.Point2
function Ray2:pointAt(t)
    return self.origin + self.direction * t
end

---@class Core.Math.Ray3
---@field origin Core.Math.Point3
---@field direction Core.Math.Vector3
local Ray3 = {}
Ray3.__index = Ray3
Core.Math.Ray3 = Ray3

---@param origin Core.Math.Point3
---@param direction Core.Math.Vector3
function Ray3.New(origin, direction)
    return setmetatable({ origin = origin, direction = direction:normalized() }, Ray3)
end

---传入参数t，返回射线在t时刻的点
---Returns the point on the ray at time t.
---@param t number
---@return Core.Math.Point3
function Ray3:pointAt(t)
    return self.origin + self.direction * t
end

---射线与平面求交
---Returns the intersection point of the ray and the plane.
---@param plane Core.Math.Plane
function Ray3:intersectPlane(plane)
    local denom = self.direction:dot(plane.normal)
    if math.abs(denom) < 1e-8 then
        return nil
    end
    local t = (plane.point - self.origin):dot(plane.normal) / denom
    if t < 0 then
        return nil
    end
    return self:pointAt(t)
end

