---@class Core.Effect
---@field Post Core.Effect.Post
local M = {}
Core.Effect = M

local rand = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time())
M.rand = rand

require("Core.Scripts.Effect.Post")

local Object = Core.Object
local Render = Core.Render

local sparkle = Object.Define(Object.Base)
function sparkle:frame()
    self.alpha = max(0, self.alpha - 1 / self.lifetime)
    self.hscale = self.r / 75
    self.vscale = self.hscale
    Core.Task.Do(self)
    local p
    local maxtime = max(10, self.lifetime - 20)
    for i = #self.particle, 1, -1 do
        p = self.particle[i]
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.vx = p.vx - p.vx * 0.04
        p.vy = p.vy - p.vy * 0.04
        if p.timer > maxtime then
            p.alpha = max(p.alpha - 5, 0)
            if p.alpha == 0 then
                table.remove(self.particle, i)
            end
        end
        p.timer = p.timer + 1
    end
    if self.timer >= self.lifetime and #self.particle == 0 then
        Object.Del(self)
    end
end
function sparkle:render()
    local blend = Render.BlendMode.MulAdd
    for _, p in ipairs(self.particle) do
        Object.SetImgState(self, blend, p.alpha, self._r, self._g, self._b)
        Render.Image(self.img, p.x, p.y, 0, 8 / 150)
    end
    if self.alpha > 0 then
        Object.SetImgState(self, blend, self.alpha * 255, self._r, self._g, self._b)
        Object.DefaultRender(self)
    end
end

function M.Sparkle(x, y, time, radius, r, g, b, count, layer)
    local self = Object.New(sparkle)
    self.x, self.y = x, y
    self.layer = layer or -400
    self.group = Core.Object.Group.Ghost
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
    for _ = 1, count do
        local a = rand:float(0, 360)
        local v = rand:float(3, 6)
        table.insert(self.particle, {
            x = self.x, y = self.y,
            vx = cos(a) * v, vy = sin(a) * v,
            alpha = rand:float(150, 250), timer = 0,
        })
    end
    return self
end

local wave = Object.Define(Object.Base)
function wave:frame()
    self.lr = self.nr
    local k = min(1, self.timer / self.time)
    self.alpha = max(0, 255 * (1 - k))
    self.nr = self.ir + Core.Lib.Easing[2](k) * (self.sr - self.ir)
    self.dr = self.nr - self.lr
    self.smear_r = self.smear_r + self.dr
    self.smear_r = self.smear_r - self.smear_r * 0.13
    if self.timer > self.time then
        Object.Del(self)
    end
end
function wave:render()
    local N = int(clamp(self.nr / 3, 20, 80))
    Render.Draw.SetState(Render.BlendMode.MulAdd, self.alpha * self.alpha_index, self._r, self._g, self._b)
    Render.Draw.Sector(self.x, self.y, self.nr - self.w / 2, self.nr + self.w / 2, 0, 360, N)
    local c1, c2 = Render.Color(self.alpha * self.alpha_index / 2, self._r, self._g, self._b), Render.Color(0, self._r, self._g, self._b)
    Render.Draw.SetState(Render.BlendMode.MulAdd, c1, c2, c2, c1)
    Render.Draw.Sector(self.x, self.y, self.nr - self.smear_r, self.nr, 0, 360, N)
    if self.out then
        Render.Draw.Sector(self.x, self.y, self.nr + self.smear_r, self.nr, 0, 360, N)
    end
end

function M.Wave(x, y, w, ir, sr, time, r, g, b, out, layer)
    local self = Object.New(wave)
    self.x, self.y = x, y
    self.layer = layer or -400
    self.group = Core.Object.Group.Ghost
    self.w = w
    self.sr = sr
    self.bound = false
    self.time = time
    self.ir = ir or 0
    self.nr = self.ir
    self.dr = 0
    self.lr = self.nr
    self.smear_r = 0
    self.alpha = 255
    self.colli = false
    self._r, self._g, self._b = r or 255, g or 255, b or 255
    self.alpha_index = 1
    self.out = out
    return self
end

local pulse = Object.Define(Object.Base)
function pulse:frame()
    task.Do(self)
    if self.timer >= self.lifetime then
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
    self.fade_in_mode = 0
    self.fade_out_mode = 0
    Core.Task.New(self, function()
        for i = 1, fade_in do
            self._a = Core.Lib.Easing[self.fade_in_mode](i / fade_in) * col.a
            Core.Task.Wait()
        end
        task.Wait(stay)
        for i = 1, fade_out do
            self._a = col.a * (1 - Core.Lib.Easing[self.fade_out_mode](i / fade_out))
            Core.Task.Wait()
        end
    end)
    return self
end
