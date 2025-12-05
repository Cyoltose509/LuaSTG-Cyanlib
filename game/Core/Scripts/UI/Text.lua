---@class Core.UI.Text : Core.UI.Child
local M = Core.Class(Core.UI.Child)
Core.UI.Text = M
---@alias Core.UI.Text.New Core.UI.Text.New|fun():Core.UI.Text
function M:init()
    Core.UI.Child.init(self, "Text", 0)
    self.text = ""
    self.font = nil
    ---@type Core.Resource.TTF
    self.font_res = nil
    self.size = 16
    self.color = Core.Render.Color.Default
    self.black_color = Core.Render.Color.Black
    self.parent = nil
    self.has_shadow = true
    self.halign = "center"
    self.valign = "vcenter"
end
---无效函数
function M:setRotation()
    return self
end
---如果只传入"centerpoint"，会自动设置为居中
---@overload fun(align:string):self
function M:setAlignment(halign, valign)
    if halign == "centerpoint" then
        halign = "center"
        valign = "vcenter"
    end
    self.halign = halign or "center"
    self.valign = valign or "vcenter"
    return self
end
function M:enableShadow(enabled)
    self.has_shadow = enabled or false
    return self
end

---@param color Core.Render.Color
function M:setColor(color)
    self.color = color or Core.Render.Color.Default
    self.black_color = Core.Render.Color(color.a, 0, 0, 0)
    return self
end
function M:refreshWH()
    if self.font_res then
        local scale = min(self._hscale, self._vscale)
        local fr = lstg.FontRenderer
        local size = self.size / self.font_res:getSize() * scale
        fr.SetFontProvider(self.font)
        fr.SetScale(size, size)
        local l, r, b, t = fr.MeasureTextBoundary(self.text)
        self:setWH((r - l) * 1.05, (t - b) * 1.3)
    else
        self:setWH(0, 0)
    end
    return self
end
---@return self
function M:setText(text)
    self.text = text or ""
    self:refreshWH()
    return self
end
function M:setFont(font)
    self.font = font
    self.font_res = Core.Resource.TTF.Get(font)
    self:refreshWH()
    return self
end
function M:setSize(size)
    self.size = size or 16
    self:refreshWH()
    return self
end

function M:update()
    Core.UI.Child.update(self)
end

function M:draw()
    --Core.Render.Draw.SetState(Core.Render.BlendMode.Default, Core.Render.Color.Default)
    --Core.Render.Draw.RectOutline(self._x, self._y, self.width * self._hscale, self.height * self._vscale, 0, 2)
    local scale = min(self._hscale, self._vscale)
    local halign, valign = self.halign, self.valign
    if self.parentLayout then
        halign, valign = "centerpoint"
    end--TODO:这是一个可能需要来完善的功能，目前暂时强制居中对齐
    if self.font_res then
        local size = self.size / self.font_res:getSize() * 2 * scale
        if self.has_shadow then
            local s = self.size * scale / 48
            for i = 1, 4 do
                Core.Render.Text(self.font, self.text, self._x + i * 0.7 * s, self._y - i * 0.5 * s, size, self.black_color, halign, valign)
            end
        end
        Core.Render.Text(self.font, self.text, self._x, self._y, size, self.color, halign, valign)
    end

end