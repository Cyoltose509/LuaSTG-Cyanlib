---@class Core.Lib.Matcher
local M = Core.Class()
Core.Lib.Matcher = M

local utf8 = require("utf8")

function M.New()
    local m = M()
    return m
end

function M:init()
    self.pat = {}
    self.next = {}
    self._pos_map = {}  -- 映射表

    self.ignore_case = true
end
local UTF8_MATCH = "[%z\1-\127\194-\244][\128-\191]*"

function M:compile(pattern)
    local pat = self.pat
    local next = self.next
    local m = 0
    local i = 1
    for ch in pattern:gmatch(UTF8_MATCH) do
        local nc = self:_normalize_char(ch)
        m = m + 1
        pat[m] = nc
        i = i + 1
    end
    self.m = m

    -- KMP build
    next[1] = 0
    local j = 0

    for c = 2, m do
        while j > 0 and pat[j + 1] ~= pat[c] do
            j = next[j]
        end
        if pat[j + 1] == pat[c] then
            j = j + 1
        end
        next[c] = j
    end

    return self
end

function M:search(text, results)
    local pat = self.pat
    local next = self.next
    local m = self.m

    local pos_map = self._pos_map

    local j = 0
    local count = 0
    local norm_i = 0
    local i = 1
    for ch in text:gmatch(UTF8_MATCH) do
        local nc = self:_normalize_char(ch)
        norm_i = norm_i + 1
        pos_map[norm_i] = i
        while j > 0 and pat[j + 1] ~= nc do
            j = next[j]
        end

        if pat[j + 1] == nc then
            j = j + 1
        end
        if j == m then
            count = count + 1
            if results then
                local start_norm = norm_i - m + 1
                results[count] = pos_map[start_norm]
            end
            j = next[j]
        end
        i = i + 1
    end
    if results then
        for k = count + 1, #results do
            results[k] = nil
        end
    end

    return count
end

function M:_normalize_char(c)
    local cp = utf8.codepoint(c)
    -- 1. 忽略大小写（英文，日语）
    if self.ignore_case then
        if cp >= 65 and cp <= 90 then
            cp = cp + 32
        end
        if cp >= 0x3041 and cp <= 0x3096 then
            cp = cp + 96
        end
    end

    return cp
end

function M:enableIgnoreCase(flag)
    self.ignore_case = flag
    return self
end