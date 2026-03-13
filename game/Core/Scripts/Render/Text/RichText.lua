---@class Core.Render.Text.RichText
local M = {}
Core.Render.Text.RichText = M

local Color = Core.Render.Color
local color = {
    white = Color.White,
    black = Color.Black,
    red = Color.Red,
    green = Color.Green,
    blue = Color.Blue,
    yellow = Color.Yellow,
    magenta = Color.Magenta,
    cyan = Color.Cyan,
    r = Color(0, 255, 130, 130),
    g = Color(0, 130, 255, 130),
    b = Color(0, 130, 130, 255),
    c = Color(0, 130, 255, 255),
    o = Color(0, 255, 255, 130),
    y = Color(0, 255, 227, 132),
    p = Color(0, 255, 130, 255),
    ["-"] = Color(0, 150, 150, 150),
}
local pairs = pairs
local tonumber = tonumber

---@class Core.Render.Text.RichText.Style
---@param style Core.Render.Text.RichText.Style
---@param default Core.Render.Text.RichText.Style
local function set_style(style, target, default)
    for k, v in pairs(default) do
        style[k] = v
    end
    ---@param name string
    ---@param value string
    for name, value in pairs(target) do
        if name == "oblique" or name == "i" then
            style.oblique = true
        elseif name == "shadow" then
            style.shadow = true
        elseif name == "underline" or name == "u" then
            style.underline = true
        elseif name == "strikethrough" or name == "s" then
            style.strikethrough = true
        elseif name == "blend" then
            style.blend = value
        elseif name == "color" or name == "col" then
            local cache = color[value:lower()]
            if cache then
                style.color = Color.Copy(cache)
            else
                style.color = Color(tonumber("FF" .. (value:sub(2) or "FFFFFF"), 16))
            end
            style._color = Color.Copy(style.color)
        elseif name == "alpha" then
            style.alpha = tonumber(value) or default.alpha
            style.color = Color.Copy(style.color)
        elseif name == "size" then
            style.size = tonumber(value) or default.size
        end
    end
end

local function parse_simple_tag(now_style, tag_str)
    -- 去掉 <> 和首尾空格
    local content = tag_str:match("^%s*<([^>]+)>%s*$")
    if not content then
        return nil
    end
    if tag_str:find("^</") then
        local key = content:match("^/%s*(%w+)%s*$")
        now_style[key:lower()] = nil
        return
    end
    -- 提取第一个 key=value（支持任意空格）
    local key, value = content:match("^%s*(%w+)%s*=%s*(.-)%s*$")
    if key then
        -- 去掉可能的引号
        value = value:gsub("^['\"](.-)['\"]$", "%1")
        now_style[key:lower()] = value
        return
    end

    -- 如果没有 =，就是布尔标签如 <b>
    key = content:match("^%s*(%w+)%s*$")
    if key then
        now_style[key:lower()] = true
        return
    end

    return nil
end

local CLEAN_TEXT = {}
---解析富文本数据
---使用GC压力最低的方法
---返回纯净文本
---@param output_list Core.Lib.RichText.Parsed[]
---@param raw_text string
---@param default_style Core.Render.Text.RichText.Style
---@return string
function M.Parse(output_list, raw_text, default_style)
    local list_i = 1
    local text_i = 1
    local now_style = {}
    local i = 1
    local m = 1 -- 纯文本的字符计数（从1开始）
    local function push_run(part)
        CLEAN_TEXT[text_i] = part
        text_i = text_i + 1
        local cur = output_list[list_i]
        if cur then
            cur.start = m
            cur.stop = m + #part - 1
            set_style(cur.style, now_style, default_style)
        else
            ---@class Core.Lib.RichText.Parsed
            local run = {
                start = m,
                stop = m + #part - 1,
                style = {}
            }
            set_style(run.style, now_style, default_style)
            output_list[list_i] = run
        end
        list_i = list_i + 1
        m = m + #part
    end

    while i <= #raw_text do
        local s, e = raw_text:find("<[^<>]+>", i)
        if not s then
            -- 最后一段纯文本
            local part = raw_text:sub(i)
            push_run(part)
            break
        end
        if raw_text:sub(s - 1, s - 1) == "\\" then
            -- 转义符号，不处理
            if s > i then
                local part = raw_text:sub(i, s - 2) .. raw_text:sub(s, e)
                push_run(part)
            end
        else
            -- 标签前的纯文本
            if s > i then
                local part = raw_text:sub(i, s - 1)
                push_run(part)
            end

            -- 处理标签
            local tag_str = raw_text:sub(s, e)
            parse_simple_tag(now_style, tag_str)
        end

        i = e + 1
    end
    for n = list_i, #output_list do
        output_list[n] = nil
    end
    for n = text_i, #CLEAN_TEXT do
        CLEAN_TEXT[n] = nil
    end
    return table.concat(CLEAN_TEXT)
end

