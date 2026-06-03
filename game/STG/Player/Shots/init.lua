---@class STG.Player.Shots
local M = {}
STG.Player.Shots = M

local Object = STG.Object
local Render = Core.Render
local Vec2 = Core.Math.Vector2

---@class STG.Player.Shots.Straight
local Straight = Object.Define()
function Straight:init(x, y)

    self.x, self.y = x, y
    self.layer = Object.Layer.PlayerShots
    self.group = Object.Group.PlayerShots
    self.r = 20
    self.a = self.r
    self.b = self.r

    self.speed_dir = Vec2.up
    self.speed = 10
    self.life_time = 60
    self.dmg = 4
    self.timer = 0
    self._blend = Core.Render.BlendMode.Default
    self._color = Core.Render.Color.Default
    self.time = STG.System.Time()
    --STG.Collision.SetNotCollideInGroup(self, true)
end
function Straight:frame()
    local dt = self.time:getDelta()
    -- 计算速度分量
    self.vx = self.speed * self.speed_dir.x * dt
    self.vy = self.speed * self.speed_dir.y * dt

    if self.timer >= self.life_time then
        Object.Del(self)
    end
end
function Straight:del()
end
function Straight:render()
end

---@param opt STG.Player.Shots.Straight
function M.Spawn(x, y, opt)
    local obj = Object.New(Straight, x, y)
    obj.speed = opt.speed or obj.speed
    obj.speed_dir = opt.speed_dir or obj.speed_dir
    obj.dmg = opt.dmg or obj.dmg
    obj.life_time = opt.life_time or obj.life_time
    return obj
end

