---@class Core.Math.Matrix3
local Matrix3 = {}
Core.Math.Matrix3 = Matrix3
Matrix3.__index = Matrix3

---@return Core.Math.Matrix3
function Matrix3.New(a11, a12, a13, a21, a22, a23, a31, a32, a33)
    return setmetatable({
        a11, a12, a13,
        a21, a22, a23,
        a31, a32, a33
    }, Matrix3)
end

---创建单位矩阵
---Creates a new identity matrix.
function Matrix3.Identity()
    return Matrix3.New(
            1, 0, 0,
            0, 1, 0,
            0, 0, 1)
end

---创建平移矩阵
---Creates a new translation matrix.
---@param tx number
---@param ty number
function Matrix3.Translation(tx, ty)
    return Matrix3.New(
            1, 0, tx,
            0, 1, ty,
            0, 0, 1)
end

---创建缩放矩阵
---Creates a new scaling matrix.
---@param sx number
---@param sy number
function Matrix3.Scale(sx, sy)
    sy = sy or sx
    return Matrix3.New(
            sx, 0, 0,
            0, sy, 0,
            0, 0, 1)
end

---创建旋转矩阵
---Creates a new rotation matrix.
---@param deg number
function Matrix3.Rotation(deg)
    local c = cos(deg)
    local s = sin(deg)
    return Matrix3.New(
            c, -s, 0,
            s, c, 0,
            0, 0, 1)
end

---矩阵乘法 a*b
---@param b Core.Math.Matrix3
function Matrix3:mul(b)
    return Matrix3.New(
            self[1] * b[1] + self[2] * b[4] + self[3] * b[7],
            self[1] * b[2] + self[2] * b[5] + self[3] * b[8],
            self[1] * b[3] + self[2] * b[6] + self[3] * b[9],

            self[4] * b[1] + self[5] * b[4] + self[6] * b[7],
            self[4] * b[2] + self[5] * b[5] + self[6] * b[8],
            self[4] * b[3] + self[5] * b[6] + self[6] * b[9],

            self[7] * b[1] + self[8] * b[4] + self[9] * b[7],
            self[7] * b[2] + self[8] * b[5] + self[9] * b[8],
            self[7] * b[3] + self[8] * b[6] + self[9] * b[9]
    )
end
Matrix3.__mul = Matrix3.mul

-- 变换二维向量 (x, y, 1)
---@param x number
---@param y number
---@return number, number
function Matrix3:transform(x, y)
    local nx = self[1] * x + self[2] * y + self[3]
    local ny = self[4] * x + self[5] * y + self[6]
    return nx, ny
end

function Matrix3:__tostring()
    return string.format("[%.3f %.3f %.3f]\n[%.3f %.3f %.3f]\n[%.3f %.3f %.3f]",
            self[1], self[2], self[3],
            self[4], self[5], self[6],
            self[7], self[8], self[9])
end

---@class Core.Math.Matrix4
local Matrix4 = {}
Core.Math.Matrix4 = Matrix4
Matrix4.__index = Matrix4

---创建一个新的 4x4 矩阵
function Matrix4.New(
        a11, a12, a13, a14,
        a21, a22, a23, a24,
        a31, a32, a33, a34,
        a41, a42, a43, a44)
    return setmetatable({
        a11, a12, a13, a14,
        a21, a22, a23, a24,
        a31, a32, a33, a34,
        a41, a42, a43, a44
    }, Matrix4)
end

---单位矩阵
function Matrix4.Identity()
    return Matrix4.New(
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
    )
end

---平移矩阵
function Matrix4.Translation(tx, ty, tz)
    return Matrix4.New(
            1, 0, 0, tx,
            0, 1, 0, ty,
            0, 0, 1, tz,
            0, 0, 0, 1
    )
end

---缩放矩阵
function Matrix4.Scale(sx, sy, sz)
    sy = sy or sx
    sz = sz or sx
    return Matrix4.New(
            sx, 0, 0, 0,
            0, sy, 0, 0,
            0, 0, sz, 0,
            0, 0, 0, 1
    )
end

---绕 X 轴旋转
function Matrix4.RotationX(deg)
    local c, s = cos(deg), sin(deg)
    return Matrix4.New(
            1, 0, 0, 0,
            0, c, -s, 0,
            0, s, c, 0,
            0, 0, 0, 1
    )
end

---绕 Y 轴旋转
function Matrix4.RotationY(deg)
    local c, s = cos(deg), sin(deg)
    return Matrix4.New(
            c, 0, s, 0,
            0, 1, 0, 0,
            -s, 0, c, 0,
            0, 0, 0, 1
    )
end

---绕 Z 轴旋转
function Matrix4.RotationZ(deg)
    local c, s = cos(deg), sin(deg)
    return Matrix4.New(
            c, -s, 0, 0,
            s, c, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
    )
end

---矩阵乘法 a*b
---@param b Core.Math.Matrix4
function Matrix4:mul(b)
    local m = {}
    for i = 0, 3 do
        for j = 0, 3 do
            local sum = 0
            for k = 0, 3 do
                sum = sum + self[1 + i * 4 + k] * b[1 + k * 4 + j]
            end
            m[1 + i * 4 + j] = sum
        end
    end
    return setmetatable(m, Matrix4)
end
Matrix4.__mul = Matrix4.mul

---变换 3D 向量 (x, y, z, 1)
---@param x number
---@param y number
---@param z number
---@return number, number, number
function Matrix4:transform(x, y, z)
    local nx = self[1] * x + self[2] * y + self[3] * z + self[4]
    local ny = self[5] * x + self[6] * y + self[7] * z + self[8]
    local nz = self[9] * x + self[10] * y + self[11] * z + self[12]
    local nw = self[13] * x + self[14] * y + self[15] * z + self[16]
    if nw ~= 0 and nw ~= 1 then
        nx, ny, nz = nx / nw, ny / nw, nz / nw
    end
    return nx, ny, nz
end

function Matrix4:__tostring()
    return string.format(
            "[%.3f %.3f %.3f %.3f]\n[%.3f %.3f %.3f %.3f]\n[%.3f %.3f %.3f %.3f]\n[%.3f %.3f %.3f %.3f]",
            self[1], self[2], self[3], self[4],
            self[5], self[6], self[7], self[8],
            self[9], self[10], self[11], self[12],
            self[13], self[14], self[15], self[16]
    )
end


