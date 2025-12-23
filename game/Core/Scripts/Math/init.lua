---@class Core.Math
---@field PointSet Core.Math.PointSet
---@field Vector2 Core.Math.Vector2
---@field Vector3 Core.Math.Vector3
---@field Quaternion Core.Math.Quaternion
---@field Ray2 Core.Math.Ray2
---@field Ray3 Core.Math.Ray3
---@field Plane Core.Math.Plane
---@field Matrix3 Core.Math.Matrix3
---@field Matrix4 Core.Math.Matrix4
---@field Geom Core.Math.Geom
local M = {}

---注意：为了避免性能开销，尽量减少对象化Vector, Ray, Plane等
---如果一个逻辑相对比较简单，可以考虑直接使用原始的数学计算
---Attention: To reduce the overhead of object-oriented Vector, Ray, Plane, etc..
---it is recommended to use the original mathematical calculations directly if the logic is relatively simple.
Core.Math = M

require("Core.Scripts.Math.PointSet")
require("Core.Scripts.Math.Vector")
require("Core.Scripts.Math.Quaternion")
require("Core.Scripts.Math.Ray")
require("Core.Scripts.Math.Plane")
require("Core.Scripts.Math.Matrix")
require("Core.Scripts.Math.Geom")

---@alias Core.Math.Point2 Core.Math.Vector2
---@alias Core.Math.Point3 Core.Math.Vector3
M.Point2 = M.Vector2
M.Point3 = M.Vector3

function M.Wrap(value, _min, _max)
    return (value - _min) % (_max - _min + 1) + _min
end

function M.IsReal(x)
    return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

function M.DeltaAngle(a1, a2)
    local a = (a1 - a2) % 360
    if a > 180 then
        a = a - 360
    end
    return a
end

function M.Solve3x3(a, b, c, d,
                    e, f, g, h,
                    i, j, k, l)
    local D = a * (f * k - g * j) - b * (e * k - g * i) + c * (e * j - f * i)
    if math.abs(D) < 1e-12 then
        return nil
    end

    -- Dx, Dy, Dz
    local Dx = d * (f * k - g * j) - b * (h * k - g * l) + c * (h * j - f * l)
    local Dy = a * (h * k - g * l) - d * (e * k - g * i) + c * (e * l - h * i)
    local Dz = a * (f * l - h * j) - b * (e * l - h * i) + d * (e * j - f * i)

    local x = Dx / D
    local y = Dy / D
    local z = Dz / D

    return x, y, z
end

function M.CartToPolar(x, y)
    return sqrt(x * x + y * y), atan2(y, x)
end

function M.PolarToCart(r, a)
    return r * cos(a), r * sin(a)
end

function M.Lerp(a, b, t)
    return (1 - t) * a + t * b
end

local exp = math.exp
function M.ExpInterp(a, b, k)
    return a + (b - a) * (1 - exp(-k))
end

M.Dist = lstg.Dist
M.Angle = lstg.Angle
