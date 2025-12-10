---@class STG.Item
local M = {}
STG.Item = M

local Object = STG.Object

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
    sound:play(volume, pan)
end

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
    self.img = 'item' .. t
    self.imgup = 'item_up' .. t
    self.attract = 0
    self.collect_online = true
    self.py = y
    self.t = 0
    self._vy = 0
    self._scale = 0
    self.__scale = 1
    self._blend = ""
    self._a, self._r, self._g, self._b = 255, 255, 255, 255
    self.fall_v = 3.4
    self.fall_a = 0.06
end
function Base:render()
    local w = Core.World.GetMain()
    if self.y > w.t and not self.no_up_render and self.imgup then
        Core.Render.Image(self.imgup, self.x, w.t - 16)
    else
        Object.SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
        Object.DefaultRender(self)
    end
end

function Base:frame()
    Core.Task.Do(self)
    local w = Core.World.GetMain()
    --TODO
    local player = self.target or player
    self.t = self.t + 1
    if self.timer == 1 then
        self.rot = -45
    end
    if self.t == 24 then

        self.py = self.y
    end
    if self.t < 24 then
        self._scale = min(self.__scale, self._scale + self.__scale / 24)
        self.rot = 45 * self.t + 45
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
            self.vy = self._vy
        end
    end
    if self.timer > 24 and self.attract > 0 then
        Object.SetV(self, self.attract, Core.Math.Angle(self, player))
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

---@type Core.Resource.Sound
function Base:colli(other)
    --TODO
    if other == player then
        if self.class.collect then
            self.class.collect(self, other)
        end
        Object.Kill(self)
        playSound(0.3, self.x / 200)
    end
end

function M.Drop(item_obj, num, x, y, ...)
    for _ = 1, num do
        local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
        local a = ran:Float(0, 360)
        Object.New(item_obj, x + r2 * cos(a), y + r2 * sin(a), ...)
    end
end

local DropPoint = Object.Define()
M.DropPoint = DropPoint
function DropPoint:init(x, y)
    local w = Core.World.GetMain()
    x = clamp(x, w.l + 8, w.r - 8)
    self.x = x
    self.y = y
    Object.SetV(self, 3, 90)
    self.v = 3
    self.group = Object.Group.Item
    self.layer = Object.Layer.Item
    self.bound = false
    self._blend = Core.Render.BlendMode.MulAdd
    self.img = "stg:drop_point"
    self.attract = 0
    self.collect_online = true
    self.py = y
    self.t = 0
    self._vy = 0
    self.omega = ran:Float(2, 3)
    self.rot = ran:Float(0, 360)
    self.is_drop_point = true
    self.vx = ran:Float(-0.3, 0.3)
    self._vy = ran:Float(6.5, 7.5)
    self.flag = 1
    self.is_minor = true
    --TODO
    self.target = player
    w:isInside(self)
    if not w:isInside(self) then
        Object.RawDel(self)
    end
end
function DropPoint:frame()
    local w = Core.World.GetMain()
    local player = self.target
    if self.timer < 45 then
        self.vy = self._vy - self._vy * self.timer / 45
    end
    if self.timer >= 54 and self.flag == 1 then
        Object.SetV(self, 16, Angle(self, player))
    end
    if self.timer >= 54 and self.flag == 0 then
        if self.attract > 0 then
            local a = Core.Math.Angle(self, player)
            self.vx = self.attract * cos(a) + player.dx * 0.5
            self.vy = self.attract * sin(a) + player.dy * 0.5
        else
            self.vy = max(self.dy - 0.06, -5)
            self.vx = 0
        end
        if self.y < w.boundB or self.y > w.boundT + 130 then
            Object.Del(self)
        end
    end
end
function DropPoint:collect()
    -- player_lib.AddScore(10)
end
function DropPoint:colli(other)
    if other == player then
        if self.class.collect then
            self.class.collect(self, other)
        end
        Core.Object.Kill(self)
        playSound(0.3, self.x / 200)

    end
end