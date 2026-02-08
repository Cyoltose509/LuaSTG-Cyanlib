---@class Core.Render.Utils
local M = {}
Core.Render.Utils = M

M.Image = lstg.Render
M.QuadImage = lstg.Render4V
M.RenderTarget = lstg.RenderTexture
M.Texture = lstg.RenderTexture
M.Animation = lstg.RenderAnimation
M.BeginScene = lstg.BeginScene
M.EndScene = lstg.EndScene

function M.RectImage(imgname, left, right, bottom, top, z)
    lstg.RenderRect(imgname, left, right, bottom, top, z)
end

---@overload fun(image:string, blend:string, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color)
---@overload fun(image:string, blend:string, a:number, r:number, g:number, b:number)
---@overload fun(image:string, blend:string, color:lstg.Color)
function M.SetImageState(image, blend, c1, c2, c3, c4)
    local img = Core.Resource.Image.Get(image)
    assert(img, "Image not found: " .. image)
    if type(c1) == "number" then
        img:setState(blend, lstg.Color(c1, c2, c3, c4))
    else
        img:setState(blend, c1, c2, c3, c4)
    end
end

---@overload fun(animation:string, blend:string, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color)
---@overload fun(animation:string, blend:string, a:number, r:number, g:number, b:number)
---@overload fun(animation:string, blend:string, color:lstg.Color)
function M.SetAnimationState(animation, blend, c1, c2, c3, c4)
    local ani = Core.Resource.Animation.Get(animation)
    assert(ani, "Animation not found: " .. animation)
    if type(c1) == "number" then
        ani:setState(blend, lstg.Color(c1, c2, c3, c4))
    else
        ani:setState(blend, c1, c2, c3, c4)
    end
end

---@overload fun(font:string, blend:string, a:number, r:number, g:number, b:number)
---@overload fun(font:string, blend:string, color:lstg.Color)
function M.SetFontState(font, blend, a, r, g, b)
    local fnt = Core.Resource.Font.Get(font)
    assert(fnt, "Font not found: " .. font)
    if type(a) == "number" then
        fnt:setState(blend, lstg.Color(a, r, g, b))
    else
        fnt:setState(blend, a)
    end
end

---图片组渲染成环状
function M.ImageGroupRing(img, x, y, r1, r2, rot, n, maximgs)
    local da = 360 / n
    local a
    for i = 1, n do
        a = rot - da * i
        M.QuadImage(img .. ((i - 1) % maximgs + 1),
                r1 * cos(a + da) + x, r1 * sin(a + da) + y, 0.5,
                r2 * cos(a + da) + x, r2 * sin(a + da) + y, 0.5,
                r2 * cos(a) + x, r2 * sin(a) + y, 0.5,
                r1 * cos(a) + x, r1 * sin(a) + y, 0.5)
    end
end

---描点连线
---@param img string
---@param line table@由obj组成的一个数组
---@param width number@线条宽度
---@param close boolean@封闭
function M.ImagePolyline(img, line, width, close)
    local n = #line
    if n < 2 then
        return
    end

    local z = 0.5
    local hw = width * 0.5

    local function get_tangent(i)
        local p_prev = line[max(1, i - 1)]
        local p_next = line[min(n, i + 1)]
        local dx = p_next.x - p_prev.x
        local dy = p_next.y - p_prev.y
        local len = sqrt(dx * dx + dy * dy)
        if len == 0 then
            return 0, 1
        end
        return dx / len, dy / len
    end
    for i = 1, n - 1 do
        local p1 = line[i]
        local p2 = line[i + 1]

        local tx1, ty1 = get_tangent(i)
        local tx2, ty2 = get_tangent(i + 1)

        local nx1, ny1 = -ty1, tx1
        local nx2, ny2 = -ty2, tx2

        local x1l = p1.x - nx1 * hw
        local y1l = p1.y - ny1 * hw
        local x1r = p1.x + nx1 * hw
        local y1r = p1.y + ny1 * hw
        local x2l = p2.x - nx2 * hw
        local y2l = p2.y - ny2 * hw
        local x2r = p2.x + nx2 * hw
        local y2r = p2.y + ny2 * hw
        M.QuadImage(img, x1l, y1l, z, x1r, y1r, z, x2r, y2r, z, x2l, y2l, z)
    end
    if close then
        M.ImagePolyline(img, { line[#line], line[1] }, width, false)
    end
end

---单点扩散渲染
---@param count number@一圈的图片数
---@param color lstg.Color@圆心颜色或整体颜色
---@param color2 lstg.Color@扩散颜色
function M.TexDiffuseCircle(texname, x, y, r1, r2, rot, n, count, spread, blend, color, color2)
    blend = blend or Core.Render.BlendMode.Default
    color = color or Core.Render.Color.Default
    color2 = color2 or color
    local tex = Core.Resource.Texture.Get(texname):setBlend(blend)
    local texl = tex:getSize()
    local da = 360 / n
    local h = 0
    local _h = texl / n * count
    local height = r2 - r1
    for _ = 1, n do
        tex:setUV1(x + r1 * cos(rot), y + r1 * sin(rot), 0.5, h, spread, color)
           :setUV2(x + r1 * cos(rot - da), y + r1 * sin(rot - da), 0.5, h + _h, spread, color)
           :setUV3(x + r2 * cos(rot - da), y + r2 * sin(rot - da), 0.5, h + _h, spread + height, color2)
           :setUV4(x + r2 * cos(rot), y + r2 * sin(rot), 0.5, h, spread + height, color2)
           :draw()
        rot = rot - da
        h = h + _h
    end
end

---用纹理以Render的形式渲染
function M.TexLikeImage(texname, x, y, rot, hscale, vscale, blend, color)
    blend = blend or Core.Render.BlendMode.Default
    color = color or Core.Render.Color.Default
    local tex = Core.Resource.Texture.Get(texname):setBlend(blend)
    local w, h = tex:getSize()
    local cosr, sinr = cos(rot), sin(rot)
    local _w, _h = w * hscale / 2, h * vscale / 2
    tex:setUV1(x - cosr * _w - sinr * _h, y + cosr * _h - sinr * _w, 0.5, 0, 0, color)
       :setUV2(x + cosr * _w - sinr * _h, y + cosr * _h + sinr * _w, 0.5, w, 0, color)
       :setUV3(x + cosr * _w + sinr * _h, y - cosr * _h + sinr * _w, 0.5, w, h, color)
       :setUV4(x - cosr * _w + sinr * _h, y - cosr * _h - sinr * _w, 0.5, 0, h, color)
       :draw()
end

function M.TexInChamferRect(texname, blend, color, l, r, b, t, rr, size, offx, offy)
    blend = blend or Core.Render.BlendMode.Default
    color = color or Core.Render.Color.Default
    local tex = Core.Resource.Texture.Get(texname):setBlend(blend)
    local tw, th = tex:getSize()
    offx = offx or (tw / 2)
    offy = offy or (th / 2)
    size = size or 1
    local w = (r - l) / size / 2
    local h = (t - b) / size / 2
    local _rr = rr / size
    tex:setUV1(l + rr, t, 0.5, offx - w + _rr, offy - h, color)
       :setUV2(r - rr, t, 0.5, offx + w - _rr, offy - h, color)
       :setUV3(r - rr, b, 0.5, offx + w - _rr, offy + h, color)
       :setUV4(l + rr, b, 0.5, offx - w + _rr, offy + h, color)
       :draw()
       :setUV1(l, t - rr, 0.5, offx - w, offy - h + _rr)
       :setUV2(l + rr, t, 0.5, offx - w + _rr, offy - h)
       :setUV3(l + rr, b, 0.5, offx - w + _rr, offy + h)
       :setUV4(l, b + rr, 0.5, offx - w, offy + h - _rr)
       :draw()
       :setUV1(r - rr, t, 0.5, offx + w - _rr, offy - h)
       :setUV2(r, t - rr, 0.5, offx + w, offy - h + _rr)
       :setUV3(r, b + rr, 0.5, offx + w, offy + h - _rr)
       :setUV4(r - rr, b, 0.5, offx + w - _rr, offy + h)
       :draw()

end

function M.TexInCircle(texname, x, y, radius, rot, scale, cut, blend, color, offx, offy, offrot)
    blend = blend or Core.Render.BlendMode.Default
    color = color or Core.Render.Color.Default
    cut = cut or 10
    local tex = Core.Resource.Texture.Get(texname):setBlend(blend)
    local tw, th = tex:getSize()
    offx = (offx or 0) / scale + tw / 2
    offy = -(offy or 0) / scale + th / 2
    offrot = offrot or 0

    local angle
    local ang = 360 / cut
    local uradius = radius / scale

    for a = 1, cut do
        angle = offrot + 360 / cut * a
        tex:setUV1(x + radius * cos(angle - ang), y + radius * sin(angle - ang), 0.5,
                offx + uradius * cos(rot + angle - ang), offy - uradius * sin(rot + angle - ang), color)
           :setUV2(x, y, 0.5, offx, offy, color)
           :setUV3(x, y, 0.5, offx, offy, color)
           :setUV4(x + radius * cos(angle), y + radius * sin(angle), 0.5,
                offx + uradius * cos(rot + angle), offy - uradius * sin(rot + angle), color)
           :draw()
    end
end

local ENUM_TTF_FMT = setmetatable({
    left = 0x00000000,
    center = 0x00000001,
    right = 0x00000002,

    top = 0x00000000,
    vcenter = 0x00000004,
    bottom = 0x00000008,

    wordbreak = 0x00000010,

    centerpoint = 0x00000105,
}, {
    __index = function()
        return 0
    end
})
local function buildFmt(...)
    local fmt = 0
    for _, t in ipairs({ ... }) do
        fmt = fmt + ENUM_TTF_FMT[t]
    end
    return fmt
end

function M.Font(fontname, text, x, y, size, ...)
    lstg.RenderText(fontname, text, x, y, size, buildFmt(...))
end

function M.TextSimple(ttfname, text, x, y, scale, color, ...)
    local fmt = buildFmt(...)
    lstg.RenderTTF(ttfname, text, x, x, y, y, fmt, color, scale)
end








