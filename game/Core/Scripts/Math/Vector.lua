---@class Core.Math.Vector2:lstg.Vector2
local Vector2 = require("lstg.Vector2")
Core.Math.Vector2 = Vector2
Vector2.New = Vector2.create
Vector2.magnitude = Vector2.length
Vector2.zero = Vector2.New(0, 0)
Vector2.one = Vector2.New(1, 1)
Vector2.up = Vector2.New(0, 1)
Vector2.down = Vector2.New(0, -1)
Vector2.left = Vector2.New(-1, 0)
Vector2.right = Vector2.New(1, 0)

function Vector2:abs()
    return Vector2.New(abs(self.x), abs(self.y))
end

function Vector2.Max(vec1, vec2)
    return (vec1 + vec2 + (vec1-vec2):abs()) * 0.5
end
function Vector2.Min(vec1, vec2)
    return (vec1 - vec2 + (vec1-vec2):abs()) * 0.5
end

---@class Core.Math.Vector3:lstg.Vector3
local Vector3 = require("lstg.Vector3")
Core.Math.Vector3 = Vector3

Vector3.New = Vector3.create
Vector3.magnitude = Vector3.length
Vector3.zero = Vector3.New(0, 0, 0)
Vector3.one = Vector3.New(1, 1, 1)
Vector3.up = Vector3.New(0, 1, 0)
Vector3.down = Vector3.New(0, -1, 0)
Vector3.left = Vector3.New(-1, 0, 0)
Vector3.right = Vector3.New(1, 0, 0)
Vector3.forward = Vector3.New(0, 0, 1)
Vector3.back = Vector3.New(0, 0, -1)


