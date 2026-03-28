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

local Core = Core
local min, max = min, max
local table = table
local sin, cos, tan = sin, cos, tan
local Color = Core.Render.Color
local tostring = tostring
local ipairs = ipairs

M.DEFAULT_FONT = "heiti"
M.DEFAULT_SIZE = 16
M.DEFAULT_COLOR = Color.Default
M.DEFAULT_OBLIQUE_ANGLE = 12

M.DEFAULT_SHADOW_COLOR = Color.Black
M.DEFAULT_SHADOW_DIR_X = 8
M.DEFAULT_SHADOW_DIR_Y = -6
M.DEFAULT_SHADOW_DIV = 4

M.DEFAULT_UNDERLINE_WIDTH = 0.04
M.DEFAULT_UNDERLINE_Y_OFFSET = 4
M.DEFAULT_UNDERLINE_Y_FACTOR = 0

M.DEFAULT_STRIKE_WIDTH = 0.04
M.DEFAULT_STRIKE_Y_OFFSET = 0
M.DEFAULT_STRIKE_Y_FACTOR = -0.32

require("Core.Scripts.Render.Text.RichText")
require("Core.Scripts.Render.Text.CJKBreak")

function M:init()
    self.text = ""
    self.font = M.DEFAULT_FONT
    self.font_res = Core.Resource.TTF.Get(self.font)
    self.color = Color.Copy(M.DEFAULT_COLOR)
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
    self._auto_w_scale = 1
    self._auto_h_scale = 1
    self.size = M.DEFAULT_SIZE
    self.hscale, self.vscale = 1, 1
    self.blend = Core.Render.BlendMode.Default
    self.shadow_params = {
        enabled = false,
        color = Color.Copy(M.DEFAULT_SHADOW_COLOR),
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
        enabled = false,
        width = M.DEFAULT_UNDERLINE_WIDTH,
        y = M.DEFAULT_UNDERLINE_Y_OFFSET,
        y_factor = M.DEFAULT_UNDERLINE_Y_FACTOR,
    }
    self.strikethrough_params = {
        enabled = false,
        width = M.DEFAULT_STRIKE_WIDTH,
        y = M.DEFAULT_STRIKE_Y_OFFSET,
        y_factor = M.DEFAULT_STRIKE_Y_FACTOR,
    }

    self._real_text = ""
    self._text_segments = {}
    ---@type Core.Lib.RichText.Parsed[]
    self._rich_text_data = {}
    ---@type Core.Render.Text.Line[]
    self._lines = {}
    ---其实这是一个field对象池
    ---@type Core.Render.Text.Field[]
    self._text_fields = {}
    self._real_hscale = 1
    self._real_vscale = 1
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
    self._default_style = {
        color = self.color,
        size = 1,
        oblique = self.is_oblique,
        shadow = self.shadow_params.enabled,
        underline = self.underline_params.enabled,
        strikethrough = self.strikethrough_params.enabled,
        blend = self.blend,
        alpha = 1,
    }
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
    text = tostring(text)
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
            Core.System.Log(Core.System.LogType.Warning, "Core.Render.Text: Font not found: " .. font)
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
    if size ~= self.size and size ~= 0 then
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
    enable = enable or false
    if self.auto_fit_width or self.auto_fit_height then
        if self.lock_aspect_ratio ~= enable then
            self.lock_aspect_ratio = enable
            self._auto_w_scale = 1
            self._auto_h_scale = 1
            self._lines_dirty = true
        end
    else
        self.lock_aspect_ratio = enable or false
    end
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
    width = width or false
    height = height or false
    if width ~= self.auto_fit_width or height ~= self.auto_fit_height then
        self.auto_fit_width = width
        self.auto_fit_height = height
        self._lines_dirty = true
    end
    return self
end

---设置是否开启阴影
---Set whether to enable the shadow
function M:enableShadow(enable)
    self.shadow_params.enabled = enable or false
    return self
end

---设置是否开启下划线
---Set whether to enable the underline
function M:enableUnderline(enable)
    self.underline_params.enabled = enable or false
    return self
end

---设置是否开启删除线
---Set whether to enable the strikethrough
function M:enableStrikethrough(enable)
    self.strikethrough_params.enabled = enable or false
    return self
end

---设置是否开启斜体
---Set whether to enable oblique
function M:enableOblique(enable)
    self.is_oblique = enable or false
    self._vector_dirty = true
    return self
end

function M:cacheString()
    if self.font_res then
        self.font_res:cacheString(self._real_text)
    end
    return self
end

---@private
function M:refreshTextSegments()
    --self._text_segments = {}
    local text = self.text
    if self.rich_text then
        local ds = self._default_style
        ds.color = self.color
        ds.oblique = self.is_oblique
        ds.shadow = self.shadow_params.enabled
        ds.underline = self.underline_params.enabled
        ds.strikethrough = self.strikethrough_params.enabled
        ds.blend = self.blend
        text = M.RichText.Parse(self._rich_text_data, text, ds)
    end
    self._real_text = text
    if self.wrap_word then
        M.CJKBreak.Tokenize(self._text_segments, text)
    else
        M.CJKBreak.SplitUTF8(self._text_segments, text)
        --self._text_segments = segText(text)
    end
    self._lines_dirty = true
end

---@private
function M:refreshSize()
    local s = self.size / self.font_res:getSize()
    self._real_hscale = self.hscale * s
    self._real_vscale = self.vscale * s
    self._lines_dirty = true
end
---@private
function M:refreshColor()
    for _, line in ipairs(self._lines) do
        for _, data in ipairs(line.data) do
            if data.style and data.style.color then
                data.style.color.a = self.color.a * data.style.alpha
                if not data.style._color then
                    data.style.color.r = self.color.r
                    data.style.color.g = self.color.g
                    data.style.color.b = self.color.b
                else
                    data.style.color.r = self.color.r / 255 * data.style._color.r
                    data.style.color.g = self.color.g / 255 * data.style._color.g
                    data.style.color.b = self.color.b / 255 * data.style._color.b
                end
            end
        end
    end
end

local SEG_TOK = {}
local WORD_BUF = {}
local WORD_CACHE_BUF = {}
---@type Core.Render.Text.Field[]
local FIELD_CACHE_BUF = {}
---@private
function M:refreshLines(second)
    local fr = lstg.FontRenderer
    fr.SetFontProvider(self.font)
    local hs, vs = self._real_hscale * self._auto_w_scale, self._real_vscale * self._auto_h_scale
    fr.SetScale(hs, vs)
    local rich_data = self._rich_text_data
    local rich_data_i = 1
    local text_seg = self._text_segments

    local total_height = 0
    local total_width = self.width

    local lh = fr.GetFontLineHeight() * self.line_height_factor
    local asc = fr.GetFontAscender()

    local lines = self._lines
    local line_pos = 1
    local line_width = 0
    local line_height = 0

    local field_buf = self._text_fields
    local last_field_pos = 1
    local field_pos = 1
    local field_width = 0
    local field_height = 0

    local field_cache_width = 0
    local field_cache_height = 0

    local word_pos = 1

    local word_cache_pos = 1
    local word_cache_width = 0
    local word_cache_height = 0

    local success = true
    local i = 1
    local byte_i = 0
    ---@type Core.Render.Text.RichText.Style
    local style

    local _real_asc = 0
    local function merge_word()
        for m = 1, word_cache_pos - 1 do
            WORD_BUF[word_pos] = WORD_CACHE_BUF[m]
            word_pos = word_pos + 1
            WORD_CACHE_BUF[m] = nil
        end
        field_width = field_width + word_cache_width
        field_height = max(field_height, word_cache_height)
        word_cache_width = 0
        word_cache_height = 0
        word_cache_pos = 1
    end
    local function merge_field()
        for m = 1, #FIELD_CACHE_BUF do
            field_buf[field_pos] = FIELD_CACHE_BUF[m]
            FIELD_CACHE_BUF[m] = nil
            field_pos = field_pos + 1
        end
        line_width = line_width + field_cache_width
        line_height = max(line_height, field_cache_height)
        field_cache_width = 0
        field_cache_height = 0
    end
    local function next_field()
        if word_pos > 1 then
            for m = word_pos, #WORD_BUF do
                WORD_BUF[m] = nil
            end
            local cur = field_buf[field_pos]
            if cur then
                cur.text = table.concat(WORD_BUF)
                cur.style = style
                cur.width = field_width
                cur.height = field_height
            else
                ---@class Core.Render.Text.Field
                local field = {
                    text = table.concat(WORD_BUF),
                    style = style,
                    width = field_width,
                    height = field_height,
                }
                field_buf[field_pos] = field
            end
            field_pos = field_pos + 1
            line_width = line_width + field_width
            line_height = max(line_height, field_height)
            field_width = 0
            field_height = 0
            word_pos = 1
        end
    end
    local function cache_field()
        if word_cache_pos > 1 then
            for m = word_cache_pos, #WORD_CACHE_BUF do
                WORD_CACHE_BUF[m] = nil
            end
            local field_cache = {
                text = table.concat(WORD_CACHE_BUF),
                style = style,
                width = word_cache_width,
                height = word_cache_height,
            }
            FIELD_CACHE_BUF[#FIELD_CACHE_BUF + 1] = field_cache
            field_cache_width = field_cache_width + word_cache_width
            field_cache_height = max(field_cache_height, word_cache_height)
            -- line_height = max(line_height, word_height)
            --line_width = line_width + word_width
            word_cache_width = 0
            word_cache_height = 0
            word_cache_pos = 1
        end
    end
    local function next_line()
        next_field()
        if line_height == 0 then
            --空行的情况
            local size = style and style.size or 1
            line_height = size * vs * lh
        end
        local cur = lines[line_pos]
        if cur then
            cur.width = line_width
            cur.height = line_height
            local data = cur.data
            local n = 1
            for m = last_field_pos, field_pos - 1 do
                data[n] = field_buf[m]
                n = n + 1
            end
            for m = n, #cur.data do
                data[m] = nil
            end
        else
            local data = {}
            ---@class Core.Render.Text.Line
            local line = {
                width = line_width,
                height = line_height,
                data = data,
            }
            local n = 1
            for m = last_field_pos, field_pos - 1 do
                data[n] = field_buf[m]
                n = n + 1
            end
            lines[line_pos] = line
        end
        line_pos = line_pos + 1
        total_width = max(total_width, line_width)
        total_height = total_height + line_height
        line_height = 0
        line_width = 0
        last_field_pos = field_pos
        --field_buf = {}
    end

    while i <= #text_seg do
        local tok = text_seg[i]
        M.CJKBreak.SplitUTF8(SEG_TOK, tok)
        local has_next_line = false
        for j = 1, #SEG_TOK do
            local seg = SEG_TOK[j]
            byte_i = byte_i + #seg
            if rich_data then
                local run = rich_data[rich_data_i]
                if run and run.start <= byte_i and byte_i <= run.stop then
                    if style then
                        next_field()
                        cache_field()
                    end
                    style = run.style
                    local size = style and style.size or 1
                    fr.SetScale(hs * size, vs * size)
                    rich_data_i = rich_data_i + 1
                end
            end
            if seg == "\n" then
                merge_word()
                merge_field()
                next_line()
                --i = i + 1
            else
                local size = style and style.size or 1
                local th = size * vs * lh
                if line_pos == 1 then
                    _real_asc = max(_real_asc, vs * size * asc)
                end
                local tw = fr.MeasureTextAdvance(seg)
                if seg ~= "" and tw == 0 then
                    success = false
                end
                if self.word_break or self.wrap_word then
                    if line_width + field_width + word_cache_width + tw > self.width then
                        if not has_next_line then
                            next_line()
                            has_next_line = true
                        elseif not self.auto_fit_height then
                            merge_word()
                            merge_field()
                            next_line()
                        end
                    end
                end
                WORD_CACHE_BUF[word_cache_pos] = seg
                word_cache_pos = word_cache_pos + 1
                word_cache_width = word_cache_width + tw
                word_cache_height = max(word_cache_height, th)
            end
        end
        merge_word()
        merge_field()
        i = i + 1
    end
    if word_pos > 1 then
        next_line()
    end
    for m = line_pos, #lines do
        lines[m] = nil
    end
    self._total_height = total_height
    self._total_width = total_width
    self._ascender = _real_asc
    self:refreshColor()
    if not second then
        local fh = self.auto_fit_width and min(1, self.width / self._total_width) or 1
        local fv = self.auto_fit_height and min(1, self.height / self._total_height) or 1
        if self.lock_aspect_ratio then
            local m = min(fh, fv)
            fh = m
            fv = m
        end
        if fh < 0.99 or fv < 0.99 then
            self._auto_w_scale = fh
            self._auto_h_scale = fv
            self:refreshLines(true)
        end
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
        startY = startY + (self.v_align - self.rect_anchor_y) * self.height * self.vscale
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
    local w1, w2, w3 = wv[1], wv[2], wv[3]
    Draw.SetState(blend, color)
    Draw.Quad(
            x1 + h0 * w1, y1 + h0 * w2, z1 + h0 * w3,
            x2 + h0 * w1, y2 + h0 * w2, z2 + h0 * w3,
            x2 + h1 * w1, y2 + h1 * w2, z2 + h1 * w3,
            x1 + h1 * w1, y1 + h1 * w2, z1 + h1 * w3)
end
function M:update()
    if self._size_dirty then
        self:refreshSize()
        self._size_dirty = false
    end
    if self._lines_dirty then
        self._auto_w_scale = 1
        self._auto_h_scale = 1
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
    return self
end
--TODO 如何减少drawcall
function M:draw(no_update)
    if not no_update then
        self:update()
    end
    local fr = lstg.FontRenderer
    fr.SetFontProvider(self.font)
    local hs, vs = self._real_hscale * self._auto_w_scale, self._real_vscale * self._auto_h_scale
    local real_s = self.size

    local xv, yv = self._xVector, self._yVector
    local wv = self._writeVector
    local _x = self._anchorX
    local _y = self._anchorY
    local _z = self._anchorZ
    local shadow_p = self.shadow_params
    local underline_p = self.underline_params
    local strikethrough_p = self.strikethrough_params
    for k, line in ipairs(self._lines) do
        local x = _x
        local y = _y
        local z = _z
        local lw = line.width
        local xoffset = -self.h_align * lw
        x = x + xv[1] * xoffset
        y = y + xv[2] * xoffset
        z = z + xv[3] * xoffset

        for _, data in ipairs(line.data) do
            local dw, dh = data.width, data.height
            local style = data.style
            local size = style and style.size or 1
            local _color = style and style.color or self.color
            local blend = style and style.blend or self.blend
            local y1, y2, y3 = wv[1], wv[2], wv[3]
            if style and style.oblique or self.is_oblique then
                y1, y2, y3 = yv[1], yv[2], yv[3]
            end
            local x1, x2, x3 = xv[1], xv[2], xv[3]
            local hsize, vsize = hs * size, vs * size
            if self.lock_aspect_ratio then
                local m = min(hs, vs)
                hsize, vsize = m * size, m * size
            end
            fr.SetScale(hsize, vsize)

            if style and style.shadow or shadow_p.enabled then
                for i = 1, shadow_p.div do
                    local c = i / shadow_p.div
                    local dx = shadow_p.dir_x * hsize * c
                    local dy = shadow_p.dir_y * vsize * c
                    fr.RenderTextInSpace(data.text, x + dx, y + dy, z, x1, x2, x3, y1, y2, y3,
                            blend, shadow_p.color * (1 - c))
                end
            end
            fr.RenderTextInSpace(data.text, x, y, z, x1, x2, x3, y1, y2, y3, blend, _color)
            if style and style.underline or underline_p.enabled then
                local w = underline_p.width * 0.5 * size * real_s
                local h = underline_p.y + underline_p.y_factor * dh
                draw_line(x, y, z, x + dw * x1, y + dw * x2, z + dw * x3, wv,
                        h - w, h + w, blend, _color)
            end
            if style and style.strikethrough or strikethrough_p.enabled then
                local w = strikethrough_p.width * 0.5 * size * real_s
                local h = strikethrough_p.y + strikethrough_p.y_factor * dh
                draw_line(x, y, z, x + dw * x1, y + dw * x2, z + dw * x3, wv,
                        h - w, h + w, blend, _color)
            end
            x = x + dw * x1
            y = y + dw * x2
            z = z + dw * x3
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
            enabled = self.underline_params.enabled,
            width = self.underline_params.width,
            y_factor = self.underline_params.y_factor,
            y = self.underline_params.y,
        },
        strikethrough_params = {
            enabled = self.strikethrough_params.enabled,
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
        :enableShadow(data.shadow_params.enabled)

        :setUnderlineWidth(data.underline_params.width)
        :setUnderlineYFactor(data.underline_params.y_factor)
        :setUnderlineY(data.underline_params.y)
        :enableUnderline(data.underline_params.enabled)

        :setStrikethroughWidth(data.strikethrough_params.width)
        :setStrikethroughYFactor(data.strikethrough_params.y_factor)
        :setStrikethroughY(data.strikethrough_params.y)
        :enableStrikethrough(data.strikethrough_params.enabled)


        :setObliqueAngle(data.oblique_angle)
        :enableOblique(data.is_oblique)
        :enableRectAnchor(data.rect_anchor)
        :enableWordBreak(data.word_break)
        :enableWrapWord(data.wrap_word)
        :enableAutoFit(data.auto_fit_width, data.auto_fit_height)


        :enableLockAspectRatio(data.lock_aspect_ratio)
        :enableRichText(data.rich_text)
end
