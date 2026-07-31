---@class STG.Enemy.Boss
---@field SpellCard STG.Enemy.Boss.SpellCard
---@field BossSystem STG.Enemy.Boss.BossSystem
---@field BossUI STG.Enemy.Boss.BossUI
---@field Profiles STG.Enemy.Boss.Profiles
local M = {}
STG.Enemy.Boss = M

local Object = STG.Object
local CT = STG.Constants

---@class STG.Enemy.Boss.Base : STG.Enemy.Base
---Boss 基类，继承 Enemy 规范
local Base = Object.Define(STG.Enemy.Base)

function Base:init(x, y, cards, system)
    -- 继承 Enemy 初始化
    self.x, self.y = x, y
    self.is_boss = true
    self.is_enemy = true
    self.layer = Object.Layer.Enemy
    self.group = Object.Group.Enemy

    -- Boss 特有属性
    self.name = ""
    self.is_final = false
    self.is_extra = false
    self.timer = 0    -- 帧计数，供符卡脚本使用 (如 boss.timer)

    -- 初始化 Boss 系统
    self.boss_sys = system or STG.Enemy.Boss.BossSystem(self, cards)

    -- 初始化 Enemy 系统 (通过基类)
    self.time = STG.System.Time()
end

function Base:frame()
    self.timer = self.timer + 1
    local dt = self.time:getDelta()
    Core.Task.Do(self, dt)
    -- Enemy system update (health, anim, collide, phase, move, shoot)
    if self.sys then
        self.sys:update(dt)
    end
    -- Boss system update (spell cards, etc)
    if self.boss_sys then
        self.boss_sys:frame()
    end
end

function Base:render()
    if self.sys then
        self.sys:render()
    end
    if self.boss_sys then
        self.boss_sys:render()
    end
end

function Base:colli(other)
end

function Base:del()
    if self.boss_sys then
        self.boss_sys:del()
    end
end

function Base:kill()
    if self.boss_sys then
        self.boss_sys:kill()
    end
end

---受击 (Boss 特殊处理，留钩子给 SpellCard)
---@param base_damage number 基础伤害
function Base:takeBossDamage(base_damage)
    local info = {
        amount = base_damage,
        bypass_invincible = false,
        source = "bullet",
        type = "hit",
    }
    if self.boss_sys then
        self.boss_sys:onDamage(base_damage)
    end
    if self.sys then
        self.sys:takeDamage(info)
    end
end

M.Base = Base

---快捷创建 Boss
---重载1: Spawn(variant_table, x, y)  — 使用 Boss.Define 返回的模板
---重载2: Spawn(x, y, cards, options) — 直接传入坐标/符卡/选项
---@overload fun(variant:table, x:number, y:number):STG.Enemy.Boss.Base
---@overload fun(x:number, y:number, cards:table, options:table):STG.Enemy.Boss.Base
function M.Spawn(variant_or_x, y_or_y, cards_or_z, options)
    -- 判断是否为 variant 模板调用：第一个参数是 table 且有 create 方法
    if type(variant_or_x) == "table" and type(variant_or_x.create) == "function" then
        local variant = variant_or_x
        local x = y_or_y or 0
        local y = cards_or_z or 0
        return variant:create(x, y)
    end

    -- 直接调用：x, y, cards, options
    local x, y = variant_or_x, y_or_y
    local cards = cards_or_z
    options = options or {}
    local boss_sys = STG.Enemy.Boss.BossSystem(nil, cards)
    if options.name then boss_sys:setName(options.name) end
    if options.difficulty then boss_sys:setDifficulty(options.difficulty) end

    local b = Object.New(Base, x, y, cards, boss_sys)
    boss_sys:setBoss(b)

    -- 应用 Enemy Profile
    if options.profile then
        b.sys:applyProfile(options.profile)
    end

    return b
end

---创建单张符卡（用于 Boss.Define 的 spell_cards 列表）
---支持 table 参数形式：{ name, hp, time_limit, bonus, onEnter, onExit, is_sc, is_combat }
---@param opts table
---@return STG.Enemy.Boss.SpellCard.Card
function M.NewSpellCard(opts)
    opts = opts or {}
    local card = STG.Enemy.Boss.SpellCard.Card(
        opts.name or "",
        opts.hp or 1000,
        0,                              -- t1: 无敌时间(秒)，入场0秒
        opts.time_limit or 30,          -- t2: 防御时间(秒)
        opts.time_limit or 30,          -- t3: 总时间(秒)
        opts.is_sc ~= false,            -- 默认是符卡
        opts.is_combat ~= false         -- 默认是战斗阶段
    )
    -- onEnter 映射到 Card.init
    if opts.onEnter then
        card.init = opts.onEnter
    end
    -- onExit 映射到 Card.del
    if opts.onExit then
        card.del = opts.onExit
    end
    -- 奖励分数
    if opts.bonus then
        card.sc_bonus_max = opts.bonus
    end
    return card
end

---定义 Boss 模板（table 参数形式，与 Main.Test.Scene 的调用兼容）
---@param opts table  { name, profiles, spell_cards, onInit }
---@return table   带 :create() 方法的 Boss 模板
function M.Define(opts)
    -- 兼容旧式位置参数调用：Define(name, x, y, cards, img, scale, options)
    if type(opts) == "string" then
        local name, x, y, cards, img, scale, options = opts, select(1, ...)
        opts = {
            name    = name,
            profiles = { style_name = (options or {}).style_name or img or "", size = scale or 1 },
            spell_cards = cards or {},
            onInit  = (options or {}).onInit,
        }
    end

    local result = {
        name        = opts.name or "",
        profiles    = opts.profiles or {},
        spell_cards = opts.spell_cards or {},
        onInit      = opts.onInit,
    }

    function result:create(x, y)
        x = x or 0
        y = y or 0
        local cards = {}
        for _, c in ipairs(result.spell_cards) do
            table.insert(cards, c)
        end

        local p = result.profiles or {}
        local b = M.Spawn(x, y, cards, {
            name    = result.name,
            profile = p,
        })

        if result.onInit then
            result.onInit(b)
        end
        return b
    end

    return result
end

---快捷生成 Boss（使用 Define 返回的模板）
---@param variant table  由 M.Define 返回的模板
---@param x number
---@param y number
---@return STG.Enemy.Boss.Base
function M.SpawnVariant(variant, x, y)
    return variant:create(x, y)
end

require("STG.Enemy.Boss.Profiles")
require("STG.Enemy.Boss.SpellCard")
require("STG.Enemy.Boss.BossSystem")
require("STG.Enemy.Boss.BossUI")

return M
