---@class STG.Effect
local M = {}
STG.Effect = M

local Object = Core.Object

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
