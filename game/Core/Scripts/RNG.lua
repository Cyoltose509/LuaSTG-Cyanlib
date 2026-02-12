---@class Core.RNG
local RNG = {}
Core.RNG = RNG

local bit = require("bit")
local random = random

---@class Core.RNG.Algorithm
RNG.Algorithm = {
    Xoshiro128p = "xoshiro128p",
    Xoshiro128pp = "xoshiro128pp",
    Xoshiro128ss = "xoshiro128ss",
    Xoshiro256p = "xoshiro256p",
    Xoshiro256pp = "xoshiro256pp",
    Xoshiro256ss = "xoshiro256ss",
    Xoshiro512p = "xoshiro512p",
    Xoshiro512pp = "xoshiro512pp",
    Xoshiro512ss = "xoshiro512ss",
    Xoroshiro1024s = "xoroshiro1024s",
    Xoroshiro1024pp = "xoroshiro1024pp",
    Xoroshiro1024ss = "xoroshiro1024ss",
    Xoroshiro128p = "xoroshiro128p",
    Xoroshiro128pp = "xoroshiro128pp",
    Xoroshiro128ss = "xoroshiro128ss",
    Pcg32Oneseq = "pcg32_oneseq",
    Pcg64Oneseq = "pcg64_oneseq",
    Pcg32Fast = "pcg32_fast",
    Pcg64Fast = "pcg64_fast",
    Splitmix64 = "splitmix64",
    --Sfc32 = "sfc32",
    --Sfc64 = "sfc64",
    --Jsf32 = "jsf32",
    --Jsf64 = "jsf64",
}

---@class Core.RNG.Generator
---@field rng random.generator
local genClass = {}
RNG.genClass = genClass

---@param algo Core.RNG.Algorithm 算法名
---@param seed number 初始种子
---@return Core.RNG.Generator
function genClass:new(algo, seed)
    algo = algo or "xoshiro256ss"
    local rng = random[algo]()
    rng:seed(seed or os.time())
    local m = {
        rng = rng,
        seed = seed or os.time(),
        _stack = {}, -- 用于回溯
        algo = algo,
    }
    setmetatable(m, { __index = genClass })
    return m
end

---生成整数
function genClass:int(a, b)
    return self.rng:integer(a, b)
end
---生成布尔值
function genClass:prob(pro)
    return self.rng:number(0, 1) < pro
end

---生成浮点数
function genClass:float(a, b)
    return self.rng:number(a, b)
end
---±1
function genClass:sign()
    return self.rng:sign()
end

function genClass:expectedInt(E)
    local base = math.floor(E)
    local frac = E - base
    if self:prob(frac) then
        return base + 1
    else
        return base
    end
end

---设置种子
function genClass:setSeed(seed)
    self.seed = seed
    self.rng:seed(seed)
end

---回溯功能
function genClass:Push()
    table.insert(self._stack, self.rng:serialize())
end

function genClass:Pop()
    if #self._stack > 0 then
        local s = table.remove(self._stack)
        self.rng:deserialize(s)
    else
        self.rng:seed(self.seed)
    end
end

---克隆
function genClass:Clone()
    local newGen = genClass:new(self.algo, self.seed)
    newGen.rng:deserialize(self.rng:serialize())
    return newGen
end

--- 主随机数通道
---@type Core.RNG.Generator[]
RNG.channels = {}

local MOD = 0xFFFFFFFF
local function hash(s)
    local h = 2166136261
    for i = 1, #s do
        h = bit.band(bit.bxor(h, string.byte(s, i)) * 16777619, 0xFFFFFFFF)
    end
    return h
end

---推入所有通道状态
function RNG:pushAll()
    for _, v in pairs(self.channels) do
        v:Push()
    end
end

---弹出所有通道状态
function RNG:popAll()
    for _, v in pairs(self.channels) do
        v:Pop()
    end
end

---设置主种子，并更新所有通道
function RNG:setSeed(seed)
    self.base_seed = seed or os.time()
    for k, v in pairs(self.channels) do
        local sub_seed = (self.base_seed + hash(k)) % MOD
        v:setSeed(sub_seed)
    end
end

---派生子通道
---@param name string 通道名
---@param algo string 算法名
---@return Core.RNG.Generator
function RNG:derive(name, algo)
    local sub_seed = (self.base_seed + hash(name)) % MOD
    local r = genClass:new(algo, sub_seed)
    self.channels[name] = r
    return r
end

---获取通道，如果不存在则自动派生
---@param field string
---@param algo Core.RNG.Algorithm 算法名（可选）
---@return Core.RNG.Generator
function RNG:getRNG(field, algo)
    if not self.channels[field] then
        return self:derive(field, algo)
    end
    return self.channels[field]
end

---创建一个野生的随机数生成器
---不受RNG管理，不受RNG的种子设置影响
---@param algo Core.RNG.Algorithm 算法名
---@param seed number 初始种子
function RNG:newRaw(algo, seed)
    return genClass:new(algo, seed)
end

---默认初始化
RNG:setSeed(os.time())

