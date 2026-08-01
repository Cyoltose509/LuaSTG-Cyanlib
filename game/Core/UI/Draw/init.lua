---@class Core.UI.Draw : Core.UI.Child
---@field Sector Core.UI.Draw.Sector
---@field Rect Core.UI.Draw.Rect
---@field RectOutline Core.UI.Draw.RectOutline
---@field RoundedRect Core.UI.Draw.RoundedRect
---@field RoundedRectOutline Core.UI.Draw.RoundedRectOutline
---@field HexRect Core.UI.Draw.HexRect
---@field HexRectOutline Core.UI.Draw.HexRectOutline
---@field Parallelogram Core.UI.Draw.Parallelogram
---@field ParallelogramOutline Core.UI.Draw.ParallelogramOutline
local M = Core.Class(Core.UI.Child)
Core.UI.Draw = M

M:addSerializeSimple(Core.UI.Child, "_blend", "_color1", "_color2", "_color3", "_color4")
M:addDeserializeOrder("_color1", Core.Render.Color.Parse)
M:addDeserializeOrder("_color2", Core.Render.Color.Parse)
M:addDeserializeOrder("_color3", Core.Render.Color.Parse)
M:addDeserializeOrder("_color4", Core.Render.Color.Parse)

function M:init(name, layer)
    Core.UI.Child.init(self, name or "Draw", layer or 0)
    self._blend = Core.Render.BlendMode.Default
    self._color1 = Core.Render.Color.Default
    self._color2 = nil
    self._color3 = nil
    self._color4 = nil
    self._need_update = true
    self._ignore_pos_update = true
    self.datas = {}
    ---悬停过渡动效（见 update / draw）：
    ---_hover_color：悬停时背景色缓动到的目标色（nil 表示不变色）
    self._hover_color = nil
    ---_hover_scale_target：悬停时额外缩放倍率（1 表示不变），用于"光标移上去放大"反馈
    self._hover_scale_target = 1
    ---hover_t：颜色过渡进度 (0→1)，每帧向目标缓动
    self.hover_t = 0
    ---_hover_scale_cur：缩放过渡当前值，每帧向 _hover_scale_target 缓动
    self._hover_scale_cur = 1
    ---每帧缓动速率（0~1，越大越快；约 0.18 在 60fps 下约 0.25s 到位）
    self.hover_speed = 0.18
end

---@overload fun(blend:lstg.BlendMode, c1:lstg.Color, c2:lstg.Color, c3:lstg.Color, c4:lstg.Color):self
---@overload fun(blend:lstg.BlendMode, color:lstg.Color):self
---@overload fun(blend:lstg.BlendMode):self
function M:setState(blend, c1, c2, c3, c4)
    self._blend = blend or self._blend
    if c2 and c3 and c4 then
        self._color1 = c1
        self._color2 = c2
        self._color3 = c3
        self._color4 = c4
    else
        self._color1 = c1 or self._color1
        self._color2 = nil
        self._color3 = nil
        self._color4 = nil
    end
    return self
end

---设置线性渐变背景，等价于 CSS `linear-gradient(dir, c1, c2)`。
---底层利用四边形 4 角顶点色做双线性插值；顶点顺序见 Core.Math.Geom.GetRectPoints：
---  P1=左下, P2=右下, P3=右上, P4=左上。
---@param c1 lstg.Color 起点色（dir 决定起点边）
---@param c2 lstg.Color 终点色
---@param dir string|nil "v"=上→下(默认) | "h"=左→右 | "d"=左上→右下
---@return self
function M:setGradient(c1, c2, dir)
    dir = dir or "v"
    if dir == "h" then
        -- 左(c1)→右(c2)：左顶点 P1,P4 为 c1，右顶点 P2,P3 为 c2
        self:setState(self._blend, c1, c2, c2, c1)
    elseif dir == "d" then
        -- 左上→右下：P4=左上=c1, P2=右下=c2，其余对角补色
        self:setState(self._blend, c2, c1, c2, c1)
    else
        -- 垂直：上(c1)→下(c2)：上顶点 P3,P4 为 c1，下顶点 P1,P2 为 c2
        self:setState(self._blend, c2, c2, c1, c1)
    end
    return self
end

---设置悬停时的目标背景色（光标移上去时平滑过渡到此色）。nil 表示禁用变色。
---@param c lstg.Color|nil
---@return self
function M:setHoverColor(c)
    self._hover_color = c
    return self
end

---设置悬停时的额外缩放倍率（光标移上去时平滑放大/缩小到此倍率）。默认 1（不变）。
---@param s number
---@return self
function M:setHoverScale(s)
    self._hover_scale_target = s or 1
    return self
end

---颜色线性插值（用于悬停过渡混合）。返回新 lstg.Color。
local function blendColor(a, b, t)
    if not a then return b end
    if not b then return a end
    local aa, ar, ag, ab = a:ARGB()
    local ba, br, bg, bb = b:ARGB()
    return lstg.Color(aa + (ba - aa) * t, ar + (br - ar) * t, ag + (bg - ag) * t, ab + (bb - ab) * t)
end

---基类每帧更新：缓动悬停过渡（颜色进度 hover_t + 缩放 _hover_scale_cur）。
---仅由持有几何的子类（Rect/RoundedRect）在各自 update 开头调用。
function M:update()
    -- 关键：Draw 节点重写了 update，必须自行刷新渲染坐标(_x/_y)与缩放，
    -- 否则会沿用初始值(0,0)把所有面板/图标画到左下角原点。
    self:refreshScale()
    self:refreshXY()
    local target = self.hovered and 1 or 0
    if self.hover_t ~= target then
        local d = self.hover_speed
        if self.hover_t < target then
            self.hover_t = min(1, self.hover_t + d)
        else
            self.hover_t = max(0, self.hover_t - d)
        end
        if self.hover_t > 0 and self.hover_t < 1 then
            self._need_update = true
        end
    end
    local starget = self.hovered and self._hover_scale_target or 1
    if self._hover_scale_cur ~= starget then
        local d = self.hover_speed
        if self._hover_scale_cur < starget then
            self._hover_scale_cur = min(starget, self._hover_scale_cur + d * (starget - 1))
        else
            self._hover_scale_cur = max(starget, self._hover_scale_cur - d * (1 - starget))
        end
        self._need_update = true
    end
end

function M:draw()
    local Draw = Core.Render.Draw
    local c1, c2, c3, c4 = self._color1, self._color2, self._color3, self._color4
    local hc = self._hover_color
    if hc and self.hover_t > 0 then
        local t = self.hover_t
        c1 = blendColor(c1, hc, t)
        c2 = c2 and blendColor(c2, hc, t) or c1
        c3 = c3 and blendColor(c3, hc, t) or c1
        c4 = c4 and blendColor(c4, hc, t) or c1
    end
    Draw.SetState(self._blend, c1, c2, c3, c4)
    local x, y = self._x, self._y
    local z = 0.5
    for _, p in ipairs(self.datas) do
        Draw.Quad(x + p[1], y + p[2], z,
                x + p[3], y + p[4], z,
                x + p[5], y + p[6], z,
                x + p[7], y + p[8], z)
    end
    Core.UI.Child.draw(self)
end

require("Core.UI.Draw.Sector")
require("Core.UI.Draw.Rect")
require("Core.UI.Draw.RectOutline")
require("Core.UI.Draw.RoundedRect")
require("Core.UI.Draw.RoundedRectOutline")
require("Core.UI.Draw.HexRect")
require("Core.UI.Draw.HexRectOutline")
require("Core.UI.Draw.Parallelogram")
require("Core.UI.Draw.ParallelogramOutline")