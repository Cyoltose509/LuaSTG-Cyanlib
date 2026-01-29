---@class Core.Lib.Easing
local VALUE_SET = {
    ---二指数加速
    QuadIn = 1,
    ---二指数减速
    QuadOut = 2,
    ---二指数加速减速
    QuadInOut = 3,
    ---正弦减速
    SineOut = 5,
    ---正弦加速
    SineIn = 6,
    ---三指数加速
    CubicIn = 7,
    ---三指数减速
    CubicOut = 8,
    ---四指数加速
    QuartIn = 9,
    ---四指数减速
    QuartOut = 10,
    ---线性
    Linear = 11,
    ---缓入后缓出
    SineQuad = 13,
    ---指数加速
    ExpoIn = 15,
    ---指数减速
    ExpoOut = 16,
    ---指数加速减速
    ExpoInOut = 17,
    CircIn = 18,
    CircOut = 19,
    CircInOut = 20,
    ElasticIn = 21,
    ElasticOut = 22,
    ElasticInOut = 23,
    BackIn = 24,
    BackOut = 25,
    BackInOut = 26,
    BounceIn = 27,
    BounceOut = 28,
    BounceInOut = 29,
    FlashIn = 30,
    FlashOut = 31,
    FlashInOut = 32,
}

local exp = math.exp

---@type Core.Lib.Easing
local M = {}
Core.Lib.Easing = M

local SetMode = {
    [1] = function(n)
        return n * n
    end,
    [2] = function(n)
        return 2 * n - n * n
    end,
    [3] = function(n)
        if n < 0.5 then
            return 2 * n * n
        else
            return -2 * n * n + 4 * n - 1
        end
    end,
    [5] = function(n)
        return sin(n * 90)
    end,
    [6] = function(n)
        return 1 - sin(90 - n * 90)
    end,
    [7] = function(n)
        return n * n * n
    end,
    [8] = function(n)
        return n * n * n - 3 * n * n + 3 * n
    end,
    [9] = function(n)
        return n * n * n * n
    end,
    [10] = function(n)
        return -n * n * n * n + 4 * n * n * n - 6 * n * n + 4 * n
    end,
    [11] = function(n)
        return n
    end,
    [13] = function(n)
        local m = sin(n * 180)
        return m * m
    end,
    [15] = function(n)
        return (exp(n) - 1) / (exp(1) - 1)
    end,
    [16] = function(n)
        return 1 - (exp(1 - n) - 1) / (exp(1) - 1)
    end, -- ExpoOut
    [17] = function(n)
        if n < 0.5 then
            return (exp(2 * n) - 1) / (exp(1) - 1) / 2
        else
            return 1 - (exp(2 * (1 - n)) - 1) / (exp(1) - 1) / 2
        end
    end, -- ExpoInOut
    [18] = function(n)
        return 1 - sqrt(1 - n * n)
    end, -- CircIn
    [19] = function(n)
        return sqrt(1 - (n - 1) * (n - 1))
    end, -- CircOut
    [20] = function(n)
        if n < 0.5 then
            return (1 - sqrt(1 - (2 * n) * (2 * n))) / 2
        else
            return (sqrt(1 - (-2 * n + 2) ^ 2) + 1) / 2
        end
    end, -- CircInOut
    [21] = function(n)
        return sin(13 * 90 * n) * (2 ^ (10 * (n - 1)))
    end, -- ElasticIn
    [22] = function(n)
        return sin(-13 * 90 * (n + 1)) * (2 ^ (-10 * n)) + 1
    end, -- ElasticOut
    [23] = function(n)
        if n < 0.5 then
            return 0.5 * sin(13 * 180 * n) * (2 ^ (20 * n - 10))
        else
            return 0.5 * (sin(-13 * 180 * (n * 2 - 1 + 1)) * (2 ^ (-20 * n + 10)) + 2)
        end
    end, -- ElasticInOut
    [24] = function(n)
        local s = 1.70158
        return n * n * ((s + 1) * n - s)
    end, -- BackIn
    [25] = function(n)
        local s = 1.70158
        return (n - 1) * (n - 1) * ((s + 1) * (n - 1) + s) + 1
    end, -- BackOut
    [26] = function(n)
        local s = 1.70158 * 1.525
        if n < 0.5 then
            return ((2 * n) ^ 2 * ((s + 1) * 2 * n - s)) / 2
        else
            return ((2 * n - 2) ^ 2 * ((s + 1) * (2 * n - 2) + s) + 2) / 2
        end
    end, -- BackInOut
    [27] = function(n)
        return 1 - M[28](1 - n)
    end, -- BounceIn
    [28] = function(n)
        -- BounceOut
        if n < 1 / 2.75 then
            return 7.5625 * n * n
        elseif n < 2 / 2.75 then
            n = n - 1.5 / 2.75
            return 7.5625 * n * n + 0.75
        elseif n < 2.5 / 2.75 then
            n = n - 2.25 / 2.75
            return 7.5625 * n * n + 0.9375
        else
            n = n - 2.625 / 2.75
            return 7.5625 * n * n + 0.984375
        end
    end,
    [29] = function(n)
        if n < 0.5 then
            return M[27](n * 2) / 2
        else
            return M[28](n * 2 - 1) / 2 + 0.5
        end
    end, -- BounceInOut
    [30] = function(n)
        return sin(n * 6 * 180) * (1 - n)
    end, -- FlashIn
    [31] = function(n)
        return sin(n * 6 * 180) * n
    end, -- FlashOut
    [32] = function(n)
        if n < 0.5 then
            return 0.5 * sin(12 * 180 * n) * (1 - 2 * n)
        else
            return 0.5 * (sin(12 * 180 * (n - 0.5)) * (2 * n - 1) + 1)
        end
    end, -- FlashInOut
}

---@return number
function M.Evaluate(mode, n)
    return SetMode[mode](n)
end
setmetatable(M, {
    __index = function(t, k)
        local map = VALUE_SET[k]
        local v
        if map then
            v = SetMode[map]
        else
            v = SetMode[k]
        end
        if v then
            rawset(t, k, v)
            return v
        elseif type(k) == "function" then
            return k
        end
    end
})






