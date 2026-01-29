---@class STG.Effect
local M = {}
STG.Effect = M

local Object = STG.Object
local Render = Core.Render
local Draw = Render.Draw

local rand = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time())
M.rand = rand

local hinter = Object.Define()
function hinter:frame()

    if self.timer < self.t1 then
        self.t = self.timer / self.t1
    elseif self.timer < self.t1 + self.t2 then
        self.t = 1
    elseif self.timer < self.t1 * 2 + self.t2 then
        self.t = (self.t1 * 2 + self.t2 - self.timer) / self.t1
    else
        Object.Del(self)
    end
    if self.fade then
        self.vscale = self.size
    else
        self.vscale = self.t * self.size
    end
end
function hinter:render()
    if self.fade then
        Object.SetImgState(self, self._blend, self.t * 255, 255, 255, 255)
    else
        Object.SetImgState(self, self._blend, 255, 255, 255, 255)
    end
    Object.DefaultRender(self)
end

function M.Hinter(img, size, x, y, t1, t2, fade)
    local self = Object.Instantiate(hinter)
    self.img = img
    self.x = x
    self.y = y
    self.t1 = t1
    self.t2 = t2
    self.fade = fade
    self.group = Object.Group.Ghost
    self.layer = Object.Layer.Top
    self.size = size
    self.t = 0
    self.hscale = self.size
    self._blend = Core.Render.BlendMode.Default
    return self
end

local fade = Object.Define()
function fade:render()
    Object.SetImgState(self, self.blend, self.color.a, self.color.r, self.color.g, self.color.b)
    Object.DefaultRender(self)
end
function fade:frame()
    local t = (self.life_time - self.timer) / self.life_time
    self.color = self.color1 * t + self.color2 * (1 - t)
    self.hscale = self.size1 * t + self.size2 * (1 - t)
    self.vscale = self.hscale
    if self.timer == self.life_time - 1 then
        Object.Del(self)
    end
end

function M.Fade(img, x, y, rot, vx, vy, omega, layer, blend, life_time, size1, size2, color1, color2)
    local self = Object.Instantiate(fade)
    self.img = img
    self.x = x or 0
    self.y = y or 0
    self.rot = rot or 0
    self.vx = vx or 0
    self.vy = vy or 0
    self.omega = omega or 0
    self.group = Object.Group.Ghost
    self.life_time = life_time or 11
    self.size1 = size1 or 1
    self.size2 = size2 or 0
    self.color1 = color1 or Core.Render.Color.White
    self.color2 = color2 or Core.Render.Color.Transparent
    self.layer = layer or Object.Layer.Top
    self.blend = blend or ''
    return self
end

local enemy_death_draw_ef = Object.Define()
function enemy_death_draw_ef:init(count, x, y, R, G, B, radius)
    self.R, self.G, self.B = R, G, B
    self.x = x
    self.y = y
    self.layer = Object.Layer.Enemy
    self.group = Object.Group.Ghost
    self.colli = false
    self.circle, self.circle2 = {}, {}
    self.r = 0
    self.radius = radius or 50
    for i = 1, count do
        self.circle[i] = { x + rand:float(-15, 15), y + rand:float(-15, 15) }
    end
    for i = 1, 3 do
        self.circle2[i] = { x + rand:float(-15, 15), y + rand:float(-15, 15) }
    end
    self.bound = false
end
function enemy_death_draw_ef:frame()
    self.r = Core.Lib.Easing.SineOut(self.timer / 45)
    if self.timer == 45 then
        Object.RawDel(self)
    end
end
function enemy_death_draw_ef:render()
    Draw.SetState(Render.BlendMode.MulAdd, 200 - 200 * self.r, 255, 255, 255)
    for _, t in ipairs(self.circle) do
        Draw.Sector(t[1], t[2], self.r * self.radius * 0.98, self.r * self.radius, 0, 360, 18)
    end
    Draw.SetState(Render.BlendMode.MulAdd, 200 - 200 + 200 * sin(90 - self.timer * 2), self.R, self.G, self.B)
    for _, t in ipairs(self.circle2) do
        Draw.Sector(t[1], t[2], self.r * self.radius * 0.98 * 1.5, self.r * self.radius * 1.5, 0, 360, 6)
    end

end

local enemy_death_break_ef = Object.Define()
function enemy_death_break_ef:init(x, y, R, G, B, radius)
    self.img = "stg:enemy_break_ef"
    self.layer = Object.Layer.Enemy
    self.group = Object.Group.Ghost
    self.colli = false
    self.R, self.G, self.B = R, G, B
    self.x = x
    self.y = y
    self.size = radius / 64
    self.rot = rand:float(0, 360)
    self.bound = false
end
function enemy_death_break_ef:frame()
    if self.timer == 30 then
        Object.Kill(self)
    end
end
function enemy_death_break_ef:render()
    local t = self.timer
    local alpha = 1 - t / 30
    alpha = 255 * alpha * alpha
    local img = self.img
    local rot = self.rot
    local x, y = self.x, self.y
    Object.SetImgState(self, Render.BlendMode.MulAdd, alpha, self.R, self.G, self.B)
    local h, v = 0.4 - t * 0.01, t * 0.2 + 0.7
    h = h * self.size
    v = v * self.size
    Render.Image(img, x, y, rot + 15, h, v)
    Render.Image(img, x, y, rot + 45, h, v)
    Render.Image(img, x, y, rot + 75, h, v)
end

local enemy_death_simple_particle = Object.Define()
function enemy_death_simple_particle:init(x, y, v, a, lifetime, size, r, g, b)
    self.img = "white"
    self.x, self.y = x, y
    self.rot = rand:float(0, 360)
    self.bound = false
    self.omega = rand:float(0.8, 1.2) * rand:sign()
    self.hscale = size
    self.vscale = size

    self.layer = Object.Layer.Enemy
    self.group = Object.Group.Ghost
    self.colli = false

    self.size = size
    self.v = v
    self.angle = a
    self.lifetime = lifetime
    self._x, self._y = x, y
    self.r, self.g, self.b = r, g, b
    self._s = rand:float(1, 3)
end
function enemy_death_simple_particle:frame()
    if self.timer >= self.lifetime then
        self.hide = true
        Object.Del(self)
    end
    local t = self.timer - 1
    local i = (90 / self.lifetime) * t
    local l = self.v * self.lifetime
    self.x = self._x + l * cos(self.angle) * sin(i)
    self.y = self._y + l * sin(self.angle) * sin(i)
    self.hscale = self.size + (-self._s * self.size / self.lifetime) * t
end
function enemy_death_simple_particle:render()
    Object.SetImgState(self, Render.BlendMode.MulAdd, 125 - 125 + 125 * sin(90 - min(1, self.timer / self.lifetime) * 90), self.r, self.g, self.b)
    Object.DefaultRender(self)
end

function M.EnemyDeathEffect(x, y, R, G, B, radius)
    Object.New(enemy_death_break_ef, x, y, R, G, B, radius)
    Object.New(enemy_death_draw_ef, rand:int(4, 8), x, y, R, G, B, radius)
    for _ = 1, rand:int(4, 8) do
        Object.New(enemy_death_simple_particle, x, y, rand:float(0.8, 2), rand:float(0, 360),
                rand:int(70, 90), rand:float(radius / 50, radius / 40), R, G, B)
    end
end





