---@class Core.Render.Text
---@field RichText Core.Render.Text.RichText
---@field CJKBreak Core.Render.Text.CJKBreak
-----------------------------------------------
---竭尽全力实现的极其完善的文本渲染系统
---目前支持的功能有：缩放，行高，阴影，斜体，旋转 (2D/3D)，对齐方式，自动换行，自动适应，混合模式，富文本
---并且会在设置各种参数之后仅进行一次重要计算，大大减少计算量，提高渲染效率
---富文本目前支持颜色，相对大小，斜体，阴影，下划线，删除线，混合模式
---A highly sophisticated text rendering system
---which supports scaling, line height, shadow, italic, rotation (2D/3D), alignment, automatic line breaks, automatic adaptation, blend mode, and rich text.
---Moreover, it will perform only one important calculation after setting various parameters,
---greatly reducing the calculation amount, improving rendering efficiency.
---Rich text currently supports color, relative size, italic, shadow, underline, strikethrough, and blend mode.
---
---示例：（详情请看RichText模块）
---Examples: (Please see the RichText module for details)
---"\\<xxx>" -- 反斜杠转义
---"Hello <color=#FF0000>world</color>!"
---"你好，<col=red>世界</col>！"
---"こんにちは、<s=0.8>世界</s>！"
---"안녕하세요, <u>세계</u>!"
---"salut, <i>le monde</i>!"
local M = Core.Class()
Core.Render.Text = M

M.DEFAULT_FONT = "heiti"
M.DEFAULT_SIZE = 16
M.DEFAULT_COLOR = Core.Render.Color.Default
M.DEFAULT_OBLIQUE_ANGLE = 12

M.DEFAULT_SHADOW_COLOR = Core.Render.Color.Black
M.DEFAULT_SHADOW_DIR_X = 4
M.DEFAULT_SHADOW_DIR_Y = -3
M.DEFAULT_SHADOW_DIV = 4

M.DEFAULT_UNDERLINE_WIDTH = 2
M.DEFAULT_UNDERLINE_Y_OFFSET = 4
M.DEFAULT_UNDERLINE_Y_FACTOR = 0

M.DEFAULT_STRIKE_WIDTH = 2
M.DEFAULT_STRIKE_Y_OFFSET = 0
M.DEFAULT_STRIKE_Y_FACTOR = -0.32

require("Core.Scripts.Render.Text.RichText")
require("Core.Scripts.Render.Text.CJKBreak")

function M:init()
    self.text = ""
    self.font = M.DEFAULT_FONT
    self.font_res = Core.Resource.TTF.Get(self.font)
    self.color = M.DEFAULT_COLOR
    self.h_align = 0.5
    self.v_align = 0.5
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
    self.size = M.DEFAULT_SIZE
    self.hscale, self.vscale = 1, 1
    self.blend = Core.Render.BlendMode.Default
    self.shadow_params = {
        enabled = false,
        color = M.DEFAULT_SHADOW_COLOR,
        dir_x = M.DEFAULT_SHADOW_DIR_X,
        dir_y = M.DEFAULT_SHADOW_DIR_Y,
        div = M.DEFAULT_SHADOW_DIV,
    }
    self.roll = 0
    self.pitch = 0
    self.yaw = 0
    self.is_oblique = false
    self.oblique_angle = M.DEFAULT_OBLIQUE_ANGLE
    self.lock_aspect_ratio = false
    self.rect_anchor = false
    self.rect_anchor_x, self.rect_anchor_y = 0.5, 0.5
    self.underline_params = {
        width = M.DEFAULT_UNDERLINE_WIDTH,
        y = M.DEFAULT_UNDERLINE_Y_OFFSET,
        y_factor = M.DEFAULT_UNDERLINE_Y_FACTOR,
    }
    self.strikethrough_params = {
        width = M.DEFAULT_STRIKE_WIDTH,
        y = M.DEFAULT_STRIKE_Y_OFFSET,
        y_factor = M.DEFAULT_STRIKE_Y_FACTOR,
    }

    self._text_segments = {}
    ---@type Core.Lib.RichText.Parsed[]
    self._rich_text_data = {}
    ---@type Core.Render.Text.Line[]
    self._lines = {}
    self._real_hscale = 1
    self._real_vscale = 1
    self._fit_height_scale = 1
    --self._line_height = 0
    self._total_width = 0
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
---在size的基础上设置横纵比
---Set the aspect ratio based on the size
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

---设置行间距倍数
---Set the line height factor
function M:setLineHeightFactor(f)
    self.line_height_factor = f or 1
    self._lines_dirty = true
    return self
end

---设置坐标
---Set the coordinates
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

---设置文本框大小
---Set the size of the text box
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

---设置对齐模式
---参考原来的format参数，支持left, right, center, top, bottom, vcenter, centerpoint
---Set the alignment mode
---Refer to the original format parameter, support left, right, center, top, bottom, vcenter, centerpoint
function M:setAlignment(...)
    local befHalign, befValign = self.h_align, self.v_align
    for _, v in ipairs({ ... }) do
        if v == "left" then
            self.h_align = 0
        elseif v == "right" then
            self.h_align = 1
        elseif v == "center" then
            self.h_align = 0.5
        elseif v == "top" then
            self.v_align = 1
        elseif v == "bottom" then
            self.v_align = 0
        elseif v == "vcenter" then
            self.v_align = 0.5
        elseif v == "centerpoint" then
            self.h_align = 0.5
            self.v_align = 0.5
        end
    end
    if befHalign ~= self.h_align or befValign ~= self.v_align then
        self._anchor_dirty = true
    end
    return self
end

---设置对齐值
---0,0为左上角，1,1为右下角，0.5,0.5为中心
---Set the alignment value
---0,0 is the upper left corner, 1,1 is the lower right corner, 0.5,0.5 is the center
function M:setAlignValue(h, v)
    h = h or self.h_align
    v = v or self.v_align
    if h ~= self.h_align or v ~= self.v_align then
        self.h_align = h
        self.v_align = v
        self._anchor_dirty = true
    end
    return self
end

---设置矩形锚点位置，仅当enableRectAnchor时有效
---0,0为左上角，1,1为右下角，0.5,0.5为中心
---Set the position of the rectangular anchor, which is valid only when enableRectAnchor
---0,0 is the upper left corner, 1,1 is the lower right corner, 0.5,0.5 is the center
function M:setRectAnchorPos(x, y)
    x = x or self.rect_anchor_x
    y = y or self.rect_anchor_y
    if x ~= self.rect_anchor_x or y ~= self.rect_anchor_y then
        self.rect_anchor_x = x
        self.rect_anchor_y = y
        if self.rect_anchor then
            self._anchor_dirty = true
        end
    end
    return self
end

---设置下划线高度偏移
---Set the height offset of the underline
function M:setUnderlineY(y)
    self.underline_params.y = y or M.DEFAULT_UNDERLINE_Y_OFFSET
    return self
end

---设置下划线相对于字体高度的倍数
---Set the multiple of the font height for the underline
function M:setUnderlineYFactor(y_f)
    self.underline_params.y_factor = y_f or M.DEFAULT_UNDERLINE_Y_FACTOR
    return self
end

---设置下划线宽度
---Set the width of the underline
function M:setUnderlineWidth(w)
    self.underline_params.width = w or M.DEFAULT_UNDERLINE_WIDTH
    return self
end

---设置删除线高度偏移
---Set the height offset of the strikethrough
function M:setStrikethroughY(y)
    self.strikethrough_params.y = y or M.DEFAULT_STRIKE_Y_OFFSET
    return self
end

---设置删除线相对于字体高度的倍数
---Set the multiple of the font height for the strikethrough
function M:setStrikethroughYFactor(y_f)
    self.strikethrough_params.y_factor = y_f or M.DEFAULT_STRIKE_Y_FACTOR
    return self
end

---设置删除线宽度
---Set the width of the strikethrough
function M:setStrikethroughWidth(w)
    self.strikethrough_params.width = w or M.DEFAULT_STRIKE_WIDTH
    return self
end
---设置斜体角度
---Set the oblique angle
function M:setObliqueAngle(ang)
    self.oblique_angle = ang or M.DEFAULT_OBLIQUE_ANGLE
    self._vector_dirty = true
    return self
end

---设置3D旋转角
---Set the 3D rotation angle
function M:setRotation3D(pitch, yaw, roll)
    self.roll = roll or 0
    self.pitch = pitch or 0
    self.yaw = yaw or 0
    self._anchor_dirty = true
    self._vector_dirty = true
    return self
end

---设置平面旋转（会自动清零3D旋转）
---Set the plane rotation (will automatically clear the 3D rotation)
function M:setRotation(rot)
    self.roll = rot or 0
    self.pitch = 0
    self.yaw = 0
    self._anchor_dirty = true
    self._vector_dirty = true
    return self
end

---设置阴影颜色
---Set the shadow color
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

---设置阴影方向
---Set the shadow direction
function M:setShadowDirection(dir_x, dir_y)
    local P = self.shadow_params
    P.dir_x = dir_x or P.dir_x
    P.dir_y = dir_y or P.dir_y
    return self
end

---设置阴影分割数
---Set the number of shadow divisions
function M:setShadowDiv(div)
    local P = self.shadow_params
    P.div = div or P.div
    return self
end

---设置文本颜色
---Set the text color
---@param color Core.Render.Color
function M:setColor(color)
    self.color = color or Core.Render.Color.Default
    self.shadow_params.color.a = self.color.a
    self:refreshColor()
    return self
end

---设置混合模式
---Set the blend mode
function M:setBlendMode(blend)
    self.blend = blend or Core.Render.BlendMode.Default
    return self
end

---设置文本
---Set the text
function M:setText(text)
    text = text or ""
    if text ~= self.text then
        self.text = text
        self:refreshTextSegments()
    end
    return self
end

---设置字体
---Set the font
function M:setFont(font)
    if font ~= nil and self.font ~= font then
        self.font = font
        self.font_res = Core.Resource.TTF.Get(font)
        if not self.font_res then
            Core.System.Log(Core.System.LogType.Warning, "Core.Render.Text: Font not found: " .. tostring(font))
            self.font = M.DEFAULT_FONT
            self.font_res = Core.Resource.TTF.Get(self.font)
        end
        self._size_dirty = true
    end
    return self
end

---设置字号（注意不是相对于加载字体的大小）
---Set the font size (attention: not the size relative to the loaded font size)
function M:setSize(size)
    size = size or 16
    if size ~= self.size then
        self.size = size
        self._size_dirty = true
    end
    return self
end

---设置是否运用矩形锚点
---默认不运用，矩形位置会根据对齐方式偏移
---若运用，则矩形位置不会偏移，而是会根据锚点位置进行定位
---Set whether to use the rectangular anchor
---By default, it is not used, the position of the rectangle will be offset according to the alignment
---If used, the position of the rectangle will not be offset, but will be located based on the anchor position
function M:enableRectAnchor(enable)
    if self.rect_anchor ~= enable then
        self.rect_anchor = enable or false
        self._anchor_dirty = true
    end
    return self
end

---设置是否锁定横纵比
---若锁定，则文字大小会根据宽度和高度的最小值进行缩放，以保持长宽比
---Set whether to lock the aspect ratio
---If locked, the text size will be scaled based on the minimum value of width and height to maintain the aspect ratio
function M:enableLockAspectRatio(enable)
    self.lock_aspect_ratio = enable or false
    return self
end

---设置是否自动换行（会破坏长单词）
---Set whether to wrap the text automatically (will break long words)
function M:enableWordBreak(enable)
    if enable ~= self.word_break then
        self.word_break = enable
        self._lines_dirty = true
    end
    return self
end

---设置是否自动换行（不会破坏长单词）
---Set whether to wrap the text automatically (will not break long words)
function M:enableWrapWord(enable)
    if enable ~= self.wrap_word then
        self.wrap_word = enable
        self:refreshTextSegments()
    end
    return self
end

---设置是否支持富文本
---Set whether to support rich text
function M:enableRichText(enable)
    if enable ~= self.rich_text then
        self.rich_text = enable
        self:refreshTextSegments()
    end
    return self
end

---设置是否自动适应宽度或高度
---Set whether to automatically adapt the width or height
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

---设置是否开启阴影
---Set whether to enable the shadow
function M:enableShadow(enable)
    self.shadow_params.enabled = enable or false
    return self
end

---设置是否开启斜体
---Set whether to enable oblique
function M:enableOblique(enable)
    self.is_oblique = enable or false
    self._vector_dirty = true
    return self
end

---@private
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
            alpha = 1,
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
---@private
function M:refreshSize()
    local s = self.size / self.font_res:getSize()
    self._real_hscale = self.hscale * s
    self._real_vscale = self.vscale * s * self._fit_height_scale
    self._lines_dirty = true
end
---@private
function M:refreshColor()
    for _, line in ipairs(self._lines) do
        for _, data in ipairs(line.data) do
            if data.style and data.style.color then
                data.style.color.a = self.color.a * data.style.alpha
                if not data.style.custom_color then
                    data.style.color.r = self.color.r
                    data.style.color.g = self.color.g
                    data.style.color.b = self.color.b
                end
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
    local rich_data = Core.Lib.Table.Copy(self._rich_text_data)
    local text = self._text_segments
    ---@type Core.Render.Text.Line[]
    local lines = {}
    ---@type Core.Render.Text.Word[]
    local word_buf = {}
    local total_width = self.width
    local line_width = 0
    local line_height = 0
    local tok_buf = {}
    local word_width = 0
    local word_height = 0
    local total_height = 0
    local success = true
    local i = 1
    local byte_i = 0
    ---@type Core.Render.Text.RichText.Style
    local style
    local lh = fr.GetFontLineHeight()
    local asc = fr.GetFontAscender()
    local _real_asc = 0
    local function next_tok(tok, tw, th, size)
        table.insert(tok_buf, tok)
        word_width = word_width + tw
        line_width = line_width + tw
        total_width = max(total_width, line_width)
        line_height = max(line_height, th)
        word_height = max(word_height, th)
        if #lines == 0 then
            _real_asc = max(_real_asc, vs * size * asc)
        end
        i = i + 1
    end
    local function next_word()
        ---@class Core.Render.Text.Word
        local word = {
            text = table.concat(tok_buf),
            style = style,
            width = word_width,
            height = word_height,
        }
        table.insert(word_buf, word)
        tok_buf = {}
        word_width = 0
        word_height = 0
    end
    local function next_line()
        next_word()
        ---@class Core.Render.Text.Line
        local line = {
            width = line_width,
            height = line_height,
            data = word_buf,
        }
        -- print(curWidth, curHeight, smallWidth, smallHeight)
        table.insert(lines, line)
        total_height = total_height + line_height
        line_height = 0
        word_buf = {}
        line_width = 0
    end

    while i <= #text do
        local tok = text[i]
        byte_i = byte_i + #tok
        if rich_data and #rich_data > 0 then
            local run = rich_data[1]
            if run.start <= byte_i and byte_i <= run.stop then
                next_word()
                style = run.style
                table.remove(rich_data, 1)
            end
        end
        if tok == "\n" then
            next_line()
            i = i + 1
        else
            local size = style and style.size or 1
            fr.SetScale(hs * size, vs * size)
            local tw = fr.MeasureTextAdvance(tok)
            local th = size * vs * lh

            if tok ~= "" and tw == 0 then
                success = false
            end
            if self.word_break or self.wrap_word then
                if line_width + tw > self.width then
                    next_line()
                end
                next_tok(tok, tw, th, size)
            else
                next_tok(tok, tw, th, size)
            end
        end
    end
    if #tok_buf > 0 then
        next_line()
    end
    self._lines = lines
    self._total_height = total_height
    self._total_width = total_width
    self._ascender = _real_asc
    self:refreshColor()
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
    local startY = -self._ascender + (1 - self.v_align) * self._total_height
    local startX = 0
    if self.rect_anchor then
        startX = startX + (self.h_align - self.rect_anchor_x) * self.width * self.hscale
        startY = startY + (self.v_align - self.rect_anchor_y) * self.height * self.vscale * self._fit_height_scale
    end
    local x, y, z = startX, startY, 0
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
function M:update()
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
end
function M:draw(no_update)
    if not no_update then
        self:update()
    end
    local fr = lstg.FontRenderer
    fr.SetFontProvider(self.font)
    local hs, vs = self._real_hscale, self._real_vscale * self._fit_height_scale

    local xv, yv = self._xVector, self._yVector
    local wv = self._writeVector
    local _x = self._anchorX
    local _y = self._anchorY
    local _z = self._anchorZ
    local P = self.shadow_params
    for k, line in ipairs(self._lines) do
        local x = _x
        local y = _y
        local z = _z
        local lw = line.width
        local index = self.auto_fit_width and min(self.width / lw, 1) or 1
        local xoffset = -self.h_align * lw * index
        x = x + xv[1] * xoffset
        y = y + xv[2] * xoffset
        z = z + xv[3] * xoffset

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
            local hsize, vsize = hs * index * size, vs * size
            if self.lock_aspect_ratio then
                local m = min(hs * index, vs)
                hsize, vsize = m * size, m * size
            end
            fr.SetScale(hsize, vsize)
            local blend = style and style.blend or self.blend
            if style and style.shadow or P.enabled then
                for i = 1, P.div do
                    local dx = P.dir_x * i / P.div * hsize * self.size / 15
                    local dy = P.dir_y * i / P.div * vsize * self.size / 15
                    fr.RenderTextInSpace(data.text, x + dx, y + dy, z, xv[1], xv[2], xv[3], y1, y2, y3,
                            blend, P.color * (1 - i / P.div))
                end
            end
            fr.RenderTextInSpace(data.text, x, y, z, xv[1], xv[2], xv[3], y1, y2, y3, blend, _color)
            if style and style.underline then
                local up = self.underline_params
                local w = up.width / 2
                local h = up.y + up.y_factor * dh
                draw_line(x, y, z, x + dw * xv[1], y + dw * xv[2], z + dw * xv[3], wv,
                        h - w, h + w, blend, _color)
            end
            if style and style.strikethrough then
                local sp = self.strikethrough_params
                local w = sp.width / 2
                local h = sp.y + sp.y_factor * dh
                draw_line(x, y, z, x + dw * xv[1], y + dw * xv[2], z + dw * xv[3], wv,
                        h - w, h + w, blend, _color)
            end
            x = x + dw * xv[1] * index
            y = y + dw * xv[2] * index
            z = z + dw * xv[3] * index
        end
        if self._lines[k + 1] then
            local h = self._lines[k + 1].height
            _x = _x + h * wv[1]
            _y = _y + h * wv[2]
            _z = _z + h * wv[3]
        end
    end

end

function M:getContentSize()
    return self._total_width, self._total_height
end

function M:serialize()
    return {
        text = self.text,
        font = self.font,
        color = tostring(self.color),
        h_align = self.h_align,
        v_align = self.v_align,
        rect_anchor = self.rect_anchor,
        rect_anchor_x = self.rect_anchor_x,
        rect_anchor_y = self.rect_anchor_y,
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
            dir_x = self.shadow_params.dir_x,
            dir_y = self.shadow_params.dir_y,
        },
        is_oblique = self.is_oblique,
        oblique_angle = self.oblique_angle,
        lock_aspect_ratio = self.lock_aspect_ratio,
        underline_params = {
            width = self.underline_params.width,
            y_factor = self.underline_params.y_factor,
            y = self.underline_params.y,
        },
        strikethrough_params = {
            width = self.strikethrough_params.width,
            y_factor = self.strikethrough_params.y_factor,
            y = self.strikethrough_params.y,
        }
    }
end
---@param data Core.Render.Text
function M:deserialize(data)
    self:setText(data.text)
        :setFont(data.font)
        :setColor(Core.Render.Color.Parse(data.color))
        :setAlignValue(data.h_align, data.v_align)
        :setRectAnchorPos(data.rect_anchor_x, data.rect_anchor_y)
        :setRect(data.width, data.height)
        :setPosition(data.x, data.y, data.z)
        :setRotation3D(data.pitch, data.yaw, data.roll)
        :setLineHeightFactor(data.line_height_factor)
        :setSize(data.size)
        :setScale(data.hscale, data.vscale)
        :setBlendMode(data.blend)
        :setShadowColor(Core.Render.Color.Parse(data.shadow_params.color))
        :setShadowDiv(data.shadow_params.div)
        :setShadowDirection(data.shadow_params.dir_x, data.shadow_params.dir_y)
        :setObliqueAngle(data.oblique_angle)
        :setUnderlineWidth(data.underline_params.width)
        :setUnderlineYFactor(data.underline_params.y_factor)
        :setUnderlineY(data.underline_params.y)
        :setStrikethroughWidth(data.strikethrough_params.width)
        :setStrikethroughYFactor(data.strikethrough_params.y_factor)
        :setStrikethroughY(data.strikethrough_params.y)

        :enableRectAnchor(data.rect_anchor)
        :enableWordBreak(data.word_break)
        :enableWrapWord(data.wrap_word)
        :enableAutoFit(data.auto_fit_width, data.auto_fit_height)
        :enableShadow(data.shadow_params.enabled)
        :enableOblique(data.is_oblique)
        :enableLockAspectRatio(data.lock_aspect_ratio)
        :enableRichText(data.rich_text)
end
