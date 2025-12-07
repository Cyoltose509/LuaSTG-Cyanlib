---@class Core.Render.Text
---@field RichText Core.Render.Text.RichText
---@field CJKBreak Core.Render.Text.CJKBreak
local M = Core.Class()
Core.Render.Text = M

require("Core.Scripts.Render.Text.RichText")
require("Core.Scripts.Render.Text.CJKBreak")

function M:init()
    self.text = ""

    self.font = nil
    self.color = Core.Render.Color.Default
    self.h_align = "center"
    self.v_align = "vcenter"
    self.width = 0
    self.height = 0
    self.x, self.y = 0, 0
    self.z = 0.5
    self.line_height_factor = 1 ---行间距倍数
    self.word_break = false ---是否自动换行（会拆掉长单词）
    self.wrap_word = false ---是否自动换行（不会拆掉长单词）
    self.rich_text = false ---是否支持富文本
    self.auto_fit_width = false ---是否自动适应宽度（不会自动换行）
    self.auto_fit_height = false ---是否自动适应高度
    self.size = 16
    self.hscale, self.vscale = 1, 1
    self.blend = Core.Render.BlendMode.Default
    self.shadow_params = {
        enabled = false,
        color = Core.Render.Color.Black,
        dirX = 4,
        dirY = -3,
        div = 4,

    }
    self.roll = 0
    self.pitch = 0
    self.yaw = 0
    self.is_oblique = false
    self.oblique_angle = 12
    self.lock_aspect_ratio = false

    ---@type Core.Resource.TTF
    self.font_res = nil
    self._text_segments = {}
    ---@type Core.Lib.RichText.Parsed[]
    self._rich_text_data = {}
    ---@type Core.Render.Text.Line[]
    self._lines = {}
    self._real_hscale = 1
    self._real_vscale = 1
    self._fit_height_scale = 1
    --self._line_height = 0
    self._total_height = 0
    self._ascender = 0
    self._anchorX, self._anchorY, self._anchorZ = 0, 0, 0
    self._xVector = { 1, 0, 0 }
    self._yVector = { 0, -1, 0 }
    self._writeVector = { 0, -1, 0 }
    self._anchor_dirty = true
    self._size_dirty = true
    self._lines_dirty = true
    self._vector_dirty = true
end
function M:setScale(hscale, vscale)
    hscale = hscale or self.hscale
    vscale = vscale or hscale
    if hscale ~= self.hscale or vscale ~= self.vscale then
        self.hscale = hscale
        self.vscale = vscale
        self._size_dirty = true
    end
    return self
end
function M:setLineHeightFactor(f)
    self.line_height_factor = f or 1
    self._lines_dirty = true
    return self
end
function M:setPosition(x, y, z)
    x = x or self.x
    y = y or self.y
    z = z or self.z
    if x ~= self.x or y ~= self.y or z ~= self.z then
        self.x = x
        self.y = y
        self.z = z
        self._anchor_dirty = true
    end
    return self
end
function M:setRect(width, height)
    width = width or self.width
    height = height or self.height
    if width ~= self.width or height ~= self.height then
        self.width = width
        self.height = height
        self._lines_dirty = true
    end
    return self
end
function M:setAlignment(...)
    local befHalign, befValign = self.h_align, self.v_align
    local befWordbreak = self.word_break
    self.h_align = "center"
    self.v_align = "vcenter"
    self.word_break = false
    for _, v in ipairs({ ... }) do
        if v == "left" then
            self.h_align = "left"
        elseif v == "right" then
            self.h_align = "right"
        elseif v == "center" then
            self.h_align = "center"
        elseif v == "top" then
            self.v_align = "top"
        elseif v == "bottom" then
            self.v_align = "bottom"
        elseif v == "vcenter" then
            self.v_align = "vcenter"
        elseif v == "centerpoint" then
            self.h_align = "center"
            self.v_align = "vcenter"
        elseif v == "wordbreak" then
            self.word_break = true
        end
    end
    if befHalign ~= self.h_align or befValign ~= self.v_align or befWordbreak ~= self.word_break then
        self._lines_dirty = true
    end
    return self
end
function M:setHAlign(value)
    value = value or self.h_align
    if value ~= self.h_align then
        self.h_align = value
        self._lines_dirty = true
    end
    return self
end
function M:setVAlign(value)
    value = value or self.v_align
    if value ~= self.v_align then
        self.v_align = value
        self._lines_dirty = true
    end
    return self
end
function M:enableLockAspectRatio(enable)
    self.lock_aspect_ratio = enable or false
    return self
end
function M:enableWordBreak(enable)
    if enable ~= self.word_break then
        self.word_break = enable
        self._lines_dirty = true
    end
    return self
end
function M:enableWrapWord(enable)
    if enable ~= self.wrap_word then
        self.wrap_word = enable
        self:refreshTextSegments()
    end
    return self
end
function M:enableRichText(enable)
    if enable ~= self.rich_text then
        self.rich_text = enable
        self:refreshTextSegments()
    end
    return self
end
function M:enableAutoFit(width, height)
    self.auto_fit_width = width or false
    height = height or false
    if height ~= self.auto_fit_height then
        self.auto_fit_height = height
        self._lines_dirty = true
        return self
    end
    return self
end

function M:enableShadow(enable)
    self.shadow_params.enabled = enable or false
    return self
end
function M:enableOblique(enable)
    self.is_oblique = enable or false
    self._vector_dirty = true
    return self
end
function M:setObliqueAngle(ang)
    self.oblique_angle = ang or 12
    self._vector_dirty = true
    return self
end
function M:setRotation3D(pitch, yaw, roll)
    self.roll = roll or 0
    self.pitch = pitch or 0
    self.yaw = yaw or 0
    self._anchor_dirty = true
    self._vector_dirty = true
    return self
end
function M:setRotation(rot)
    self.roll = rot or 0
    self.pitch = 0
    self.yaw = 0
    self._anchor_dirty = true
    self._vector_dirty = true
    return self
end
---@overload fun(color:Core.Render.Color):self
function M:setShadowColor(r, g, b)
    local c = self.shadow_params.color
    if r and g and b then
        c.r = r
        c.g = g
        c.b = b
    elseif r then
        c.r = r.r
        c.g = r.g
        c.b = r.b
    end
    return self
end
function M:setShadowDirection(dirX, dirY)
    local P = self.shadow_params
    P.dirX = dirX or P.dirX
    P.dirY = dirY or P.dirY
    return self
end
function M:setShadowDiv(div)
    local P = self.shadow_params
    P.div = div or P.div
    return self
end

---@param color Core.Render.Color
function M:setColor(color)
    self.color = color or Core.Render.Color.Default
    self.shadow_params.color.a = self.color.a
    self:refreshColor()
    return self
end
function M:setBlendMode(blend)
    self.blend = blend or Core.Render.BlendMode.Default
    return self
end
function M:setText(text)
    text = text or ""
    if text ~= self.text then
        self.text = text

        self:refreshTextSegments()
    end
    return self
end
function M:refreshTextSegments()
    self._text_segments = {}
    local text = self.text
    if self.rich_text then
        local data = M.RichText.Parse(text, {
            color = self.color,
            size = 1,
            oblique = self.is_oblique,
            shadow = self.shadow_params.enabled,
            underline = false,
            strikethrough = false,
            blend = self.blend,
        })
        text = data.text
        self._rich_text_data = data.runs
    end
    if self.wrap_word then
        self._text_segments = M.CJKBreak.Tokenize(text)
    else
        for i, ch in ipairs(string.utf8_byte(text)) do
            self._text_segments[i] = string.utf8_char(ch)
        end
    end
    self._lines_dirty = true
end
function M:setFont(font)
    if font ~= nil and self.font ~= font then
        self.font = font
        self.font_res = Core.Resource.TTF.Get(font)
        self._size_dirty = true
    end
    return self
end

function M:setSize(size)
    size = size or 16
    if size ~= self.size then
        self.size = size
        self._size_dirty = true
    end
    return self
end
---@private
function M:refreshSize()
    local s = self.size / self.font_res:getSize()
    self._real_hscale = self.hscale * s
    self._real_vscale = self.vscale * s * self._fit_height_scale
    self._lines_dirty = true
end

function M:splitLines()
    local rich_data = Core.Lib.Table.Copy(self._rich_text_data)
    local text = self._text_segments
    local hs, vs = self._real_hscale, self._real_vscale
    local fr = lstg.FontRenderer
    ---@type Core.Render.Text.Line[]
    local lines = {}
    local curBuf = {}
    ---@type Core.Render.Text.Data[]
    local dataBuf = {}
    local curWidth = 0
    local curHeight = 0
    local smallBuf = {}
    local smallWidth = 0
    local smallHeight = 0
    local totalHeight = 0
    local success = true
    local i = 1
    local byte_i = 0
    ---@type Core.Render.Text.RichText.Style
    local style
    local lh = fr.GetFontLineHeight()
    local function next(tok, tw)
        table.insert(curBuf, tok)
        table.insert(smallBuf, tok)
        smallWidth = smallWidth + tw
        curWidth = curWidth + tw
        i = i + 1
    end
    local function insert_line()
        local data = {
            text = table.concat(smallBuf),
            style = style,
            width = smallWidth,
            height = smallHeight,
        }
        table.insert(dataBuf, data)
        ---@class Core.Render.Text.Line
        local line = {
            width = curWidth,
            height = curHeight,
            data = dataBuf,
        }
        -- print(curWidth, curHeight, smallWidth, smallHeight)
        table.insert(lines, line)
        totalHeight = totalHeight + curHeight
        curHeight = 0
        curBuf = {}
        dataBuf = {}
        smallBuf = {}
        smallWidth = 0
        smallHeight = 0
        curWidth = 0
    end

    while i <= #text do
        local tok = text[i]
        byte_i = byte_i + #tok
        if rich_data and #rich_data > 0 then
            local run = rich_data[1]
            if run.start <= byte_i and byte_i <= run.stop then

                ---@class Core.Render.Text.Data
                local data = {
                    text = table.concat(smallBuf),
                    style = style,
                    width = smallWidth,
                    height = smallHeight,
                }
                table.insert(dataBuf, data)
                smallBuf = {}
                smallWidth = 0
                smallHeight = 0
                style = run.style
                table.remove(rich_data, 1)
            end
        end
        if tok == "\n" then
            insert_line()
            i = i + 1
        else
            local size = style and style.size or 1
            fr.SetScale(hs * size, vs * size)
            local tw = fr.MeasureTextAdvance(tok)
            local th = size * vs * lh
            curHeight = max(curHeight, th)
            smallHeight = max(smallHeight, th)
            if tok ~= "" and tw == 0 then
                success = false
            end
            local overflow = curWidth + tw > self.width
            if self.word_break then
                if overflow then
                    if #curBuf == 0 then
                        insert_line()
                        i = i + 1
                    else
                        insert_line()
                    end
                else
                    next(tok, tw)
                end
            elseif self.wrap_word then
                if overflow then
                    if #curBuf == 0 then
                        insert_line()
                        i = i + 1
                    else
                        insert_line()
                    end
                else
                    next(tok, tw)
                end
            else
                next(tok, tw)
            end
        end
    end
    if #curBuf > 0 then
        insert_line()
    end
    self._lines = lines
    self._total_height = totalHeight
    self:refreshColor()
    return success
end
function M:refreshColor()
    for _, line in ipairs(self._lines) do
        for _, data in ipairs(line.data) do
            if data.style and data.style.color then
                data.style.color.a = self.color.a
            end
        end
    end
end

---@private
function M:refreshLines()
    local fr = lstg.FontRenderer
    fr.SetFontProvider(self.font)
    local hs, vs = self._real_hscale, self._real_vscale
    fr.SetScale(hs, vs)
    --self._line_height = fh * vs * self.line_height_factor
    self._ascender = fr.GetFontAscender() * vs
    local success = self:splitLines()
    if self.auto_fit_height then
        self._fit_height_scale = min(1, self.height / self._total_height)
        -- self._line_height = self._line_height * self._fit_height_scale
    else
        self._fit_height_scale = 1
    end
    self._anchor_dirty = true
    return success
end

local function vec2_rot(x, y, r_deg)
    local sin_v = sin(r_deg)
    local cos_v = cos(r_deg)
    return x * cos_v - y * sin_v, x * sin_v + y * cos_v
end

---@private
function M:refreshAnchor()
    local startY = -self._ascender
    if self.v_align == "vcenter" then
        startY = startY + self._total_height / 2
    elseif self.v_align == "bottom" then
        startY = startY + self._total_height
    end
    local x, y, z = 0, startY, 0
    if self.pitch ~= 0 then
        y, z = vec2_rot(y, z, self.pitch)
    end
    if self.yaw ~= 0 then
        x, z = vec2_rot(x, z, self.yaw)
    end
    if self.roll ~= 0 then
        x, y = vec2_rot(x, y, self.roll)
    end
    self._anchorX = self.x + x
    self._anchorY = self.y + y
    self._anchorZ = self.z + z
end

---@private
function M:refreshVector()

    local xv, yv = self._xVector, self._yVector
    local wv = self._writeVector
    local oblique = self.oblique_angle
    xv[1], xv[2], xv[3] = 1, 0, 0
    yv[1], yv[2], yv[3] = tan(-oblique), -1, 0
    wv[1], wv[2], wv[3] = 0, -1, 0
    if self.pitch ~= 0 then
        xv[2], xv[3] = vec2_rot(xv[2], xv[3], self.pitch)
        yv[2], yv[3] = vec2_rot(yv[2], yv[3], self.pitch)
        wv[2], wv[3] = vec2_rot(wv[2], wv[3], self.pitch)
    end
    if self.yaw ~= 0 then
        xv[1], xv[3] = vec2_rot(xv[1], xv[3], self.yaw)
        yv[1], yv[3] = vec2_rot(yv[1], yv[3], self.yaw)
        wv[1], wv[3] = vec2_rot(wv[1], wv[3], self.yaw)
    end
    if self.roll ~= 0 then
        xv[1], xv[2] = vec2_rot(xv[1], xv[2], self.roll)
        yv[1], yv[2] = vec2_rot(yv[1], yv[2], self.roll)
        wv[1], wv[2] = vec2_rot(wv[1], wv[2], self.roll)
    end
end

local Draw = Core.Render.Draw
local function draw_line(x1, y1, z1, x2, y2, z2, wv, h0, h1, blend, color)
    Draw.SetState(blend, color)
    Draw.Quad(
            x1 + h0 * wv[1], y1 + h0 * wv[2], z1 + h0 * wv[3],
            x2 + h0 * wv[1], y2 + h0 * wv[2], z2 + h0 * wv[3],
            x2 + h1 * wv[1], y2 + h1 * wv[2], z2 + h1 * wv[3],
            x1 + h1 * wv[1], y1 + h1 * wv[2], z1 + h1 * wv[3])
end

function M:draw()
    if self._size_dirty then
        self:refreshSize()
        self._size_dirty = false
    end
    while self._lines_dirty do
        if self:refreshLines() then
            self._lines_dirty = false
        end
    end
    if self._anchor_dirty then
        self:refreshAnchor()
        self._anchor_dirty = false
    end
    if self._vector_dirty then
        self:refreshVector()
        self._vector_dirty = false
    end
    local fr = lstg.FontRenderer
    fr.SetFontProvider(self.font)
    local hs, vs = self._real_hscale, self._real_vscale * self._fit_height_scale

    local xv, yv = self._xVector, self._yVector
    local wv = self._writeVector
    local halign = self.h_align
    local _x = self._anchorX
    local _y = self._anchorY
    local _z = self._anchorZ
    local P = self.shadow_params
    for k, line in ipairs(self._lines) do
        local x = _x
        local y = _y
        local z = _z
        local xoffset = 0
        local lw = line.width
        if halign == "center" then
            xoffset = -lw / 2
        elseif halign == "right" then
            xoffset = -lw
        end
        x = x + xv[1] * xoffset
        y = y + xv[2] * xoffset
        z = z + xv[3] * xoffset
        local index = 1
        if self.auto_fit_width then
            index = min(self.width / lw, 1)
        end
        for _, data in ipairs(line.data) do
            local dw, dh = data.width, data.height
            local style = data.style
            local size = style and style.size or 1
            local _color = self.color
            if style and style.color then
                _color = style.color
            end
            local y1, y2, y3 = wv[1], wv[2], wv[3]
            if style and style.oblique or self.is_oblique then
                y1, y2, y3 = yv[1], yv[2], yv[3]
            end
            if self.lock_aspect_ratio then
                local m = min(hs * index, vs)
                fr.SetScale(m * size, m * size)
            else
                fr.SetScale(hs * index * size, vs * size)
            end
            local blend = style and style.blend or self.blend
            if style and style.shadow or P.enabled then
                for i = 1, P.div do
                    local dx = P.dirX * i / P.div
                    local dy = P.dirY * i / P.div
                    fr.RenderTextInSpace(data.text, x + dx, y + dy, z, xv[1], xv[2], xv[3], y1, y2, y3,
                            blend, P.color * (1 - i / P.div))
                end
            end
            fr.RenderTextInSpace(data.text, x, y, z, xv[1], xv[2], xv[3], y1, y2, y3, blend, _color)
            if style and style.underline then
                draw_line(x, y, z, x + dw * xv[1], y + dw * xv[2], z + dw * xv[3], wv,
                        3, 5, blend, _color)
            end
            if style and style.strikethrough then
                local h = -dh * 0.32
                draw_line(x, y, z, x + dw * xv[1], y + dw * xv[2], z + dw * xv[3], wv,
                        h - 1, h + 1, blend, _color)
            end
            x = x + dw * xv[1]
            y = y + dw * xv[2]
            z = z + dw * xv[3]
        end
        if self._lines[k + 1] then
            local h = self._lines[k + 1].height
            _x = _x + h * wv[1]
            _y = _y + h * wv[2]
            _z = _z + h * wv[3]
        end
    end

end

function M:serialize()
    return {
        text = self.text,
        font = self.font,
        color = tostring(self.color),
        halign = self.h_align,
        valign = self.v_align,
        width = self.width,
        height = self.height,
        x = self.x,
        y = self.y,
        z = self.z,
        pitch = self.pitch,
        yaw = self.yaw,
        roll = self.roll,

        line_height_factor = self.line_height_factor,
        word_break = self.word_break,
        wrap_word = self.wrap_word,
        auto_fit_width = self.auto_fit_width,
        auto_fit_height = self.auto_fit_height,
        rich_text = self.rich_text,
        size = self.size,
        hscale = self.hscale,
        vscale = self.vscale,
        blend = self.blend,
        shadow_params = {
            color = tostring(self.shadow_params.color),
            enabled = self.shadow_params.enabled,
            div = self.shadow_params.div,
            dirX = self.shadow_params.dirX,
            dirY = self.shadow_params.dirY,
        },
        is_oblique = self.is_oblique,
        oblique_angle = self.oblique_angle,
        lock_aspect_ratio = self.lock_aspect_ratio,
    }
end
---@param data Core.Render.Text
function M:deserialize(data)
    self:setText(data.text)
        :setFont(data.font)
        :setColor(Core.Render.Color.Parse(data.color))
        :setHAlign(data.h_align)
        :setVAlign(data.v_align)
        :setRect(data.width, data.height)
        :setPosition(data.x, data.y, data.z)
        :setRotation3D(data.pitch, data.yaw, data.roll)
        :setLineHeightFactor(data.line_height_factor)
        :enableWordBreak(data.word_break)
        :enableWrapWord(data.wrap_word)
        :enableAutoFit(data.auto_fit_width, data.auto_fit_height)
        :setSize(data.size)
        :setScale(data.hscale, data.vscale)
        :setBlendMode(data.blend)
        :setShadowColor(Core.Render.Color.Parse(data.shadow_params.color))
        :enableShadow(data.shadow_params.enabled)
        :setShadowDiv(data.shadow_params.div)
        :setShadowDirection(data.shadow_params.dirX, data.shadow_params.dirY)
        :enableOblique(data.is_oblique)
        :setObliqueAngle(data.oblique_angle)
        :enableLockAspectRatio(data.lock_aspect_ratio)
        :enableRichText(data.rich_text)
end
