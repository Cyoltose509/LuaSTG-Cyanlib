---@class Core.Effect.Post
local M = {}
Core.Effect.Post = M

local Render = Core.Render
local rand = Core.Effect.rand

local colsRGB = {
    Render.Color.Red,
    Render.Color.Green,
    Render.Color.Blue,
}

---@alias Core.Effect.Post.Func fun(rtName:string, x0:number, y0:number, scale:number)

---获得一个Glitch特效的函数形式
---每调用一次生成一个静态效果，若需要动态Glitch则需多次调用
---可用于RenderTarget的后处理特效
---Return a function that generates a static Glitch effect, which can be called multiple times to generate dynamic Glitch.
---It can be used as a post-processing effect for RenderTarget.
---@param strength number 错位强度
---@param prob number 错位概率
---@param cut number 纹理切割数量
---@param departRGB number RGB分离值，默认为0
---@param vertical boolean 是否纵向，false为横向
---@return Core.Effect.Post.Func
function M.Glitch(strength, prob, cut, departRGB, vertical)
    local offcache = {}
    local departrgbcache = {}
    for _ = 1, cut do
        local off = rand:sign() * rand:float(0.5, 1) * strength
        local flag = rand:prob(prob)
        table.insert(offcache, { (flag and off * rand:float(-1, 1) or 0), (flag and off or 0) })
    end
    departRGB = departRGB or 0
    for _ = 1, cut do
        table.insert(departrgbcache, rand:float(-departRGB, departRGB))
    end
    vertical = vertical or false

    local color = Render.Color.White
    return function(rtName, x0, y0, scale)
        local rt = Core.Resource.RenderTarget.Get(rtName)
        if not rt then
            return
        end
        x0 = x0 or 0
        y0 = y0 or 0
        scale = scale or 1

        local w, h = rt:getSize()
        local sw, sh = w * scale, h * scale
        if vertical then
            local _w = sw / cut
            local k = (cut - 1) / 2
            for x = -k, k do
                local floatx = offcache[x + k + 1][2]
                local oy = offcache[x + k + 1][1]
                local tx = (x * _w + floatx + sw / 2) % sw - sw / 2
                local _x1 = (sw / 2 - _w / 2 + tx) / scale
                local _x2 = (sw / 2 + _w / 2 + tx) / scale
                if departrgbcache[x + k + 1] ~= 0 then
                    local departy = departrgbcache[x + k + 1]
                    for y = -1, 1 do
                        local _color = colsRGB[y + 2]
                        rt:setUV1(x0 + sw / 2 + x * _w - _w / 2, y0 + sh + y * departy + oy, 0.5, _x1, 0, _color)
                          :setUV2(x0 + sw / 2 + x * _w + _w / 2, y0 + sh + y * departy + oy, 0.5, _x2, 0, _color)
                          :setUV3(x0 + sw / 2 + x * _w + _w / 2, y0 + 0 + y * departy + oy, 0.5, _x2, h, _color)
                          :setUV4(x0 + sw / 2 + x * _w - _w / 2, y0 + 0 + y * departy + oy, 0.5, _x1, h, _color)
                          :setBlend(Render.BlendMode.MulAdd):draw()
                    end
                else
                    rt:setUV1(x0 + sw / 2 + x * _w - _w / 2, y0 + sh + oy, 0.5, _x1, 0, color)
                      :setUV2(x0 + sw / 2 + x * _w + _w / 2, y0 + sh + oy, 0.5, _x2, 0, color)
                      :setUV3(x0 + sw / 2 + x * _w + _w / 2, y0 + 0 + oy, 0.5, _x2, h, color)
                      :setUV4(x0 + sw / 2 + x * _w - _w / 2, y0 + 0 + oy, 0.5, _x1, h, color)
                      :setBlend(Render.BlendMode.Default):draw()
                end
            end
        else
            local _h = sh / cut
            local k = (cut - 1) / 2
            for y = -k, k do
                local floaty = offcache[y + k + 1][2]
                local ox = offcache[y + k + 1][1]
                local ty = (y * _h + floaty + sh / 2) % sh - sh / 2
                local _y1 = h - (sh / 2 + _h / 2 + ty) / scale
                local _y2 = h - (sh / 2 - _h / 2 + ty) / scale
                if departrgbcache[y + k + 1] ~= 0 then
                    local departx = departrgbcache[y + k + 1]
                    for x = -1, 1 do
                        local _color = colsRGB[x + 2]
                        rt:setUV1(x0 + 0 + x * departx + ox, y0 + sh / 2 + y * _h + _h / 2, 0.5, 0, _y1, _color)
                          :setUV2(x0 + sw + x * departx + ox, y0 + sh / 2 + y * _h + _h / 2, 0.5, w, _y1, _color)
                          :setUV3(x0 + sw + x * departx + ox, y0 + sh / 2 + y * _h - _h / 2, 0.5, w, _y2, _color)
                          :setUV4(x0 + 0 + x * departx + ox, y0 + sh / 2 + y * _h - _h / 2, 0.5, 0, _y2, _color)
                          :setBlend(Render.BlendMode.MulAdd):draw()
                    end
                else
                    rt:setUV1(x0 + 0, y0 + sh / 2 + y * _h + _h / 2, 0.5, 0, _y1, color)
                      :setUV2(x0 + sw, y0 + sh / 2 + y * _h + _h / 2, 0.5, w, _y1, color)
                      :setUV3(x0 + sw, y0 + sh / 2 + y * _h - _h / 2, 0.5, w, _y2, color)
                      :setUV4(x0 + 0, y0 + sh / 2 + y * _h - _h / 2, 0.5, 0, _y2, color)
                      :setBlend(Render.BlendMode.Default):draw()

                end
            end
        end
    end
end

---获取放射式色散特效的函数形式
---Return a function that generates a Radial Chromatic effect.
---@param strength number 色散强度
---@param cx number 色散中心横坐标
---@param cy number 色散中心纵坐标
---@param colors table[3] 色彩列表，默认为{Render.Color.Red, Render.Color.Green, Render.Color.Blue}
---@return Core.Effect.Post.Func
function M.RadialChromatic(strength, cx, cy, colors)
    colors = colors or colsRGB
    return function(rtName, x0, y0, scale)
        local rt = Core.Resource.RenderTarget.Get(rtName)
        if not rt then
            return
        end
        x0 = x0 or 0
        y0 = y0 or 0
        scale = scale or 1
        local w, h = rt:getSize()
        cx, cy = cx or w / 2 * scale, cy or h / 2 * scale
        local w1, w2 = cx, w * scale - cx
        local h1, h2 = cy, h * scale - cy

        for z = -1, 1 do
            local s = 1 + strength * z
            local color = colors[z + 2]
            rt:setUV1(x0 + cx - w1 * s, y0 + cy + h2 * s, 0.5, 0, 0, color)
              :setUV2(x0 + cx + w2 * s, y0 + cy + h2 * s, 0.5, w, 0, color)
              :setUV3(x0 + cx + w2 * s, y0 + cy - h1 * s, 0.5, w, h, color)
              :setUV4(x0 + cx - w1 * s, y0 + cy - h1 * s, 0.5, 0, h, color)
              :setBlend(Render.BlendMode.MulAdd):draw()
        end
    end

end

---获取方向色散特效的函数形式
---Return a function that generates a Directional Chromatic effect.
---@param offX number 色散横向偏移
---@param offY number 色散纵向偏移
---@param colors table[3] 色彩列表，默认为{Render.Color.Red, Render.Color.Green, Render.Color.Blue}
---@return Core.Effect.Post.Func
function M.DirectionalChromatic(offX, offY, colors)
    colors = colors or colsRGB
    offX, offY = offX or 0, offY or 0
    return function(rtName, x0, y0, scale)
        local rt = Core.Resource.RenderTarget.Get(rtName)
        if not rt then
            return
        end
        x0 = x0 or 0
        y0 = y0 or 0
        scale = scale or 1
        local w, h = rt:getSize()
        for z = -1, 1 do
            local color = colors[z + 2]
            rt:setUV1(x0 + offX * z, y0 + h * scale + offY * z, 0.5, 0, 0, color)
              :setUV2(x0 + w * scale + offX * z, y0 + h * scale + offY * z, 0.5, w, 0, color)
              :setUV3(x0 + w * scale + offX * z, y0 + offY * z, 0.5, w, h, color)
              :setUV4(x0 + offX * z, y0 + offY * z, 0.5, 0, h, color)
              :setBlend(Render.BlendMode.MulAdd):draw()
        end
    end

end

---对纹理进行旋转、缩放、偏移、颜色变换的函数形式
---Return a function that transforms a texture by rotation, scaling, offset, and color change.
---@param rotation number 旋转角度，单位为弧度
---@param hscale number 水平缩放比例
---@param vscale number 垂直缩放比例
---@param offX number 水平偏移量
---@param offY number 垂直偏移量
---@param color lstg.Color 颜色
---@param blend lstg.BlendMode 混合模式
---@return fun(rtName:string, x0:number, y0:number, scale:number)
function M.Transform(rotation, hscale, vscale, offX, offY, color, blend)
    rotation = rotation or 0
    hscale = hscale or 1
    vscale = vscale or hscale
    offX = offX or 0
    offY = offY or 0
    color = color or Render.Color.White
    blend = blend or Render.BlendMode.Default
    local cosr, sinr = cos(rotation), sin(rotation)
    return function(rtName, x0, y0, scale)
        local rt = Core.Resource.RenderTarget.Get(rtName)
        if not rt then
            return
        end
        x0 = x0 or 0
        y0 = y0 or 0
        scale = scale or 1
        local w, h = rt:getSize()
        local sw, sh = w * scale, h * scale
        local cx, cy = x0 + sw / 2 + offX, y0 + sh / 2 + offY
        local w0, h0 = sw / 2 * hscale, sh / 2 * vscale

        local x1, y1 = -w0 * cosr - h0 * sinr, -w0 * sinr + h0 * cosr
        local x2, y2 = w0 * cosr - h0 * sinr, w0 * sinr + h0 * cosr
        local x3, y3 = w0 * cosr + h0 * sinr, w0 * sinr - h0 * cosr
        local x4, y4 = -w0 * cosr + h0 * sinr, -w0 * sinr - h0 * cosr
        rt:setUV1(cx + x1, cy + y1, 0.5, 0, 0, color)
          :setUV2(cx + x2, cy + y2, 0.5, w, 0, color)
          :setUV3(cx + x3, cy + y3, 0.5, w, h, color)
          :setUV4(cx + x4, cy + y4, 0.5, 0, h, color)
          :setBlend(blend):draw()
    end
end

---获取单点扩散波浪特效的函数形式
---坐标系原点为纹理左下角
---：疑惑为什么不和纹理采样的坐标系统一？
---可能是我的小癖好
---Get a function that generates a single point wave distortion effect.
---The coordinate system origin is the bottom left of the texture.
---: Why not use the coordinate system of the texture sampling?
---Maybe it's my little habit.
---@param x number 波纹中心横坐标
---@param y number 波纹中心纵坐标
---@param strength number 波纹强度
---@param waveR number 波纹半径
---@param maxR number 扩散半径
---@param T number 0~1 动画进度参数
---@param cutR number 对波纹的切割数
---@param cutN number 对圆的切割数
---@return Core.Effect.Post.Func
function M.ShockWave(x, y, T, strength, waveR, maxR, cutR, cutN)
    maxR = maxR or 120--最大半径
    waveR = waveR or 60
    maxR = maxR - waveR / 2
    strength = strength or 1
    cutR = cutR or 42
    cutN = cutN or 10
    local color = Core.Render.Color.White
    return function(rtName, x0, y0, scale)
        local rt = Core.Resource.RenderTarget.Get(rtName)
        if not rt then
            return
        end
        rt:setBlend(Render.BlendMode.Force)
        local w, h = rt:getSize()
        rt:setUV1(x0, y0 + h * scale, 0.5, 0, 0, color)
          :setUV2(x0 + w * scale, y0 + h * scale, 0.5, w, 0, color)
          :setUV3(x0 + w * scale, y0, 0.5, w, h, color)
          :setUV4(x0, y0, 0.5, 0, h, color)
          :draw()
        local sr = maxR * T
        local kr1 = sr
        local kr2 = sr
        local dr1 = waveR / cutR
        for i = 1, cutR do
            local dr2 = waveR / cutR - strength * ((i - 1) / (cutR - 1) * 2 - 1) * sin(T * 180)
            for r = 1, cutN do
                local da = 360 / cutN
                local ang = r * da
                local cosa1, sina1 = cos(ang), sin(ang)
                local cosa2, sina2 = cos(ang + da), sin(ang + da)
                local x1, y1 = x + cosa1 * kr2, y + sina1 * kr2
                local x2, y2 = x + cosa1 * (kr2 + dr2), y + sina1 * (kr2 + dr2)
                local x3, y3 = x + cosa2 * (kr2 + dr2), y + sina2 * (kr2 + dr2)
                local x4, y4 = x + cosa2 * kr2, y + sina2 * kr2
                local ux1, uy1 = x + cosa1 * kr1, y + sina1 * kr1
                local ux2, uy2 = x + cosa1 * (kr1 + dr1), y + sina1 * (kr1 + dr1)
                local ux3, uy3 = x + cosa2 * (kr1 + dr1), y + sina2 * (kr1 + dr1)
                local ux4, uy4 = x + cosa2 * kr1, y + sina2 * kr1
                rt:setUV1(x0 + x1 * scale, y0 + y1 * scale, 0.5, ux1, h - uy1, color)
                  :setUV2(x0 + x2 * scale, y0 + y2 * scale, 0.5, ux2, h - uy2, color)
                  :setUV3(x0 + x3 * scale, y0 + y3 * scale, 0.5, ux3, h - uy3, color)
                  :setUV4(x0 + x4 * scale, y0 + y4 * scale, 0.5, ux4, h - uy4, color)
                  :draw()
            end
            kr1 = kr1 + dr1
            kr2 = kr2 + dr2
        end
    end
end

---@type Core.Resource.Shader
local GrayEffect
function M.Gray(strength)
    if not GrayEffect then
        GrayEffect = Core.Resource.Shader.Get("core:gray")
    end
    GrayEffect:setFloat("alpha", strength)
    return function(rtName, x0, y0, scale)
        GrayEffect:setTexture("screen_texture", rtName)
        GrayEffect:post("")
    end
end
