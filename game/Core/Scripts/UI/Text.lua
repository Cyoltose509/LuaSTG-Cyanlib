---@class Core.UI.Text : Core.UI.Child
local M = Core.Class(Core.UI.Child)
Core.UI.Text = M
M:addSerializeSimple(Core.UI.Child, "text")
M:addSerializeOrder("text", function(value)
    return Core.Lib.Json.Encode(value:serialize())
end)
M:addDeserializeOrder("text", function(value, self)
    self.text:deserialize(Core.Lib.Json.Decode(value))
    return self.text
end)

---@alias Core.UI.Text.New Core.UI.Text.New|fun():Core.UI.Text
function M:init()
    Core.UI.Child.init(self, "Text", 0)
    ---@private
    self.text = Core.Render.Text()
    self.text:enableRectAnchor(true)
    self._auto_width_height = true
end
function M:autoWidthHeight(enable)
    self._auto_width_height = enable
    if enable then
        self:setWH(self.text._total_width, self.text._total_height)
    end
    return self
end

function M:setText(text)
    self.text:setText(text)
    return self
end
function M:setFont(font)
    self.text:setFont(font)
    return self
end
function M:setColor(color)
    self.text:setColor(color)
    return self
end
function M:setHAlign(value)
    self.text:setHAlign(value)
    return self
end
function M:setVAlign(value)
    self.text:setVAlign(value)
    return self
end
function M:setAlignment(...)
    self.text:setAlignment(...)
    return self
end
function M:setTextRect(w, h, free)
    self.text:setRect(w, h)
    if not free then
        self:setWH(w, h)
    end
    return self
end
function M:setRotation(rot)
    self.text:setRotation(rot)
    return self
end
function M:setLineHeightFactor(f)
    self.text:setLineHeightFactor(f)
    return self
end
function M:enableWordBreak(enable)
    self.text:enableWordBreak(enable)
    return self
end
function M:enableWrapWord(enable)
    self.text:enableWrapWord(enable)
    return self
end
function M:enableAutoFit(width, height)
    self.text:enableAutoFit(width, height)
    return self
end
function M:setSize(s)
    self.text:setSize(s)
    return self
end
function M:setBlendMode(mode)
    self.text:setBlendMode(mode)
    return self
end
function M:setShadowColor(color)
    self.text:setShadowColor(color)
    return self
end
function M:enableShadow(enable)
    self.text:enableShadow(enable)
    return self
end
function M:setShadowDiv(div)
    self.text:setShadowDiv(div)
    return self
end
function M:setShadowDirection(dirX, dirY)
    self.text:setShadowDirection(dirX, dirY)
    return self
end
function M:enableOblique(enable)
    self.text:enableOblique(enable)
    return self
end
function M:setObliqueAngle(a)
    self.text:setObliqueAngle(a)
    return self
end
function M:enableLockAspectRatio(enable)
    self.text:enableLockAspectRatio(enable)
    return self
end
function M:enableRichText(enable)
    self.text:enableRichText(enable)
    return self
end
function M:refresh()
    self.text:setPosition(self:getXY())
    self.text:setScale(self:getScale())
    self.text:update()
end
function M:before_update()
    local last_width, last_height = self.text:getContentSize()
    self:refresh()
    local now_width, now_height = self.text:getContentSize()
    if self._auto_width_height and (last_width ~= now_width or last_height ~= now_height) then
        --self:setWH(self.text._total_width, self.text._total_height)
        self:setTextRect(now_width, now_height)
    end
end
function M:update()
    Core.UI.Child.update(self)
    self:refresh()
end
function M:draw()
    --Core.Render.Draw.SetState("", Core.Render.Color(255, 255, 255, 255))
    --Core.Render.Draw.Sector(self._x, self._y, 0, 30, 0, 360, 20)
    self.text:draw(true)
    Core.UI.Child.draw(self)
end
