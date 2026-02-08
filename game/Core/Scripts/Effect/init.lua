---@class Core.Effect
---@field Post Core.Effect.Post
local M = {}
Core.Effect = M

local Object = Core.Object

local rand = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time())
M.rand = rand

local Render = Core.Render

local sparkle = Object.Define(Object.Base)
function sparkle:frame()
    local dt = Core.Time.Delta
    self.alpha = max(0, self.alpha - 1 / self.lifetime * dt)
    self.hscale = self.r / 75
    self.vscale = self.hscale
    self.time = self.time + dt
    local p
    local maxtime = max(0.15, self.lifetime - 0.3)
    for i = #self.particle, 1, -1 do
        p = self.particle[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vx = Core.Math.ExpInterp(p.vx, 0, dt * 3)
        p.vy = Core.Math.ExpInterp(p.vy, 0, dt * 3)
        if p.timer > maxtime then
            p.alpha = max(p.alpha - 300 * dt, 0)
            if p.alpha == 0 then
                table.remove(self.particle, i)
            end
        end
        p.timer = p.timer + 1
    end
    if self.time >= self.lifetime and #self.particle == 0 then
        Object.Del(self)
    end
end
function sparkle:render()
    local blend = Render.BlendMode.MulAdd
    for _, p in ipairs(self.particle) do
        Object.SetImgState(self, blend, p.alpha, self._r, self._g, self._b)
        Render.Image(self.img, p.x, p.y, 0, p.size)
    end
    if self.alpha > 0 then
        Object.SetImgState(self, blend, self.alpha * 255, self._r, self._g, self._b)
        Object.DefaultRender(self)
    end
end

function M.Sparkle(x, y, time, radius, r, g, b, count, layer)
    local self = Object.New(sparkle)
    self.x, self.y = x, y
    self.layer = layer or 0
    self.group = 0
    self.colli = false
    self.bound = false
    self.lifetime = time
    self.r = radius
    self.alpha = 1
    self._r, self._g, self._b = r, g, b
    self.particle = {}
    self.img = "bright"
    count = count or 30
    self.hscale = self.r / 75
    self.vscale = self.hscale
    self.time = 0
    for _ = 1, count do
        local a = rand:float(0, 360)
        local v = rand:float(2, 7) * radius
        table.insert(self.particle, {
            x = self.x, y = self.y,
            vx = cos(a) * v, vy = sin(a) * v,
            size = self.r / 700,
            alpha = rand:float(150, 250), timer = 0,
        })
    end
    return self
end

local wave = Object.Define(Object.Base)
function wave:frame()
    local dt = Core.Time.Delta
    self.time = self.time + dt
    self.lr = self.nr
    local k = min(1, self.time / self.lifetime)
    self.alpha = max(0, self.full_alpha * (1 - k))
    self.nr = self.ir + Core.Lib.Easing[2](k) * (self.sr - self.ir)
    self.dr = self.nr - self.lr
    self.smear_r = self.smear_r + self.dr
    self.smear_r = Core.Math.ExpInterp(self.smear_r, 0, dt * 7.2)
    if self.time > self.lifetime then
        Object.Del(self)
    end
end
function wave:render()
    local N = 60
    Render.Draw.SetState(Render.BlendMode.MulAdd, self.alpha * self.alpha_index, self._r, self._g, self._b)
    Render.Draw.Sector(self.x, self.y, self.nr - self.w / 2, self.nr + self.w / 2, 0, 360, N)
    local c1, c2 = Render.Color(self.alpha * self.alpha_index / 2, self._r, self._g, self._b), Render.Color(0, self._r, self._g, self._b)
    Render.Draw.SetState(Render.BlendMode.MulAdd, c1, c2, c2, c1)
    Render.Draw.Sector(self.x, self.y, self.nr - self.smear_r, self.nr, 0, 360, N)
    if self.out then
        Render.Draw.Sector(self.x, self.y, self.nr + self.smear_r, self.nr, 0, 360, N)
    end
end

function M.Wave(x, y, w, ir, sr, time, r, g, b, out, layer, full_alpha)
    local self = Object.New(wave)
    self.x, self.y = x, y
    self.layer = layer or 0
    self.group = 0
    self.w = w
    self.sr = sr
    self.bound = false
    self.lifetime = time
    self.ir = ir or 0
    self.nr = self.ir
    self.dr = 0
    self.lr = self.nr
    self.smear_r = 0

    self.colli = false
    self._r, self._g, self._b = r or 255, g or 255, b or 255
    self.alpha_index = 1
    self.out = out
    self.time = 0
    self.full_alpha = full_alpha or 255
    self.alpha = self.full_alpha
    return self
end

local pulse = Object.Define(Object.Base)
function pulse:frame()
    local dt = Core.Time.Delta
    self.time = self.time + dt
    if self.time < self.t1 then
        self._a = self.fade_in_mode(self.time / self.t1) * self.__a
    elseif self.time < self.t2 then
        self._a = self.__a
    elseif self.time < self.t3 then
        self._a = self.fade_out_mode((self.time - self.t2) / (self.t3 - self.t2)) * self.__a
    end
    if self.time >= self.lifetime then
        Object.RawDel(self)
    end
end
function pulse:render()
    local curC = Core.Display.Camera.GetCurrent()
    if curC and curC.getView then
        local view = curC:getView()
        Render.Draw.SetState(self.blend, self._a, self._r, self._g, self._b)
        Render.Draw.Rect(view.left, view.right, view.bottom, view.top)
    end
end

---@param layer number
---@param col Core.Render.Color
function M.PulseScreen(layer, col, blend, fade_in, stay, fade_out)
    col = col or Core.Render.Color.Default
    local self = Core.Object.New(pulse)
    self.layer = layer or 0
    self.group = Core.Object.Group.Ghost
    self.blend = blend or ""
    self.__a = col.a
    self._r, self._g, self._b = col.r, col.g, col.b
    fade_in = int(fade_in or 0)
    stay = int(stay or 0)
    fade_out = int(fade_out or 0)
    self.lifetime = fade_in + stay + fade_out
    if fade_in > 0 then
        self._a = 0
    else
        self._a = 255
    end
    self.fade_in_mode = Core.Lib.Easing.Linear
    self.fade_out_mode = Core.Lib.Easing.Linear
    self.time = 0
    self.t1 = fade_in
    self.t2 = fade_in + stay
    self.t3 = fade_in + stay + fade_out
    return self
end

require("Core.Scripts.Effect.Post")

