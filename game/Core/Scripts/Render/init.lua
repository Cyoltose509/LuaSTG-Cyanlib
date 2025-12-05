---@class Core.Render
---@field Draw Core.Render.Draw
---@field Mesh Core.Render.Mesh
---@field Skybox Core.Render.Skybox
---@field Color Core.Render.Color
---@field GPU Core.Render.GPU
---@field ScreenRT Core.Render.ScreenRT
---@field Ball Core.Render.Ball
local M = {}
Core.Render = M

require("Core.Scripts.Render.Draw")
require("Core.Scripts.Render.Mesh")
require("Core.Scripts.Render.Skybox")
require("Core.Scripts.Render.Color")
require("Core.Scripts.Render.GPU")
require("Core.Scripts.Render.ScreenRT")
require("Core.Scripts.Render.Ball")

---@class lstg.BlendMode
M.BlendMode = {
    Default = "",
    MulAlpha = "mul+alpha",
    MulAdd = "mul+add",
    MulRev = "mul+rev",
    MulSub = "mul+sub",
    AddAlpha = "add+alpha",
    AddAdd = "add+add",
    AddRev = "add+rev",
    AddSub = "add+sub",
    AlphaBal = "alpha+bal",
    MulMin = "mul+min",
    MulMax = "mul+max",
    MulMul = "mul+mul",
    MulScreen = "mul+screen",
    AddMin = "add+min",
    AddMax = "add+max",
    AddMul = "add+mul",
    AddScreen = "add+screen",
    Force = "one",
}

---@class lstg.KnownSamplerState
M.SamplerState = {
    PointWrap = "point+wrap",
    PointClamp = "point+clamp",
    LinearWrap = "linear+wrap",
    LinearClamp = "linear+clamp",
}

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

function M.TexInCircle(texname, x, y, ux, uy, radius, rot, scale, blend, color, cut)
    blend = blend or Core.Render.BlendMode.Default
    color = color or Core.Render.Color.Default
    local tex = Core.Resource.Texture.Get(texname):setBlend(blend)
    local angle
    local ang = 360 / cut / 2
    local uradius = radius / scale
    for a = 1, cut do
        angle = rot + 360 / cut * a
        tex:setUV1(x + radius * cos(angle - ang), y + radius * sin(angle - ang), 0.5,
                ux + uradius * cos(angle + ang), uy - uradius * sin(angle + ang), color)
           :setUV2(x, y, 0.5, ux, uy, color)
           :setUV3(x, y, 0.5, ux, uy, color)
           :setUV4(x + radius * cos(angle - ang), y + radius * sin(angle - ang), 0.5,
                ux + uradius * cos(angle - ang), uy - uradius * sin(angle - ang), color)
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
    paragraph = 0x00000010,

    noclip = 0x00000100,
    centerpoint = 0x00000105,
}, {
    __index = function()
        return 0
    end
})
local function buildFmt(...)
    local fmt = 0
    for _,t in ipairs({...}) do
        fmt = fmt + ENUM_TTF_FMT[t]
    end
    return fmt
end
local function simpleFmt(...)
    local halign = 0
    local valign = 0
    for _,v in ipairs({...}) do
        if v == "center" then
            halign = 1
        elseif v == "right" then
            halign = 2
        elseif v == "vcenter" then
            valign = 1
        elseif v == "bottom" then
            valign = 2
        elseif v == "centerpoint" then
            halign = 1
            valign = 1
        end
    end
    return halign, valign
end

local function getStrokePos(ix, iy, l, r, b, t, halign, valign)
    local w, h = r - l, t - b
    local x, y = ix, iy
    if halign == 0 then
        x = x - l -- 使左边缘对齐 x
    elseif halign == 1 then
        x = (x - l) - (w / 2) -- 居中
    else
        -- "right"
        x = x - r -- 使右边缘对齐 x
    end
    if valign == 0 then
        y = y - t -- 使顶边缘对齐 y
    elseif valign == 1 then
        y = (y - b) - (h / 2) -- 居中
    else
        y = y - b -- 使底边缘对齐 y
    end
    return x, y
end

function M.Font(fontname, text, x, y, size, ...)
    lstg.RenderText(fontname, text, x, y, size, buildFmt(...))
end

function M.Text(ttfname, text, x, y, scale, color, ...)
    local fmt = buildFmt(...)
    lstg.RenderTTF(ttfname, text, x, x, y, y, fmt, color, scale)
end

function M.TextInRect(ttfname, text, left, right, bottom, top, scale, color, ...)
    lstg.RenderTTF(ttfname, text, left, right, bottom, top, buildFmt(...), color, scale)
end


---绘制文本，支持对齐方式、旋转、缩放、混合模式、颜色等参数
---不支持多行渲染（可能会出问题）
---Render Text with alignment, rotation, scaling, blend mode, and color parameters
---Does not support multi-line rendering (may cause problems)
---@param ttfname string
---@param blend lstg.BlendMode
---@param color lstg.Color
function M.TextAdvanced(ttfname, text, x, y, rot, hscale, vscale, blend, color, ...)
    rot = rot or 0
    hscale = hscale or 1
    vscale = vscale or 1
    blend = blend or Core.Render.BlendMode.Default
    color = color or Core.Render.Color.Default
    local fr = lstg.FontRenderer
    fr.SetFontProvider(ttfname)
    fr.SetScale(hscale / 2, vscale / 2)

    local x0, y0 = x, y
    local l, r, b, t = fr.MeasureTextBoundary(text)
    x, y = getStrokePos(x, y, l, r, b, t, ...)

    local cos_v = cos(rot)
    local sin_v = sin(rot)
    local dx = x - x0
    local dy = y - y0
    local x1 = x0 + dx * cos_v - dy * sin_v
    local y1 = y0 + dx * sin_v + dy * cos_v

    -- 绘制

    local ret, x2, y2 = fr.RenderTextInSpace(text, x1, y1, 0.5,
            cos(rot), sin(rot), 0,
            cos(rot - 90), sin(rot - 90), 0,
            blend, color)
    assert(ret)

    return x2, y2
end

---绘制斜体文本
---用向量模拟斜体效果
---仅支持单行渲染
---Render italic text with vector simulation
---Only supports single-line rendering
function M.TextItalic(ttfname, text, x, y, size, color, ...)
    size = size or 1
    color = color or Core.Render.Color.Default

    local fr = lstg.FontRenderer
    fr.SetFontProvider(ttfname)
    fr.SetScale(size / 2, size / 2)

    local l, r, b, t = fr.MeasureTextBoundary(text)
    x, y = getStrokePos(x, y, l, r, b, t, simpleFmt(...))

    local ret, x2, y2 = fr.RenderTextInSpace(text, x, y, 0.5, 1, 0, 0, -0.1, -1, 0, "", color)
    assert(ret)
    return x2, y2

end

---绘制文本，支持最大宽度限制
---仅支持单行渲染
---Render text with maximum width limit
---Only supports single-line renderings
function M.TextMaxWidth(ttfname, text, x, y, size, maxw, color, ...)
    size = size or 1
    maxw = maxw or math.huge
    color = color or Core.Render.Color.Default

    size = size / 2
    -- 设置字体

    local fr = lstg.FontRenderer
    fr.SetFontProvider(ttfname)
    fr.SetScale(size, size)

    -- 计算笔触位置
    local l, r, b, t = fr.MeasureTextBoundary(text)
    local w = r - l
    if w > maxw then
        fr.SetScale(size * maxw / w, size)
        w = maxw
        r = l + w
    end

    x, y = getStrokePos(x, y, l, r, b, t, simpleFmt(...))

    -- 绘制
    local ret, x2, y2 = fr.RenderTextInSpace(text, x, y, 0.5, 1, 0, 0, 0, -1, 0, "", color)
    assert(ret)
    return x2, y2
end

local text_command = {
    ["d"] = function()
        return 255, 255, 255, 1, 1
    end, --default
    ["r"] = function()
        return 255, 130, 130
    end, --red
    ["b"] = function()
        return 130, 130, 255
    end, --blue
    ["c"] = function()
        return 130, 255, 255
    end, --cyan
    ["o"] = function()
        return 255, 255, 130
    end, --orange
    ["g"] = function()
        return 130, 255, 130
    end, --green
    ["y"] = function()
        return 255, 227, 132
    end, --yellow,
    ["p"] = function()
        return 255, 130, 255
    end, --purple
    ["-"] = function()
        return 150, 150, 150
    end, --gray
}
--TODO
---简单的富文本
---text内指令实现多颜色，多大小渲染一串字符，仅支持单行渲染
---使用例：§r 红色 §b 蓝色 §c 青色 §o 橙色 §g 绿色 §y 黄色 §p 紫色 §- 灰色
---Simple rich text
---The text command implements multi-color, multi-size rendering of a string, and only single-line rendering is supported.
---Example: §r red §b blue §c cyan §o orange §g green §y yellow §p purple §- gray
function M.TextRich(ttfname, format_text, x, y, size, alpha, black, ...)
    size = size * 0.5
    local fr = lstg.FontRenderer
    fr.SetFontProvider(ttfname)

    local init_R, init_G, init_B = 255, 255, 255
    if black then
        init_R, init_G, init_B = 0, 0, 0
    end
    local init_color = lstg.Color(alpha, init_R, init_G, init_B)
    local init_size = 1
    local split_str = "§"
    local strs = string.split(format_text, split_str)
    local x_off = 0
    local l, r, b, t
    local w, h
    local init_A = 1
    fr.SetScale(size * init_size, size * init_size)
    local pure_texts = {}
    for i, v in ipairs(strs) do
        if i == 1 then
            pure_texts[i] = v
        else
            pure_texts[i] = v:sub(2)
        end
    end
    l, r, b, t = fr.MeasureTextBoundary(table.concat(pure_texts, " "))
    w, h = r - l, t - b
    x, y = getStrokePos(x, y, l, r, b, t, simpleFmt(...))
    for i, text in ipairs(strs) do
        if i ~= 1 then
            local R, G, B, Ai, sizei = text_command[text:sub(1, 1)]()
            text = " " .. text:sub(2)
            if Ai then
                init_A = Ai
            end
            if sizei then
                init_size = sizei
            end
            if not black then
                if R then
                    init_R, init_G, init_B = R, G, B
                end
            end
            init_color = Color(alpha * init_A, init_R, init_G, init_B)
        end
        fr.SetScale(size * init_size, size * init_size)
        l, r = fr.MeasureTextBoundary(text)
        w = r - l
        -- 绘制
        fr.RenderTextInSpace(text, x + x_off, y, 0.5, 1, 0, 0, 0, -1, 0, "", init_color)
        x_off = x_off + w
    end
end







