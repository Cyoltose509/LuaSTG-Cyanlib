---@class Core.Math.Quaternion:lstg.Vector4
local Quaternion = require("lstg.Vector4")
Core.Math.Quaternion = Quaternion

Quaternion.New = Quaternion.create
Quaternion.magnitude = Quaternion.length

function Quaternion:conjugate()
    return Quaternion.New(-self.x, -self.y, -self.z, self.w)
end

function Quaternion:inverse()
    local len2 = self:length() ^ 2
    local c = self:conjugate()
    return Quaternion.New(c.x / len2, c.y / len2, c.z / len2, c.w / len2)
end

---@param axis Core.Math.Vector3
---@param angle number
function Quaternion.FromAxisAngle(axis, angle)
    local half = angle * 0.5
    local s = sin(half)
    return Quaternion.New(axis.x * s, axis.y * s, axis.z * s, cos(half))
end

---@return Core.Math.Vector3, number
function Quaternion:toAxisAngle()
    local angle = 2 * acos(self.w)
    local s = sqrt(1 - self.w * self.w)
    if s < 1e-6 then
        return Core.Math.Vector3.New(1, 0, 0), angle
    else
        return Core.Math.Vector3.New(self.x / s, self.y / s, self.z / s), angle
    end
end

---@param v Core.Math.Vector3
function Quaternion:rotateVector(v)
    local qv = Quaternion.New(v.x, v.y, v.z, 0)
    local qi =self:inverse()
    local r = self * qv * qi
    return Core.Math.Vector3.New(r.x, r.y, r.z)
end
