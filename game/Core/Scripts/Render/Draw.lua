---@class Core.Render.Draw
local M = {}
Core.Render.Draw = M

local Render4V = lstg.Render4V
local Render = lstg.Render
local RenderRect = lstg.RenderRect

local DEFAULT_TEX = "white"

---@overload fun(blend:string, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color)
---@overload fun(blend:string, a:number, r:number, g:number, b:number)
---@overload fun(blend:string, color:lstg.Color)
function M.SetState(blend, c1, c2, c3, c4)
    if not blend and not c1 then
        return
    end
    local white = Core.Resource.Image.Get(DEFAULT_TEX)
    if type(c1) == "number" then
        white:setState(blend, lstg.Color(c1, c2, c3, c4))
    else
        white:setState(blend, c1, c2, c3, c4)
    end
end

---渲染矩形
function M.Rect(left, right, bottom, top, z)
    RenderRect(DEFAULT_TEX, left, right, bottom, top, z)
end

---渲染一个纯色遮罩
---需传入一个相机
---@param camera Core.Display.Camera2D
function M.Mask(camera)
    camera = camera or Core.Display.Camera.GetCurrent()
    if camera and camera.getView then
        local v = camera:getView()
        RenderRect(DEFAULT_TEX, v.left, v.right, v.bottom, v.top)
    end
end

---渲染两点之间的连线
---可以分别指定两端的裁剪长度和宽度
---Draw a line between two points with optional cuts and widths.
---cut1 and cut2 are the lengths of the cuts at the start and end of the line.
---w1 and w2 are the widths of the line at the start and end of the line.
---@param w1 number start point width
---@param w2 number end point width
---@param cut1 number start point cut length
---@param cut2 number end point cut length
function M.Connect(x1, y1, x2, y2, w1, w2, cut1, cut2)
    cut1 = cut1 or 0
    cut2 = cut2 or 0
    w2 = w2 or w1

    local rot = atan2(y2 - y1, x2 - x1)
    local cosr, sinr = cos(rot), sin(rot)
    x1 = x1 + cut1 * cosr
    y1 = y1 + cut1 * sinr
    x2 = x2 - cut2 * cosr
    y2 = y2 - cut2 * sinr
    local len = hypot(y2 - y1, x2 - x1)
    local cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
    if w1 == w2 then
        M.Line(cx, cy, rot, len, w1)
    else
        local w1x, w1y = w1 * -sinr, w1 * cosr
        local w2x, w2y = w2 * -sinr, w2 * cosr
        M.Quad(x1 + w1x, y1 + w1y, 0.5,
                x2 + w2x, y2 + w2y, 0.5,
                x2 - w2x, y2 - w2y, 0.5,
                x1 - w1x, y1 - w1y, 0.5)
    end
end

---渲染线段
---严格来说是更自由的矩形，可以旋转
function M.Line(x, y, rot, w, h, z)
    rot = rot or 0
    w = w or 1
    h = h or w
    Render(DEFAULT_TEX, x, y, rot, w / 16, h / 16, z)
end
---渲染四边形
function M.Quad(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)
    Render4V(DEFAULT_TEX, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)
end

function M.Circle(x, y, r1, r2, point, z)
    point = point or 30
    z = z or 0.5
    local ang = (360) / point
    local angle
    for i = 1, point do
        angle = i * ang
        M.Quad(x + r2 * cos(angle - ang), y + r2 * sin(angle - ang), z,
                x + r1 * cos(angle - ang), y + r1 * sin(angle - ang), z,
                x + r1 * cos(angle), y + r1 * sin(angle), z,
                x + r2 * cos(angle), y + r2 * sin(angle), z)
    end

end

---渲染圆，扇形，环形，环扇形
function M.Sector(x, y, r1, r2, a1, a2, point, rot, z)
    rot = rot or 0
    z = z or 0.5
    local ang = (a2 - a1) / point
    local angle
    for i = 1, point do
        angle = a1 + ang * i + rot
        M.Quad(x + r2 * cos(angle - ang), y + r2 * sin(angle - ang), z,
                x + r1 * cos(angle - ang), y + r1 * sin(angle - ang), z,
                x + r1 * cos(angle), y + r1 * sin(angle), z,
                x + r2 * cos(angle), y + r2 * sin(angle), z)
    end
end

function M.RectOutline(x, y, w, h, rot, outl)
    rot = rot or 0
    outl = outl or 1
    local ox = w / 2 + outl / 2
    local oy = h / 2 + outl / 2
    M.Line(x + ox * cos(rot), y + ox * sin(rot), rot + 90, (h), outl)
    M.Line(x + oy * sin(rot), y - oy * cos(rot), rot + 180, (w + outl * 2), outl)
    M.Line(x - ox * cos(rot), y - ox * sin(rot), rot + 270, (h), outl)
    M.Line(x - oy * sin(rot), y + oy * cos(rot), rot, (w + outl * 2), outl)
end

function M.RectBrightOutline(x1, x2, y1, y2, ws, alpha, r, g, b, blend)
    blend = blend or Core.Render.BlendMode.MulAdd
    local col1 = lstg.Color(0, r, g, b)
    local col2 = lstg.Color(alpha, r, g, b)
    M.SetState(blend, col1, col1, col2, col2)
    M.Rect(x1, x2, y1, y1 + ws)
    M.Rect(x1, x2, y2, y2 - ws)
    M.SetState(blend, col2, col1, col1, col2)
    M.Rect(x1, x1 + ws, y1, y2)
    M.Rect(x2, x2 - ws, y1, y2)

end

---渲染圆角矩形
function M.RoundedRect(x1, x2, y1, y2, rr, point)
    point = point or 1

    M.Rect(x1 + rr, x2 - rr, y1, y2)
    M.Rect(x1, x1 + rr, y1 + rr, y2 - rr)
    M.Rect(x2 - rr, x2, y1 + rr, y2 - rr)
    M.Sector(x1 + rr, y2 - rr, 0, rr, 90, 180, point)
    M.Sector(x2 - rr, y2 - rr, 0, rr, 0, 90, point)
    M.Sector(x1 + rr, y1 + rr, 0, rr, 180, 270, point)
    M.Sector(x2 - rr, y1 + rr, 0, rr, 270, 360, point)
end

---渲染圆角矩形描边
function M.RoundedRectOutline(x1, x2, y1, y2, rr, outline, point)
    point = point or 1
    M.Rect(x1 + rr, x2 - rr, y1, y1 + outline)
    M.Rect(x1 + rr, x2 - rr, y2 - outline, y2)
    M.Rect(x1, x1 + outline, y1 + rr, y2 - rr)
    M.Rect(x2 - outline, x2, y1 + rr, y2 - rr)
    M.Sector(x1 + rr, y2 - rr, rr - outline, rr, 90, 180, point)
    M.Sector(x2 - rr, y2 - rr, rr - outline, rr, 0, 90, point)
    M.Sector(x1 + rr, y1 + rr, rr - outline, rr, 180, 270, point)
    M.Sector(x2 - rr, y1 + rr, rr - outline, rr, 270, 360, point)
end

---默认是横向拉伸的正六边形长框
function M.HexRect(x1, x2, y1, y2)
    local r = (y2 - y1) / SQRT3
    local _x1, _y1 = x1 - r / 2, y1
    local _x2, _y2 = x2 + r / 2, y1
    local _x3, _y3 = x2 + r, (y1 + y2) / 2
    local _x4, _y4 = x2 + r / 2, y2
    local _x5, _y5 = x1 - r / 2, y2
    local _x6, _y6 = x1 - r, (y1 + y2) / 2
    local z = 0.5
    M.Quad(_x6, _y6, z, _x1, _y1, z, _x2, _y2, z, _x3, _y3, z)
    M.Quad(_x6, _y6, z, _x5, _y5, z, _x4, _y4, z, _x3, _y3, z)
end

local pos_map = {
    { 3, 4, 3, 4 },
    { 3, 4, 1, 2 },
    { 1, 2, 1, 2 },
    { 1, 2, 1, 2, },
    { 1, 2, 3, 4 },
    { 3, 4, 3, 4 },
}
local center = { 0, 0, 0, 0 }
local SQRT3 = math.sqrt(3)
function M.HexRectOutline(x1, x2, y1, y2, outline)
    local ang = 360 / 6
    local angle
    local r2 = (y2 - y1) / SQRT3
    local r1 = r2 - outline
    center[1], center[2], center[3], center[4] = x1, (y1 + y2) / 2, x2, (y1 + y2) / 2
    for i = 1, 6 do
        angle = ang * i
        M.Quad(center[pos_map[i][1]] + r2 * cos(angle - ang), center[pos_map[i][2]] + r2 * sin(angle - ang), 0.5,
                center[pos_map[i][1]] + r1 * cos(angle - ang), center[pos_map[i][2]] + r1 * sin(angle - ang), 0.5,
                center[pos_map[i][3]] + r1 * cos(angle), center[pos_map[i][4]] + r1 * sin(angle), 0.5,
                center[pos_map[i][3]] + r2 * cos(angle), center[pos_map[i][4]] + r2 * sin(angle), 0.5)
    end
end

---@angle number@底和腰的夹角
---@rotation number@整个旋转角度
function M.Parallelogram(cx, cy, length, waist, angle, rotation)
    rotation = rotation or 0
    local z = 0.5
    local ca, sa = cos(angle), sin(angle)
    local cr, sr = cos(rotation), sin(rotation)
    local x1, y1 = 0, 0
    local x2, y2 = ca * waist, sa * waist
    local x3, y3 = length + x2, y2
    local x4, y4 = length + x1, y1
    x1, y1 = cx, cy
    x2, y2 = cx + cr * x2 - sr * y2, cy + sr * x2 + cr * y2
    x3, y3 = cx + cr * x3 - sr * y3, cy + sr * x3 + cr * y3
    x4, y4 = cx + cr * x4 - sr * y4, cy + sr * x4 + cr * y4
    M.Quad(x1, y1, z, x2, y2, z, x3, y3, z, x4, y4, z)
end

function M.ParallelogramOutline(cx, cy, length, waist, angle, outline, rotation)
    rotation = rotation or 0
    outline = min(length, waist, outline)

    local ca, sa = cos(angle), sin(angle)
    local cr, sr = cos(rotation), sin(rotation)
    local _waist = outline / abs(sa)
    local x1, y1 = 0, 0
    local x2, y2 = ca * outline, sa * outline
    local x3, y3 = ca * waist, sa * waist
    local x4, y4 = ca * outline + length - outline, sa * outline
    x1, y1 = cx, cy
    x2, y2 = cx + cr * x2 - sr * y2, cy + sr * x2 + cr * y2
    x3, y3 = cx + cr * x3 - sr * y3, cy + sr * x3 + cr * y3
    x4, y4 = cx + cr * x4 - sr * y4, cy + sr * x4 + cr * y4
    M.Parallelogram(x1, y1, length, _waist, angle, rotation)
    M.Parallelogram(x2, y2, _waist, waist - outline * 2, angle, rotation)
    M.Parallelogram(x3, y3, length, _waist, angle + 180, rotation)
    M.Parallelogram(x4, y4, _waist, waist - outline * 2, angle, rotation)
end




