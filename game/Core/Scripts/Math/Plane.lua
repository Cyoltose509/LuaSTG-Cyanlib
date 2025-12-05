---@class Core.Math.Plane
---@field point Core.Math.Point3
---@field normal Core.Math.Vector3
local Plane = {}
Plane.__index = Plane
Core.Math.Plane = Plane

---@param point Core.Math.Point3
---@param normal Core.Math.Vector3
function Plane.New(point, normal)
    assert(normal:length() > 0, "Plane normal cannot be zero")
    normal = normal:normalize()
    return setmetatable({
        point = point,
        normal = normal,
    }, Plane)
end

---计算点到平面的距离（有符号）
---Calculate the signed distance between a point and a plane.
---@param p Core.Math.Point3
function Plane:pointDistance(p)
    local v = p - self.point
    return v:dot(self.normal)
end
---射线和平面求交
---Calculate the intersection point of a ray and a plane.
---@param ray Core.Math.Ray3 @射线
---@return Core.Math.Point3|nil
function Plane:intersectRay(ray)
    local denom = ray.direction:dot(self.normal)
    if math.abs(denom) < 1e-8 then
        return nil
    end
    local t = (self.point - ray.origin):dot(self.normal) / denom
    if t < 0 then
        return nil
    end
    return ray:pointAt(t)
end

