local utf8 = require("utf8")

---@param nums number[]|number
---@return string
function string.utf8_char(nums)
    if type(nums) ~= "table" then
        return utf8.char(nums)
    else
        return utf8.char(unpack(nums))
    end
end

---@param str string
---@return number[]
function string.utf8_byte(str)
    local nums = {}
    for _, c in utf8.codes(str) do
        nums[#nums + 1] = c
    end
    return nums
end

---@param s string
---@return function, string, number
function string.utf8_codes(s)
    return utf8.codes(s)
end



---@param str string
---@return number
function string.utf8_len(str)
    return utf8.len(str)
end
---@param s string
---@param i number
---@param j number
---@return string
function string.utf8_sub(s, i, j)
    i = i or 1
    j = j or -1
    if i < 0 or j < 0 then
        local len = utf8.len(s)
        if not len then
            return ""
        end
        if i < 0 then
            i = len + 1 + i
        end
        if j < 0 then
            j = len + 1 + j
        end
    end
    local start_pos = utf8.offset(s, i)
    local end_pos = utf8.offset(s, j + 1)
    if start_pos and end_pos then
        return s:sub(start_pos, end_pos - 1)
    elseif start_pos then
        return s:sub(start_pos)
    else
        return ""
    end
end
---分割字符串
---@param str string@要分割的字符串
---@param delimiter string @分割符
---@return string[] @分割好的字符串表
function string.split(str, delimiter)
    if delimiter == "" then
        return false
    end
    local pos, arr = 0, {}
    for st, sp in function()
        return str:find(delimiter, pos, true)
    end do
        table.insert(arr, str:sub(pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, str:sub(pos))
    return arr
end