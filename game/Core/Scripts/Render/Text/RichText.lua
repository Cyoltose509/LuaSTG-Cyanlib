---@class Core.Render.Text.RichText
local M = {}
Core.Render.Text.RichText = M

---@class Core.Render.Text.RichText.Style
---@field color Core.Render.Color
---@field size number
---@field oblique boolean
---@field shadow boolean
---@field underline boolean
---@field strikethrough boolean
---@field blend boolean

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
    g = Color(0, 130, 255, 130),
    y = Color(0, 255, 227, 132),
    p = Color(0, 255, 130, 255),
    ["-"] = Color(0, 150, 150, 150),
}

local function current_style(now_style, default)

    ---@type Core.Render.Text.RichText.Style
    local style = {}
    for k, v in pairs(default) do
        style[k] = v
    end
    for name, value in pairs(now_style) do
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
            if color[value:lower()] then
                style.color = Color(color[value:lower()]:ARGB())
            else
                style.color = Color(tonumber("FF" .. (value or "FFFFFF"), 16))
            end
        elseif name == "size" then
            style.size = tonumber(value) or default.size
        end
    end
    return style
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

---@class Core.Lib.RichText.Data
---@field text string
---@field runs Core.Lib.RichText.Parsed[]
---@param raw_text string
---@param default_style Core.Render.Text.RichText.Style
---@return Core.Lib.RichText.Data
function M.Parse(raw_text, default_style)
    local clean_text = {}
    local runs = {}
    local now_style = {}
    local i = 1
    local char_index = 1  -- 纯文本的字符计数（从1开始）

    local function push_run(end_char_index)
        if char_index < end_char_index then
            ---@class Core.Lib.RichText.Parsed
            local run = {
                start = char_index,
                stop = end_char_index - 1,
                style = current_style(now_style, default_style)
            }
            table.insert(runs, run)
            char_index = end_char_index
        end
    end

    while i <= #raw_text do
        local s, e = raw_text:find("<[^>]+>", i)
        if not s then
            -- 最后一段纯文本
            local part = raw_text:sub(i)
            table.insert(clean_text, part)
            push_run(char_index + #part)
            break
        end

        -- 标签前的纯文本
        if s > i then
            local part = raw_text:sub(i, s - 1)
            table.insert(clean_text, part)
            push_run(char_index + #part)
        end

        -- 处理标签
        local tag_str = raw_text:sub(s, e)
        parse_simple_tag(now_style, tag_str)
        i = e + 1
    end

    return {
        text = table.concat(clean_text),
        runs = runs
    }
end

