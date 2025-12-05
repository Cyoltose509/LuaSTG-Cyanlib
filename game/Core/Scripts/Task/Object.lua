---@class Core.Task.Object
local M = {}
Core.Task.Object = M

local Object = Core.Object

---子弹变速
---需要task环境
---@param iv number@InitVelocity
---@param tv number@TargetVelocity
---@param rotate number@朝向跟随速度方向，默认为true
---@param easing number@改变的模式，默认为线性
function M.ChangingV(self, iv, tv, angle, time, rotate, easing)
    rotate = rotate ~= false
    easing = easing or 0
    angle = angle or self.rot

    Object.SetV(self, iv, angle, rotate)
    local V = tv - iv
    local lastvx, lastvy = self.vx, self.vy
    for i = 1, time do
        local k = Core.Lib.Easing[easing](i / time)
        local v = iv + V * k
        local vx, vy = v * cos(angle), v * sin(angle)
        self.vx = self.vx + vx - lastvx
        self.vy = self.vy + vy - lastvy
        lastvx, lastvy = vx, vy
        Core.Task.Wait()
    end
end

---子弹变速变向
---需要task环境
function M.ChangingVA(self, iv, tv, ia, da, time, rotate, easing)
    rotate = rotate ~= false
    easing = easing or 0

    Object.SetV(self, iv, ia, rotate)
    local V = tv - iv
    local lastvx, lastvy = self.vx, self.vy
    for i = 1, time do
        local k = Core.Lib.Easing[easing](i / time)
        local v = iv + V * k
        local angle = ia + da * i
        local vx, vy = v * cos(angle), v * sin(angle)
        self.vx = self.vx + vx - lastvx
        self.vy = self.vy + vy - lastvy
        if rotate then
            self.rot = angle
        end
        lastvx, lastvy = vx, vy
        Core.Task.Wait()
    end
end

---独自创建一个task来执行速度变化
function M.ChangeVWithTask(self, iv, tv, angle, time, delay, rotate, easing)

    Core.Task.New(self, function()
        Core.Task.Wait(delay or 0)
        M.ChangingV(self, iv, tv, angle, time, rotate, easing)
    end)
end

---独自创建一个task来执行变速变向
function M.ChangeVAWithTask(self, iv, tv, ia, da, time, delay, rotate, easing)

    Core.Task.New(self, function()
        Core.Task.Wait(delay or 0)
        M.ChangingVA(self, iv, tv, ia, da, time, rotate, easing)
    end)
end

---大小变化过程
---需要task环境
function M.ChangingSizeColli(self, dh, dv, time, easing)
    easing = easing or 0
    local h = self.hscale
    local v = self.vscale
    local _a, _b = self.a / h, self.b / v
    for i = 1, time do
        i = Core.Lib.Easing[easing](i / time)
        self.hscale = h + dh * i
        self.vscale = v + dv * i
        self.a = _a * self.hscale
        self.b = _b * self.vscale
        Core.Task.Wait()
    end
end

function M.ChangeSizeColliWithTask(self, dh, dv, time, easing, delay)
    Core.Task.New(self, function()
        Core.Task.Wait(delay or 0)
        M.ChangingSizeColli(self, dh, dv, time, easing)
    end)
end


