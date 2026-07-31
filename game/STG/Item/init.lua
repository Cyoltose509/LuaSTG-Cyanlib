---@class STG.Item
local M = {}
STG.Item = M

local Object = STG.Object
local Angle  = Core.Math.Angle
local rand   = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time() + 1)

local sound
M.DefaultSound = "item00"

function M.SetDefaultSound(sound_name)
    M.DefaultSound = sound_name
    sound = Core.Resource.Sound.Get(sound_name)
end

local function playSound(volume, pan)
    if not sound then
        sound = Core.Resource.Sound.Get(M.DefaultSound)
    end
    if sound then
        sound:play(volume, pan)
    end
end

-- ========================================
-- Item.Base — 道具基类
-- ========================================

local Base = Object.Define()
M.Base = Base

function Base:init(x, y, t, v, angle)
    local w = Core.World.GetMain()
    self.x = clamp(x, w.l + 16, w.r - 16)
    self.y = y
    self.v = v or 5
    Object.SetV(self, self.v, angle or 90)
    self.group = Object.Group.Item
    self.layer = Object.Layer.Item
    self.bound = false
    self.img   = "item" .. t
    self.imgup = "item_up" .. t
    self.attract = 0
    self.collect_online = true
    self.py    = y
    self.t     = 0
    self._vy   = 0
    self._scale  = 0
    self.__scale = 1
    self._blend  = ""
    self._a, self._r, self._g, self._b = 255, 255, 255, 255
    self.fall_v = 3.4
    self.fall_a = 0.06
end

function Base:render()
    local w = Core.World.GetMain()
    if self.y > w.t and not self.no_up_render and self.imgup then
        Core.Render.SimpleSprite(self.imgup, self.x, w.t - 16)
    else
        Object.SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
        Object.DefaultRender(self)
    end
end

function Base:frame()
    Core.Task.Do(self)
    local w      = Core.World.GetMain()
    local player = self.target or STG.Player.Get()
    self.t = self.t + 1

    if self.timer == 1 then
        self.rot = -45
    end
    if self.t == 24 then
        self.py = self.y
    end

    if self.t < 24 then
        self._scale = min(self.__scale, self._scale + self.__scale / 24)
        self.rot    = 45 * self.t + 45
        self.hscale = (self.t + 25) / 48 * self._scale
        self.vscale = self.hscale
        if self.timer < 24 then
            self.y = self.py + self.v * self.t - 0.5 * self.v / 48 * self.t * self.t
        end
        if self.t == 22 then
            self.vx = 0
        end
    else
        local _a = self.fall_a
        if self.attract <= 0 then
            self._vy = max(-self.fall_v, self._vy - _a)
            self.vy  = self._vy
        end
    end

    if self.timer > 24 and self.attract > 0 and player then
        Object.SetV(self, self.attract, Angle(self, player))
        self.x = self.x + player.dx * 0.5
        self.y = self.y + player.dy * 0.5
    end

    if self.y < w.boundB or self.y > w.boundT + 130 then
        Object.Del(self)
    end

    if self.attract >= 8 then
        self.collected = true
    end
end

function Base:colli(other)
    local p = STG.Player.Get()
    if other == p then
        if self.class.collect then
            self.class.collect(self, other)
        end
        Object.Kill(self)
        playSound(0.3, self.x / 200)
    end
end

-- ========================================
-- Drop — 批量生成道具
-- ========================================

function M.Drop(item_obj, num, x, y, ...)
    for _ = 1, num do
        local r2 = math.sqrt(rand:float(1, 4)) * math.sqrt(math.max(num - 1, 0)) * 5
        local a  = rand:float(0, 360)
        Object.New(item_obj, x + r2 * cos(a), y + r2 * sin(a), ...)
    end
end

-- ========================================
-- DropPoint — 得分点（自动飞向玩家）
-- ========================================

local DropPoint = Object.Define()
M.DropPoint = DropPoint

function DropPoint:init(x, y)
    local w = Core.World.GetMain()
    x = clamp(x, w.l + 8, w.r - 8)
    self.x = x
    self.y = y
    Object.SetV(self, 3, 90)
    self.v     = 3
    self.group = Object.Group.Item
    self.layer = Object.Layer.Item
    self.bound = false
    self._blend = Core.Render.BlendMode.MulAdd
    self.img    = "stg:drop_point"
    self.attract = 0
    self.collect_online = true
    self.py   = y
    self.t    = 0
    self._vy  = 0
    self.omega = rand:float(2, 3)
    self.rot   = rand:float(0, 360)
    self.is_drop_point = true
    self.vx   = rand:float(-0.3, 0.3)
    self._vy  = rand:float(6.5, 7.5)
    self.flag = 1
    self.is_minor = true
    self.target = self.target or STG.Player.Get()

    if not w:isInside(self) then
        Object.RawDel(self)
        return
    end
end

function DropPoint:frame()
    local w      = Core.World.GetMain()
    local player = self.target

    if self.timer < 45 then
        self.vy = self._vy - self._vy * self.timer / 45
    end

    if self.timer >= 54 and self.flag == 1 and player then
        Object.SetV(self, 16, Angle(self, player))
    end

    if self.timer >= 54 and self.flag == 0 then
        if self.attract > 0 and player then
            local a  = Angle(self, player)
            self.vx  = self.attract * cos(a) + player.dx * 0.5
            self.vy  = self.attract * sin(a) + player.dy * 0.5
        else
            self.vy = max(self.vy - 0.06, -5)
            self.vx = 0
        end
        if self.y < w.boundB or self.y > w.boundT + 130 then
            Object.Del(self)
        end
    end
end

function DropPoint:collect()
    -- 得分点收集：可接入 STG.System.Score
    -- STG.System.Score.addScore(10)
end

function DropPoint:colli(other)
    local p = STG.Player.Get()
    if other == p then
        if self.class.collect then
            self.class.collect(self, other)
        end
        Core.Object.Kill(self)
        playSound(0.3, self.x / 200)
    end
end

-- ========================================
-- Power Item — 灵力道具
-- ========================================

local PowerItem = Core.Class(Base)
M.PowerItem = PowerItem

function PowerItem:init(x, y)
    Base.init(self, x, y, "p", 4, 90 + rand:float(-15, 15))
    self._power_amount = STG.Constants.ITEM_POWER_SMALL or 1
end

function PowerItem.collect(self, player)
    if player and player.sys and player.sys.shoot_system then
        player.sys.shoot_system:addPower(self._power_amount)
    end
    -- 通知 Score 系统
    if STG.System and STG.System.Score then
        STG.System.Score.addScore(STG.Constants.SCORE_POWER_ITEM or 10)
    end
end

-- ========================================
-- Big Power Item — 大灵力道具
-- ========================================

local BigPowerItem = Core.Class(Base)
M.BigPowerItem = BigPowerItem

function BigPowerItem:init(x, y)
    Base.init(self, x, y, "P", 4.5, 90 + rand:float(-10, 10))
    self._power_amount = STG.Constants.ITEM_POWER_BIG or 8
end

function BigPowerItem.collect(self, player)
    if player and player.sys and player.sys.shoot_system then
        player.sys.shoot_system:addPower(self._power_amount)
    end
    if STG.System and STG.System.Score then
        STG.System.Score.addScore(STG.Constants.SCORE_POWER_ITEM_BIG or 50)
    end
end

-- ========================================
-- Score Item（点符）
-- ========================================

local ScoreItem = Core.Class(Base)
M.ScoreItem = ScoreItem

function ScoreItem:init(x, y)
    Base.init(self, x, y, "s", 4, 90 + rand:float(-20, 20))
    self._score_amount = STG.Constants.ITEM_SCORE_VALUE or 1000
end

function ScoreItem.collect(self, player)
    if STG.System and STG.System.Score then
        STG.System.Score.addScore(self._score_amount)
    end
end

-- ========================================
-- Life Fragment（残机碎片）
-- ========================================

local LifeFragment = Core.Class(Base)
M.LifeFragment = LifeFragment

function LifeFragment:init(x, y)
    Base.init(self, x, y, "L", 3.5, 90)
end

function LifeFragment.collect(self, player)
    if player and player.sys and player.sys.health_system then
        player.sys.health_system:addLife(1)
    end
    if STG.System and STG.System.Score then
        STG.System.Score.addScore(STG.Constants.ITEM_LIFE_SCORE or 0)
    end
end

-- ========================================
-- Bomb Fragment（炸弹碎片）
-- ========================================

local BombFragment = Core.Class(Base)
M.BombFragment = BombFragment

function BombFragment:init(x, y)
    Base.init(self, x, y, "B", 3.5, 90)
end

function BombFragment.collect(self, player)
    if player and player.sys and player.sys.health_system then
        player.sys.health_system:addBomb(1)
    end
    if STG.System and STG.System.Score then
        STG.System.Score.addScore(STG.Constants.ITEM_BOMB_SCORE or 0)
    end
end
