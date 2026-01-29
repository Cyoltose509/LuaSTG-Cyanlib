---@class STG.Player.Shots
local M = {}
STG.Player.Shots = M

local Object = STG.Object
local Render = Core.Render
local Vec2 = Core.Math.Vector2

---@class STG.Player.Shots.Base
local Base = Object.Define()
function Base:init(x, y)

    self.x, self.y = x, y
    self.layer = Object.Layer.PlayerShots
    self.group = Object.Group.PlayerShots
    self.r = 20
    self.a = self.r
    self.b = self.r

    self.speed_dir = Vec2.up
    self.speed = 10
    self.life_time = 60
    self._r, self._g, self._b = 135, 206, 250
    self.dmg = 10
    self.knockback = 10
    self.timer = 0
    --STG.Collision.SetNotCollideInGroup(self, true)
end
function Base:frame(dt)
    -- 计算速度分量
    self.vx = self.speed * self.speed_dir.x
    self.vy = self.speed * self.speed_dir.y

    if self.timer >= self.life_time then
        Object.Del(self)
    end
end
function Base:colli(other)
end
function Base:del()
end
function Base:render()
    local A = 1
    local R, G, B = self._r, self._g, self._b

    Render.SetImageState("pure_circle", Render.BlendMode.MulAdd, Render.Color(255 * A, R, G, B))
    Render.Image("pure_circle", self.x, self.y, 0, self.a / 125)
    Render.SetImageState("bright", Render.BlendMode.MulAdd, Render.Color(100 * A, R, G, B))
    Render.Image("bright", self.x, self.y, 0, self.a / 125)
end

---@param opt STG.Player.Shots.Base
function M.Spawn(x, y, opt)
    local obj = Object.New(Base, x, y)
    obj.speed = opt.speed or     obj.speed
    obj.speed_dir = opt.speed_dir or     obj.speed_dir
    obj.life_time = opt.life_time or     obj.life_time
    obj.dmg = opt.dmg or     obj.dmg
    obj.knockback = opt.knockback or     obj.knockback
    return obj
end

