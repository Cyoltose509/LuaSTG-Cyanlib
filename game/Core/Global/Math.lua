---=====================================
---luastg math
---=====================================

----------------------------------------
---常量
local math = math
PI = math.pi
PIx2 = math.pi * 2
PI_2 = math.pi * 0.5
PI_4 = math.pi * 0.25
SQRT2 = math.sqrt(2)
SQRT3 = math.sqrt(3)
SQRT2_2 = math.sqrt(0.5)
GOLD = 360 * (math.sqrt(5) - 1) / 2

----------------------------------------
---数学函数

int = math.floor
abs = math.abs
max = math.max
min = math.min
sqrt = math.sqrt
cos = lstg.cos
sin = lstg.sin
tan = lstg.tan
acos = lstg.acos
asin = lstg.asin
atan = lstg.atan
atan2 = lstg.atan2

local function lsin(t)
    return asin(sin(t)) / 90
end
_G.lsin = lsin

---限制数的范围，
---比同时用min,max高效
---比单个min,max低效
local function clamp(t, MIN, MAX)
    if MAX and t >= MAX then
        return MAX
    elseif MIN and t <= MIN then
        return MIN
    else
        return t
    end
end
_G.clamp = clamp

local function lerp(a, b, t)
    return a + (b - a) * t
end
_G.lerp = lerp

---获得数字的符号(1/-1/0)
local function sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end
_G.sign = sign

---获得(x,y)向量的模长
---@overload fun(x:number, y:number):number
local function hypot(x, y)
    return sqrt(x * x + y * y)
end
_G.hypot = hypot

---阶乘，目前用于组合数和贝塞尔曲线
local fac = {}
local function factorial(num)
    if num < 0 then
        error("Can't get factorial of a minus number.")
    end
    if num < 2 then
        return 1
    end
    num = int(num)
    if fac[num] then
        return fac[num]
    end
    local result = 1
    for i = 1, num do
        if fac[i] then
            result = fac[i]
        else
            result = result * i
            fac[i] = result
        end
    end
    return result
end
_G.factorial = factorial

---组合数，目前用于贝塞尔曲线
local function combinNum(ord, sum)
    assert(ord >= 0 and sum >= 0, "Can't get combinatorial of minus numbers.")
    ord = int(ord)
    sum = int(sum)
    return factorial(sum) / (factorial(ord) * factorial(sum - ord))
end
_G.combinNum = combinNum

---legacy
ran = lstg.Rand()
