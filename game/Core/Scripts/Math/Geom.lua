---@class Core.Math.Geom
local M = {}
Core.Math.Geom = M

function M.PointInRect(px, py, x1, x2, y1, y2)
    if x1 > x2 then
        x1, x2 = x2, x1
    end
    if y1 > y2 then
        y1, y2 = y2, y1
    end
    return px >= x1 and px <= x2 and py >= y1 and py <= y2
end

function M.PerspectiveProjection(x, y, z, x0, y0, z0, zp, fovy)
    -- Calculate the scaling factor based on depth (z distance from the viewpoint)
    fovy = fovy or 1
    local t = (zp - z0) / (z - z0) * sign(z - z0) / fovy
    --if z <= z0 then
    -- t = -99999999999999
    -- end
    -- Compute the projected coordinates on the plane z = zp
    local x_proj = x0 + (x - x0) * t
    local y_proj = y0 + (y - y0) * t

    return -x_proj, -y_proj, zp

end

function M.InversePerspectiveProjection(x_proj, y_proj, zp, x0, y0, z0, z)
    -- Calculate the inverse scaling factor based on depth (z distance from the viewpoint)
    local t_inv = (z - z0) / (zp - z0)

    -- Compute the original coordinates (x, y) in 3D space
    local x = x0 + (x_proj - x0) * t_inv
    local y = y0 + (y_proj - y0) * t_inv

    return x, y, z
end

function M.PointOnSegment(mp, p1, p2, offset)
    local x1, y1 = p1.x, p1.y
    local x2, y2 = p2.x, p2.y
    local x0, y0 = mp.x, mp.y
    -- 计算线段的长度平方
    local dx, dy = x2 - x1, y2 - y1
    local lengthSquared = dx * dx + dy * dy
    --[[
    -- 特殊情况：线段长度为0
    if lengthSquared == 0 then
        -- 直接计算点到起点的距离
        return Dist(mp, p1) <= offset
    end--]]
    -- 计算点到线段的投影
    local t = ((x0 - x1) * dx + (y0 - y1) * dy) / lengthSquared
    -- 限制t在区间[0, 1]
    t = clamp(t, 0, 1)
    -- 计算最近点的坐标
    local closestX = x1 + t * dx
    local closestY = y1 + t * dy
    -- 计算点到该投影点的距离
    local distance = hypot(x0 - closestX, y0 - closestY)--Dist(mp, { x = closestX, y = closestY })
    -- 检查距离是否在误差范围内
    return distance <= offset
end

local SQRT3 = sqrt(3)
---判断点是否在正六边形内
function M.PointInHexagon(px, py, cx, cy, a)
    local dx = abs(px - cx)
    local dy = abs(py - cy)
    if dy > SQRT3 / 2 * a then
        return false
    end
    if dx > a then
        return false
    end
    if SQRT3 * dx + dy > SQRT3 * a then
        return false
    end
    return true
end

---输入矩形参数
---返回矩形4个顶点的坐标
---Input rect parameters
---Return the coordinates of the four corners of the rectangle
---@param rotateCenter boolean 是否旋转中心 whether to rotate the center
---@return number[]
function M.GetRectPoints(cx, cy, w, h, angle, rotateCenter)
    local cosr, sinr = cos(angle), sin(angle)
    if rotateCenter then
        cx, cy = cx * cosr - cy * sinr, cx * sinr + cy * cosr
    end
    local w2, h2 = w / 2, h / 2
    return { cx - w2 * cosr - h2 * sinr, cy + h2 * cosr - w2 * sinr,
             cx + w2 * cosr - h2 * sinr, cy + h2 * cosr + w2 * sinr,
             cx + w2 * cosr + h2 * sinr, cy - h2 * cosr + w2 * sinr,
             cx - w2 * cosr + h2 * sinr, cy - h2 * cosr - w2 * sinr }
end

---旋转四边形
---Rotate a quadrilateral
---@param rotateCenter boolean 是否旋转中心 whether to rotate the center
function M.RotateQuad(cx, cy, x1, y1, x2, y2, x3, y3, x4, y4, angle, rotateCenter)
    local cosr, sinr = cos(angle), sin(angle)
    if rotateCenter then
        cx, cy = cx * cosr - cy * sinr, cx * sinr + cy * cosr
    end
    return {
        cx + x1 * cosr - y1 * sinr, cy + x1 * sinr + y1 * cosr,
        cx + x2 * cosr - y2 * sinr, cy + x2 * sinr + y2 * cosr,
        cx + x3 * cosr - y3 * sinr, cy + x3 * sinr + y3 * cosr,
        cx + x4 * cosr - y4 * sinr, cy + x4 * sinr + y4 * cosr
    }
end




