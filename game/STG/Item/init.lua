---@class STG.Item
local M = {}
STG.Item = M

local Object = STG.Object
local Constants = STG.Constants
local Event = STG.Event
local Render = Core.Render

local rand = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time())

-- ========================================
-- Item Types
-- ========================================

---@class STG.Item.Type
---@field id string Unique type identifier
---@field img string Sprite name prefix
---@field img_up string|nil Sprite for above-world indicator
---@field value number Base value (score points or power amount)
---@field sound string|nil Sound effect name

---@type table<string, STG.Item.Type>
M.Types = {
    Power = {
        id = "power",
        img = "stg:item_power",
        img_up = "stg:item_power_up",
        value = 1,
        sound = "item00",
    },
    BigPower = {
        id = "big_power",
        img = "stg:item_bigpoint",
        img_up = "stg:item_bigpoint_up",
        value = 3,
        sound = "item00",
    },
    Point = {
        id = "point",
        img = "stg:item_point",
        img_up = "stg:item_point_up",
        value = 100,
        sound = "item00",
    },
    BigPoint = {
        id = "big_point",
        img = "stg:item_bigpoint",
        img_up = "stg:item_bigpoint_up",
        value = 500,
        sound = "item00",
    },
    Bomb = {
        id = "bomb",
        img = "stg:item_bomb",
        img_up = "stg:item_bomb_up",
        value = 1,
        sound = "item00",
    },
    Life = {
        id = "life",
        img = "stg:item_life",
        img_up = "stg:item_life_up",
        value = 1,
        sound = "item00",
    },
}

-- ========================================
-- Sound
-- ========================================

M.DefaultSound = "item00"

local function playCollectSound(item_type, volume, pan)
    local sound_name = item_type and item_type.sound or M.DefaultSound
    STG.SE.Play(sound_name, volume or 0.3, pan or 0)
end

function M.SetDefaultSound(name)
    M.DefaultSound = name
end

-- ========================================
-- Item Base Class
-- ========================================

local Base = Object.Define()
M.Base = Base

---@param item_type STG.Item.Type
---@param x number
---@param y number
---@param v number|nil Initial upward velocity
---@param angle number|nil Initial direction (default 90 = up)
function Base:init(item_type, x, y, v, angle)
    local w = Core.World.GetMain()
    self.item_type = item_type or M.Types.Point
    self.x = clamp(x, w.l + Constants.WORLD.MARGIN_ITEM, w.r - Constants.WORLD.MARGIN_ITEM)
    self.y = y
    self.v = v or 5
    self.vy = self.v
    self.group = Object.Group.Item
    self.layer = Object.Layer.Item
    self.bound = false
    self.img = self.item_type.img
    self.img_up = self.item_type.img_up
    self.collected = false
    self.attract_speed = 0
    self.can_auto_collect = true
    self.py = y
    self.timer_count = 0
    self._vy = 0
    self._scale = 0
    self._scale_target = 1
    self._blend = ""
    self._a, self._r, self._g, self._b = 255, 255, 255, 255
    self.fall_v = Constants.ITEM.FALL_V
    self.fall_a = Constants.ITEM.FALL_A
end

function Base:render()
    local w = Core.World.GetMain()
    if self.y > w.t and self.img_up then
        Render.Utils.SimpleSprite(self.img_up, self.x, w.t - 16)
    else
        Object.SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
        Object.DefaultRender(self)
    end
end

function Base:frame()
    Core.Task.Do(self)
    local w = Core.World.GetMain()
    self.timer_count = self.timer_count + 1

    -- Initial fly-up phase (first 24 frames)
    if self.timer_count < 24 then
        self._scale = min(self._scale_target, self._scale + self._scale_target / 24)
        self.rot = 45 * self.timer_count + 45
        self.hscale = (self.timer_count + 25) / 48 * self._scale
        self.vscale = self.hscale
        if self.timer_count < 24 then
            self.y = self.py + self.v * self.timer_count - 0.5 * self.v / 48 * self.timer_count * self.timer_count
        end
        if self.timer_count == 22 then
            self.vx = 0
        end
        return
    end

    -- Fall phase
    if self.attract_speed <= 0 then
        self._vy = max(-self.fall_v, self._vy - self.fall_a)
        self.vy = self._vy
    end

    -- Auto-collect: check for nearby player via attract threshold
    if self.can_auto_collect and self.attract_speed >= Constants.ITEM.ATTRACT_THRESHOLD then
        self.collected = true
    end

    -- Cull if out of world bounds
    if self.y < w.boundB or self.y > w.boundT + 130 then
        Object.Del(self)
    end
end

function Base:colli(other)
    if not Object.IsValid(other) then
        return
    end
    if other.group == Object.Group.Player then
        self:collect(other)
    end
end

---Called when the player collects this item.
---@param player STG.Player.Base
function Base:collect(player)
    if self.collected then
        return
    end
    self.collected = true

    local item_type = self.item_type
    if not item_type then
        Object.Kill(self)
        return
    end

    -- Fire event for collection (player systems listen to this)
    Event.Fire(Event.Group.ITEM_COLLECT, self, player)

    -- Handle default collection behavior based on type
    local res_comp = nil
    if player.sys and player.sys.component_sys then
        res_comp = player.sys.component_sys:getComponent("Resource")
    end

    if res_comp then
        local id = item_type.id
        if id == "power" then
            res_comp:addPower(item_type.value)
        elseif id == "big_power" then
            res_comp:addPower(item_type.value)
        elseif id == "point" or id == "big_point" then
            res_comp:addScore(item_type.value)
        elseif id == "bomb" then
            res_comp:addBomb(item_type.value)
            local bomb_comp = player.sys.component_sys:getComponent("Bomb")
            if bomb_comp then
                bomb_comp:addBomb(item_type.value)
            end
        elseif id == "life" then
            res_comp:addLife(item_type.value)
        end
    end

    Object.Kill(self)
    playCollectSound(self.item_type, 0.3, self.x / 200)
end

-- ========================================
-- Drop API
-- ========================================

---Drop items. Supports two calling conventions:
---1. New API: Drop(type, num, x, y) - drops `num` items of `type` at (x,y) with spread
---2. Legacy API: Drop(class, x, y) - creates one instance of `class` at (x,y) with spread
---@param item_type_or_class any Item type from M.Types, or an Object.Define class
---@param num_or_x number Count (new API) or X position (legacy API)
---@param x_or_y number X position (new API) or Y position (legacy API)
---@param y_or_nil number|nil Y position (new API) or nil (legacy API)
function M.Drop(item_type_or_class, num_or_x, x_or_y, y_or_nil)
    -- Detect calling convention: if first arg is a class (has is_class field from Object.Define)
    if type(item_type_or_class) == "table" and item_type_or_class.is_class then
        -- Legacy API: Drop(class, x, y)
        local cls = item_type_or_class
        local x = num_or_x or 0
        local y = x_or_y or 0
        local r2 = sqrt(rand:Float(1, 4)) * 5
        local a = rand:Float(0, 360)
        Object.New(cls, x + r2 * cos(a), y + r2 * sin(a))
        return
    end

    -- New API: Drop(type, num, x, y)
    local item_type = item_type_or_class
    local num = num_or_x or 1
    local x = x_or_y or 0
    local y = y_or_nil or 0
    if not item_type or num <= 0 then
        return
    end
    for _ = 1, num do
        local r2 = sqrt(rand:Float(1, 4)) * sqrt(num - 1) * 5
        local a = rand:Float(0, 360)
        Object.New(Base, item_type, x + r2 * cos(a), y + r2 * sin(a))
    end
end

-- ========================================
-- Drop Point (auto-collect attractor)
-- ========================================

local DropPoint = Object.Define()
M.DropPoint = DropPoint

function DropPoint:init(x, y)
    local w = Core.World.GetMain()
    x = clamp(x, w.l + Constants.WORLD.MARGIN_DROP_POINT, w.r - Constants.WORLD.MARGIN_DROP_POINT)
    self.x = x
    self.y = y
    Object.SetV(self, 3, 90)
    self.v = 3
    self.group = Object.Group.Item
    self.layer = Object.Layer.Item
    self.bound = false
    self._blend = Render.BlendMode.MulAdd
    self.img = "stg:drop_point"
    self.attract_speed = 0
    self.can_auto_collect = true
    self.py = y
    self.timer_count = 0
    self._vy = 0
    self.omega = rand:Float(2, 3)
    self.rot = rand:Float(0, 360)
    self.is_drop_point = true
    self.vx = rand:Float(-0.3, 0.3)
    self._vy = rand:Float(
        Constants.ITEM.DROP_POINT_IMPULSE_VY_MIN,
        Constants.ITEM.DROP_POINT_IMPULSE_VY_MAX
    )
    self.flag = 1
    self.is_minor = true

    if not w:isInside(self) then
        Object.RawDel(self)
    end
end

function DropPoint:frame()
    local w = Core.World.GetMain()
    -- Fly up then hover (0-45 frames)
    if self.timer_count < 45 then
        self.vy = self._vy - self._vy * self.timer_count / 45
    end
    -- After delay, fly toward player or fall
    if self.timer_count >= 54 and self.flag == 1 then
        -- Phase 1: fast launch toward player
        local player = STG.Player.Get()
        if Object.IsValid(player) then
            Object.SetV(self, Constants.ITEM.DROP_POINT_ATTRACT_V, Angle(self, player))
        end
        self.flag = 0
    end
    if self.timer_count >= 54 and self.flag == 0 then
        if self.attract_speed > 0 then
            local player = STG.Player.Get()
            if Object.IsValid(player) then
                local a = Core.Math.Angle(self, player)
                self.vx = self.attract_speed * cos(a) + player.dx * 0.5
                self.vy = self.attract_speed * sin(a) + player.dy * 0.5
            end
        else
            self.vy = max(self.dy - 0.06, -5)
            self.vx = 0
        end
        if self.y < w.boundB or self.y > w.boundT + 130 then
            Object.Del(self)
        end
    end
end

function DropPoint:collect(player)
    Event.Fire(Event.Group.ITEM_COLLECT, self, player)
    local res_comp = nil
    if player and player.sys and player.sys.component_sys then
        res_comp = player.sys.component_sys:getComponent("Resource")
    end
    if res_comp then
        res_comp:addScore(10)
    end
end

function DropPoint:colli(other)
    if other.group == Object.Group.Player then
        self:collect(other)
        Object.Kill(self)
        playCollectSound(nil, 0.3, self.x / 200)
    end
end

