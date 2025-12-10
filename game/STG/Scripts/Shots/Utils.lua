---@class STG.Shots.Utils
local M = {}
STG.Shots.Utils = M

local Object = STG.Object
local Base = STG.Shots.Bullet.Base
local Task = Core.Task
local MulAdd = Core.Render.BlendMode.MulAdd
local Laser = STG.Shots.Laser
local Curve = STG.Shots.CurveLaser

---@param x number
---@param y number
---@param sty STG.Shots.Bullet.Style.Base
---@param col number
---@param v number
---@param a number
---@param omega number
---@param stay boolean
---@param destroyable boolean
function M.BulletStraight(x, y, sty, col, v, a, omega, stay, destroyable)
    local self = Object.New(Base, sty, col, stay, destroyable)
    self.x, self.y = x, y
    self.omega = omega or 0
    Object.SetV(self, v or 0, a or 0, not sty.disable_navi)
    return self
end
---@param style STG.Shots.Bullet.Style.Base
function M.BulletDecel(x, y, style, col, fv, v, a, mulAdd, stay, wait, time)
    local self = Object.New(Base, style, col, stay)
    self.x, self.y = x, y
    self._blend = mulAdd and MulAdd or self._blend
    self.wait = wait or 0
    self.time = time or 25
    Core.Object.SetV(self, fv, a, not style.disable_navi)
    Task.New(self, function()
        Task.Wait(self.wait)
        Task.Object.ChangingV(self, fv, v, a, self.time, not style.disable_navi)
    end)
    return self
end
---@param style STG.Shots.Bullet.Style.Base
function M.BulletAccel(x, y, style, col, fv, v, a, mulAdd, stay, wait, time)
    return M.BulletDecel(x, y, style, col, fv, v, a, mulAdd, stay, wait or 60, time or 120)
end
---@param style STG.Shots.Bullet.Style.Base
function M.BulletDecAcc(x, y, style, col, fv, v, a, mulAdd, stay)
    local self = Object.New(Base, style, col, stay)
    self.x, self.y = x, y
    self._blend = mulAdd and MulAdd or self._blend
    self.time1, self.time2, self.time3 = 25, 60, 120
    self.middle_v = 0.5
    Object.SetV(self, fv, a, not style.disable_navi)
    Task.New(self, function()
        Task.Object.ChangingV(self, fv, self.middle_v, a, self.time1, not style.disable_navi)
        Task.Wait(self.time2)
        Task.Object.ChangingV(self, self.middle_v, v, a, self.time3, not style.disable_navi)
    end)
    return self
end
---离散式动作段序列子弹
---使用例子：M.Segmented(x, y, style, col, stay, { {v = 3, a = 0, time = 100}, {func=function(self)... end} })
---Separate action sequence bullet
---@param style STG.Shots.Bullet.Style.Base
function M.BulletSegmented(x, y, style, col, stay, ...)
    local self = Object.New(Base, style, col, stay)
    self.x, self.y = x, y
    self.segments = { ... }
    Object.SetV(self, self.segments[1].v, self.segments[1].a, not style.disable_navi)
    Task.New(self, function()
        for i, con in ipairs(self.segments) do
            if con.v and con.a then
                Object.SetV(self, con.v, con.a, not style.disable_navi)
            end
            if con.func then
                con.func(self)
            end
            --TODO
            --PlaySound("kira00", 0.1, self.x / 256, true)
            if i == #self.segments then
                break
            end
            Task.Object.ChangingV(self, con.v, 0, con.a, int(con.time or 1), not style.disable_navi, con.easing)
            Task.Wait(con.wait or 0)
        end
    end)
    return self
end

---速度驱动的动态转向子弹
---使用例子：M.Steering(x, y, style, col, v, a, stay, { {v = 3, r = 0.1, time = 100}, {v=2,r=-2,time=50,wait=60} })
---Dynamic turn-around bullet with speed-driven steering
---@param style STG.Shots.Bullet.Style.Base
function M.BulletSteering(x, y, style, col, v, a, stay, ...)
    local self = Object.New(Base, style, col, stay)
    self.x, self.y = x, y
    self.v, self.angle = v, a
    self.segments = { ... }
    Object.SetV(self, self.v, self.angle, not style.disable_navi)
    Task.New(self, function()
        local _v
        for _, con in ipairs(self.segments) do
            Task.Wait(con.wait or 0)
            con.v = con.v or self.v
            _v = -self.v + con.v
            con.r = con.r or 0
            if con.func then
                con.func(self)
            end
            Task.Object.ChangingVA(self, self.v, con.v, self.angle, con.r, con.time, not style.disable_navi, con.easing)
            self.angle = self.angle + con.r * con.time
            self.v = con.v or self.v
        end
        self.changed = true
    end)
    return self
end

function M.BulletSetV(x, y, style, col, vx, vy, stay)
    local self = Object.New(Base, style, col, stay)
    self.x, self.y = x, y
    self.vx, self.vy = vx, vy
    if not style.disable_navi then
        self.rot = atan2(vy, vx)
    end
    return self
end

---创建一个雾化效果
---Create a fog effect
---@overload fun(x: number, y: number, sty: STG.Shots.Bullet.Style.Base, col: number, v: number, a: number, mulAdd: boolean): lstg.GameObject
---@overload fun(obj: lstg.GameObject): lstg.GameObject
function M.BulletFogEffect(x, y, sty, col, v, a, mulAdd)
    if type(x) == "table" then
        local self = Object.New(Base, x.imgclass, x._index, false)
        self.x, self.y = x.x, x.y
        self.colli = false
        self._blend = x._blend
        Task.New(self, function()
            for _ = 1, self.fogtime do
                if not Object.IsValid(x) then
                    break
                end
                self.x, self.y = x.x, x.y
                task.Wait()
            end
            Object.RawDel(self)
        end)
        return self
    else
        local self = Object.New(Base, sty, col, false)
        self.colli = false
        self.x, self.y = x, y
        if v and a then
            Object.SetV(self, v, a, not sty.disable_navi)
        end
        self._blend = mulAdd and MulAdd or self._blend
        Task.New(self, function()
            Task.Wait(self.fogtime)
            Object.RawDel(self)
        end)
        return self
    end

end

function M.LaserStraight(x, y, col, v, a, growTime, w, param, head)
    w = w or 8
    head = head or 0
    param = param or w
    local self = Laser.Create(x, y, a, 0, 0, 0, w, w, head, col)
    Laser.Grow(self, w, v, growTime, param, a)
    return self
end

--TODO
local Radial = Object.Define(Laser.Base)
function Radial:render()
    local color = STG.Bullet.Color[self.style_index]
    Core.Render.Draw.SetState(Core.Render.BlendMode.MulAdd, self.alpha * 180, color.r, color.g, color.b)
    Core.Render.Draw.Line(self.x + cos(self.rot) * self.line / 2, self.y + sin(self.rot) * self.line / 2, self.rot, self.line, 2)
    Laser.Base.render(self)
end

function M.LaserRadial(x, y, col, w, time, a, da, rv, sound)
    local self = Laser.Create(x, y, a, 0, 0, 0, 0, w, 0, col)
    --self.class = Radial
    da = da or 0
    rv = rv or 16
    self.line = 0
    self._is_radial = true
    self.radial_v = rv
    --TODO
    self.shooting_speed = rv
    self.collider_interval = 64
    Laser.ToLength(self, 40 * rv, 0, 40 * rv, 0)
    Laser.TurnHalfOn(self, w, 80)
    Core.Task.New(self, function()
        for i = 1, time do
            self.rot = a + da * (Core.Lib.Easing[2](i / time))
            Core.Task.Wait()
        end
        if sound ~= false then
            Core.Resource.Sound.Get("lazer00"):play()
        end
        Laser.TurnOn(self, w, 30, true)
        Core.Task.Wait(80)
        --[[
        for _ = 1, 40 do
            self.l3 = self.l3 + rv
            Core.Task.Wait()
        end
        for _ = 1, 40 do
            self.l1 = self.l1 + rv
            Core.Task.Wait()
        end--]]
        Laser.TurnOff(self, 30, true)
        Core.Task.Wait(30)
        self.onDelCollider = nil
        Core.Object.Del(self)
    end)
    return self
end

function M.LaserCurve(x, y, color, l, w, v, a, ...)
    local c = { ... }
    return Curve.New(x, y, color, 1, l, w, w, function(self)
        self.angle = a
        self.v = v
        Core.Object.SetV(self, v, self.angle)
        Task.New(self, function()
            local _v
            for _, con in ipairs(c) do
                Task.Wait(con.wait or 0)
                _v = -self.v + (con.v or self.v)
                con.r = con.r or 0
                con.time = con.time or 0
                if con.func then
                    con.func(self)
                end
                Task.Object.ChangingVA(self, self.v, con.v or self.v, self.angle, con.r, con.time, false)
                self.angle = self.angle + con.r * con.time
                self.v = con.v or self.v
            end
            self.changed = true
        end)
    end)
end