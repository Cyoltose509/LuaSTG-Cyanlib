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
        local sw, sh = w / scale, h / scale
        if vertical then
            local _w = sw / cut
            local k = (cut - 1) / 2
            for x = -k, k do
                local floatx = offcache[x + k + 1][2]
                local oy = offcache[x + k + 1][1]
                local tx = (x * _w + floatx + sw / 2) % sw - sw / 2
                local _x1 = (sw / 2 - _w / 2 + tx) * scale
                local _x2 = (sw / 2 + _w / 2 + tx) * scale
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
                local _y1 = h - (sh / 2 + _h / 2 + ty) * scale
                local _y2 = h - (sh / 2 - _h / 2 + ty) * scale
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
        cx, cy = cx or w / 2 / scale, cy or h / 2 / scale
        local w1, w2 = cx, w / scale - cx
        local h1, h2 = cy, h / scale - cy

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
---@param offx number 色散横向偏移
---@param offy number 色散纵向偏移
---@param colors table[3] 色彩列表，默认为{Render.Color.Red, Render.Color.Green, Render.Color.Blue}
function M.DirectionalChromatic(offx, offy, colors)
    colors = colors or colsRGB
    offx, offy = offx or 0, offy or 0
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
            rt:setUV1(x0 + offx * z, y0 + h / scale + offy * z, 0.5, 0, 0, color)
              :setUV2(x0 + w / scale + offx * z, y0 + h / scale + offy * z, 0.5, w, 0, color)
              :setUV3(x0 + w / scale + offx * z, y0 + offy * z, 0.5, w, h, color)
              :setUV4(x0 + offx * z, y0 + offy * z, 0.5, 0, h, color)
              :setBlend(Render.BlendMode.MulAdd):draw()
        end
    end

end

---对纹理进行旋转、缩放、偏移、颜色变换的函数形式
---Return a function that transforms a texture by rotation, scaling, offset, and color change.
---@param rotation number 旋转角度，单位为弧度
---@param hscale number 水平缩放比例
---@param vscale number 垂直缩放比例
---@param xoffset number 水平偏移量
---@param yoffset number 垂直偏移量
---@param color lstg.Color 颜色
---@param blend lstg.BlendMode 混合模式
function M.Transform(rotation, hscale, vscale, xoffset, yoffset, color, blend)
    rotation = rotation or 0
    hscale = hscale or 1
    vscale = vscale or hscale
    xoffset = xoffset or 0
    yoffset = yoffset or 0
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
        local sw, sh = w / scale, h / scale
        local cx, cy = x0 + sw / 2, y0 + sh / 2
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

local Vec = Core.Math.Vector2
--TODO
---@param vec Core.Math.Vector2 传播方向
---@param thickness number 波纹厚度（越大越宽）
---@param strength number 扭曲位移强度
---@param omega number 波频率（越大越密）
---@param bidirectional boolean 是否双向传播
---@return fun(rtName:string, x0:number, y0:number, scale:number, process:number)
function M.Shockline(process, vec, thickness, strength, omega, bidirectional)
    vec = vec or Vec.right

    return function(rtName, x0, y0, scale)
        local rt = Core.Resource.RenderTarget.Get(rtName)
        if not rt then
            return
        end

        x0 = x0 or 0
        y0 = y0 or 0
        scale = scale or 1

        local w, h = rt:getSize()
        local sw, sh = w / scale, h / scale

    end
end
