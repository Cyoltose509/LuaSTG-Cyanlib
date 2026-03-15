---@class Core.Lib.CSV
local M = {}
Core.Lib.CSV = M


---解析CSV文本
---使用示例
---id,name,score
---1,Alice,100
---2,Bob,200
---3,"Charlie, Jr",300
---local csv = Core.Lib.CSV
---local text = io.open("test.csv","r"):read("*a")
---local rows = csv.Parse(text, true)
---for _,row in ipairs(rows) do
---    print(row.id, row.name, row.score)
---end
---1 Alice 100
---2 Bob 200
---3 Charlie, Jr 300
---@param text string 输入的 CSV 文本数据
---@param has_header boolean 是否包含表头
---@param sep string 字段分隔符
---@return table
function M.Parse(text, has_header, sep)
    sep = sep or ","

    local rows = {}
    local row = {}
    local field = {}

    local header = nil
    local in_quotes = false

    local function push_field()
        row[#row + 1] = table.concat(field):gsub("\r\n", "\n"):gsub("\r", "\n")
        field = {}
    end

    local function push_row()
        if has_header then
            if not header then
                -- 复制 header
                header = {}
                for i = 1, #row do
                    header[i] = row[i]
                end
            else
                local obj = {}
                for i = 1, #header do
                    obj[header[i]] = row[i] or ""
                end
                rows[#rows + 1] = obj
            end
        else
            rows[#rows + 1] = row
        end
        row = {}
    end

    local i = 1
    local len = #text

    while i <= len do
        local c = text:sub(i, i)

        if c == '"' then
            if in_quotes and text:sub(i + 1, i + 1) == '"' then
                field[#field + 1] = '"'
                i = i + 1
            else
                in_quotes = not in_quotes
            end

        elseif c == sep and not in_quotes then
            push_field()

        elseif (c == "\n" or c == "\r") and not in_quotes then
            push_field()
            push_row()

            if c == "\r" and text:sub(i + 1, i + 1) == "\n" then
                i = i + 1
            end

        else
            field[#field + 1] = c
        end

        i = i + 1
    end

    if #field > 0 or #row > 0 then
        push_field()
        push_row()
    end

    return rows
end

return M