---@class Core.Render.Text.CJKBreak
local M = {}
Core.Render.Text.CJKBreak = M

M.Type = {
    Normal = 0,
    Letter = 1,
    Opening = 2,
    Closing = 3,
}

local char_class = {}
local utf8 = require("utf8")
do

    local function add_range(from, to, type)
        for i = from, to do
            char_class[i] = type
        end
    end
    add_range(0x4E00, 0x9FFF, M.Type.Normal)     -- CJK 统一表意文字
    add_range(0x3400, 0x4DBF, M.Type.Normal)     -- Ext A
    add_range(0x20000, 0x323AF, M.Type.Normal)   -- Ext B～I（常用区）
    add_range(0xAC00, 0xD7A3, M.Type.Normal)     -- 韩文音节
    add_range(0x3040, 0x30FF, M.Type.Normal)     -- 日文假名
    add_range(0x31F0, 0x31FF, M.Type.Normal)     -- 假名扩展
    add_range(0xFF01, 0xFF60, M.Type.Normal)     -- 全角 ASCII（大部分归0，个别后面覆盖）
    char_class[0x3000] = M.Type.Normal        -- 全角空格
    char_class[0x20] = M.Type.Normal        -- 半角空格

    -- 字母 & 数字（单词内部禁止断行）
    add_range(0x0030, 0x0039, M.Type.Letter)  -- 0-9
    add_range(0x0041, 0x005A, M.Type.Letter)  -- A-Z
    add_range(0x0061, 0x007A, M.Type.Letter)  -- a-z
    add_range(0x00C0, 0x02AF, M.Type.Letter)  -- 拉丁扩展
    add_range(0x0370, 0x03FF, M.Type.Letter)  -- 希腊
    add_range(0x0400, 0x052F, M.Type.Letter)  -- 西里尔
    add_range(0x2160, 0x217F, M.Type.Letter)  -- 罗马数字

    -- 禁止行尾的开符号（Opening punctuation）
    for _, c in utf8.codes("(\"'（［【「『《〈＜〔｛〘〖〚｟［｢«‹〱〳〴") do
        char_class[c] = M.Type.Opening
    end
    for _, b in ipairs({
        0xFF08, 0xFF3B, 0xFF5B, 0xFF5F, -- 全角 ( [ { ｛
        0x300C, 0x300E, 0x3010, 0x3014, 0x3016, 0x3018, 0x301A, -- 各种左括号
    }) do
        char_class[b] = M.Type.Opening
    end

    -- 禁止行首的闭/中符号（Closing + Middle）
    for _, c in utf8.codes("\").。!！?？,，;；:：·…⋯•─—～~」』》〉】〕）]}｝〙〗〛｠｣>»›.．｡､") do
        char_class[c] = M.Type.Closing
    end
    for _, b in ipairs({
        0xFF09, 0xFF3D, 0xFF5D, 0xFF60, -- 全角 ) ] } ｝
        0x300D, 0x300F, 0x3011, 0x3015, 0x3017, 0x3019, 0x301B, -- 右括号
        0x3001, 0x3002, 0xFF0C, 0xFF0E, 0xFF1A, 0xFF1B, 0xFF1F, -- 常见闭句符号
        0x2025, 0x2026, 0x30FB, -- … ‥ ・
    }) do
        char_class[b] = M.Type.Closing
    end
end

---获取单个字符的类别
---@param ch string
---@return number
function M.Get(ch)
    local b = utf8.codepoint(ch)
    if not char_class[b] then
        char_class[b] = M.Type.Normal
    end
    return char_class[b]
end

local UTF8_MATCH = "[%z\1-\127\194-\244][\128-\191]*"
---将字符串分割为单个字符，存入表中
---使用GC压力最低的方法
---@param list string[]
---@param text string
function M.SplitUTF8(list, text)
    local i = 1
    for ch in text:gmatch(UTF8_MATCH) do
        list[i] = ch
        i = i + 1
    end
    for j = i, #list do
        list[j] = nil
    end
end

local BUF = {}
local concat = table.concat
---将字符串分割为词语，存入表中
---使用GC压力最低的方法
---@param list string[]
---@param text string
function M.Tokenize(list, text)
    local prev_type
    local i = 1
    local buf_i = 1
    for ch in text:gmatch(UTF8_MATCH) do
        local t = M.Get(ch)
        if t == M.Type.Normal or t == M.Type.Opening then
            if buf_i > 1 and prev_type ~= M.Type.Opening then
                for m = buf_i, #BUF do
                    BUF[m] = nil
                end
                list[i] = concat(BUF)
                i = i + 1
                buf_i = 1
            end
            BUF[buf_i] = ch
            buf_i = buf_i + 1
        elseif t == M.Type.Letter then
            if prev_type ~= M.Type.Normal then
                BUF[buf_i] = ch
                buf_i = buf_i + 1
            else
                if buf_i > 1 then
                    for m = buf_i, #BUF do
                        BUF[m] = nil
                    end
                    list[i] = concat(BUF)
                    buf_i = 1
                    i = i + 1
                end
                BUF[1] = ch
                buf_i = 2
            end
        elseif t == M.Type.Closing then
            BUF[buf_i] = ch
            buf_i = buf_i + 1
        end
        prev_type = t
    end
    if buf_i > 1 then
        for m = buf_i, #BUF do
            BUF[m] = nil
        end
        list[i] = concat(BUF)
        i = i + 1
    end
    for j = i, #list do
        list[j] = nil
    end
end