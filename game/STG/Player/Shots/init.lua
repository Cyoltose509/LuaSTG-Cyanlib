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
    self.a, self.b = 8, 8
    self.speed_dir = Vec2.up
    self.speed = 10
    self.life_time = 60
    self.dmg = 10
    self.timer = 0
    self._blend = Core.Render.BlendMode.Default
    self._a, self._r, self._g, self._b = 200, 255, 255, 255
    self.hscale, self.vscale = 0.5, 0.5
    self.img = "stg:reimu_bullet_red"
    self.time = STG.System.Time()
    self.navi = true
end

function Straight:frame()
    local dt = self.time:getDelta()
    self.vx = self.speed * self.speed_dir.x * dt
    self.vy = self.speed * self.speed_dir.y * dt
    self.timer = self.timer + dt
    if self.timer >= self.life_time then
        Object.Del(self)
    end
end

function Straight:render()
    Object.SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
    Object.DefaultRender(self)
end

function M.Spawn(x, y, opt)
    local obj = Object.New(Straight, x, y)
    obj.speed = opt.speed or obj.speed
    obj.speed_dir = opt.speed_dir or obj.speed_dir
    obj.dmg = opt.dmg or obj.dmg
    obj.life_time = opt.life_time or obj.life_time
    return obj
end
