---@class Core.Render.Draw
local M = {}
Core.Render.Draw = M

local Render4V = lstg.Render4V
local Render = lstg.Render
local RenderRect = lstg.RenderRect
local cos, sin = cos, sin
local atan2 = atan2
local hypot = hypot
local Color = lstg.Color
local type = type
local DEFAULT_TEX = "white"
local number = "number"
local TMP_COLOR = Color(0, 0, 0, 0)
local SetImageState = lstg.SetImageState

---@overload fun(blend:string, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color)
---@overload fun(blend:string, a:number, r:number, g:number, b:number)
---@overload fun(blend:string, color:lstg.Color)
function M.SetState(blend, c1, c2, c3, c4)
    if not blend and not c1 then
        return
    end
    if type(c1) == number then
        TMP_COLOR.a = c1
        TMP_COLOR.r = c2
        TMP_COLOR.g = c3
        TMP_COLOR.b = c4
        SetImageState(DEFAULT_TEX, blend, TMP_COLOR)
    elseif c2 then
        SetImageState(DEFAULT_TEX, blend, c1, c2, c3, c4)
    else
        SetImageState(DEFAULT_TEX, blend, c1)
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
    local cx, cy = (x1 + x2) * 0.5, (y1 + y2) * 0.5
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
    Render(DEFAULT_TEX, x, y, rot, w * 0.0625, h * 0.0625, z)
end
---渲染四边形
function M.Quad(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)
    Render4V(DEFAULT_TEX, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4)
end

function M.Circle(x, y, r1, r2, point, rotation, z)
    point = point or 30
    rotation = rotation or 0
    z = z or 0.5
    local ang = (360) / point
    local angle
    for i = 1, point do
        angle = i * ang + rotation
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
    local ox = w * 0.5 + outl * 0.5
    local oy = h * 0.5 + outl * 0.5
    local cosr=cos(rot)
    local sinr=sin(rot)
    M.Line(x + ox * cosr, y + ox * sinr, rot + 90, h, outl)
    M.Line(x + oy * sinr, y - oy * cosr, rot, w + outl * 2, outl)
    M.Line(x - ox * cosr, y - ox * sinr, rot, h, outl)
    M.Line(x - oy * sinr, y + oy * cosr, rot, w + outl * 2, outl)
end

function M.RectBrightOutline(x1, x2, y1, y2, ws, alpha, r, g, b, blend)
    blend = blend or Core.Render.BlendMode.MulAdd
    local col1 = Color(0, r, g, b)
    local col2 = Color(alpha, r, g, b)
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

local HALF = 0.5
local SIN60 = 0.8660254037844386
local INV_SQRT3 = 0.5773502691896257

---横向拉伸的正六边形
function M.HorizontalHex(x1, x2, y1, y2)
    local r = (y2 - y1) * INV_SQRT3
    local bx1, bx2, bx3, bx4 = x1, x1 + r * HALF, x2 - r * HALF, x2
    local by1, by2, by3 = y1, (y1 + y2) * HALF, y2
    local z = 0.5
    M.Quad(bx1, by2, z, bx2, by1, z, bx3, by1, z, bx4, by2, z)
    M.Quad(bx1, by2, z, bx2, by3, z, bx3, by3, z, bx4, by2, z)
end
function M.VerticalHex(x1, x2, y1, y2)
    local r = (x2 - x1) * INV_SQRT3
    local by1, by2, by3, by4 = y1, y1 + r * HALF, y2 - r * HALF, y2
    local bx1, bx2, bx3 = x1, (x1 + x2) * HALF, x2
    local z = 0.5
    M.Quad(bx2, by1, z, bx1, by2, z, bx1, by3, z, bx2, by4, z)
    M.Quad(bx2, by1, z, bx3, by2, z, bx3, by3, z, bx2, by4, z)

end

function M.HorizontalHexOutline(x1, x2, y1, y2, outline)
    local r2 = (y2 - y1) * INV_SQRT3
    local r1 = r2 - outline
    local z = 0.5
    local cx1, cy1, cx2, cy2 = x1 + r2, (y1 + y2) * HALF, x2 - r2, (y1 + y2) * HALF
    M.Quad(cx2 + r2, cy2, z,
            cx2 + r1, cy2, z,
            cx2 + r1 * HALF, cy2 + r1 * SIN60, z,
            cx2 + r2 * HALF, cy2 + r2 * SIN60, z)
    M.Quad(cx2 + r2 * HALF, cy2 + r2 * SIN60, z,
            cx2 + r1 * HALF, cy2 + r1 * SIN60, z,
            cx1 - r1 * HALF, cy1 + r1 * SIN60, z,
            cx1 - r2 * HALF, cy1 + r2 * SIN60, z)
    M.Quad(cx1 - r2 * HALF, cy1 + r2 * SIN60, z,
            cx1 - r1 * HALF, cy1 + r1 * SIN60, z,
            cx1 - r1, cy1, z,
            cx1 - r2, cy1, z)
    M.Quad(cx1 - r2, cy1, z,
            cx1 - r1, cy1, z,
            cx1 - r1 * HALF, cy1 - r1 * SIN60, z,
            cx1 - r2 * HALF, cy1 - r2 * SIN60, z)
    M.Quad(cx1 - r2 * HALF, cy1 - r2 * SIN60, z,
            cx1 - r1 * HALF, cy1 - r1 * SIN60, z,
            cx2 + r1 * HALF, cy2 - r1 * SIN60, z,
            cx2 + r2 * HALF, cy2 - r2 * SIN60, z)
    M.Quad(cx2 + r2 * HALF, cy2 - r2 * SIN60, z,
            cx2 + r1 * HALF, cy2 - r1 * SIN60, z,
            cx2 + r1, cy2, z,
            cx2 + r2, cy2, z)
end
function M.VerticalHexOutline(x1, x2, y1, y2, outline)
    local r2 = (x2 - x1) * INV_SQRT3
    local r1 = r2 - outline
    local z = 0.5
    local cx1, cy1, cx2, cy2 = (x1 + x2) * HALF, y1 + r2, (x1 + x2) * HALF, y2 - r2
    M.Quad(cx2, cy2 + r2, z,
            cx2, cy2 + r1, z,
            cx2 - r1 * SIN60, cy2 + r1 * HALF, z,
            cx2 - r2 * SIN60, cy2 + r2 * HALF, z)
    M.Quad(cx2 - r2 * SIN60, cy2 + r2 * HALF, z,
            cx2 - r1 * SIN60, cy2 + r1 * HALF, z,
            cx1 - r1 * SIN60, cy1 - r1 * HALF, z,
            cx1 - r2 * SIN60, cy1 - r2 * HALF, z)
    M.Quad(cx1 - r2 * SIN60, cy1 - r2 * HALF, z,
            cx1 - r1 * SIN60, cy1 - r1 * HALF, z,
            cx1, cy1 - r1, z,
            cx1, cy1 - r2, z)
    M.Quad(cx1, cy1 - r2, z,
            cx1, cy1 - r1, z,
            cx1 + r1 * SIN60, cy1 - r1 * HALF, z,
            cx1 + r2 * SIN60, cy1 - r2 * HALF, z)
    M.Quad(cx1 + r2 * SIN60, cy1 - r2 * HALF, z,
            cx1 + r1 * SIN60, cy1 - r1 * HALF, z,
            cx2 + r1 * SIN60, cy2 + r1 * HALF, z,
            cx2 + r2 * SIN60, cy2 + r2 * HALF, z)
    M.Quad(cx2 + r2 * SIN60, cy2 + r2 * HALF, z,
            cx2 + r1 * SIN60, cy2 + r1 * HALF, z,
            cx2, cy2 + r1, z,
            cx2, cy2 + r2, z)
end



