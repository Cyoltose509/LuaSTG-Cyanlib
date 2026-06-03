local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.Move : STG.Enemy.System.SystemBase
local M = Core.Class(base)
STG.Enemy.System.Move = M

---@param enemy STG.Enemy.Base
---@param system STG.Enemy.System
function M:init(enemy, system)
    base.init(self, enemy, system)

    self.move_speed = 20

    self.cmd = { type = "stop" }

    self.base_vx = 0
    self.base_vy = 0

    self.overlay = {
        vx = 0,
        vy = 0,
        timer = 0,
        maxtime = 0,
    }
    self.vx = 0
    self.vy = 0

    self.modifiers = {}
    self.move_enabled = true
end

function M:enableMove(v)
    self.move_enabled = v
end

function M:setProfile(profile)
    if not profile then
        return
    end
end

function M:stop()
    self.cmd.type = "stop"
end

function M:moveWithDir(speed, ang, time)
    self.cmd.type = "dir"
    self.cmd.ang = ang
    self.cmd.speed = speed
    self.cmd.timer = 0
    self.cmd.maxtime = time or math.huge
end

function M:moveTo(x, y, time, mode)
    self.cmd.type = "to"
    self.cmd.x = x
    self.cmd.y = y
    self.cmd.init_x = self.enemy.x
    self.cmd.init_y = self.enemy.y
    self.cmd.maxtime = time
    self.cmd.timer = 0
    self.cmd.mode = mode or Core.Lib.Easing.Linear
end

function M:impulse(vx, vy, time)
    self.overlay.vx = vx
    self.overlay.vy = vy
    self.overlay.timer = max(self.overlay.timer, time or 0.2)
    self.overlay.maxtime = self.overlay.timer
end

function M:knockback(angle, power, time)
    self:impulse(
            cos(angle) * power,
            sin(angle) * power,
            time or 0.15
    )
end

function M:addModifier(name, mul, time)
    self.modifiers[name] = {
        mul = mul,
        timer = time or -1,
    }
end

function M:removeModifier(name)
    self.modifiers[name] = nil
end

function M:update(dt)
    local e = self.enemy
    local cmd = self.cmd

    local speed_mul = 1
    for k, m in pairs(self.modifiers) do
        if m.timer > 0 then
            m.timer = m.timer - dt
            if m.timer <= 0 then
                self.modifiers[k] = nil
            end
        end
        speed_mul = speed_mul * m.mul
    end

    self.base_vx, self.base_vy = 0, 0
    if self.move_enabled then
        if cmd.type == "dir" then
            local v = cmd.speed * speed_mul
            self.base_vx = cos(cmd.ang) * v
            self.base_vy = sin(cmd.ang) * v
            cmd.timer = cmd.timer + 1
            if cmd.timer >= cmd.maxtime then
                self:stop()
            end
        elseif cmd.type == "to" then
            cmd.timer = cmd.timer + speed_mul * dt
            local m = cmd.mode(min(1, cmd.timer / cmd.maxtime))
            local tx = cmd.init_x + (cmd.x - cmd.init_x) * m
            local ty = cmd.init_y + (cmd.y - cmd.init_y) * m
            self.base_vx = (tx - e.x)
            self.base_vy = (ty - e.y)
            if cmd.timer >= cmd.maxtime then
                self:stop()
            end
        end
    end
    local o = self.overlay
    local ovx = o.vx
    local ovy = o.vy
    if o.timer > 0 then
        o.timer = max(0, o.timer - dt)
        if o.timer <= 0 then
            o.vx = 0
            o.vy = 0
            ovx = 0
            ovy = 0
        end
        local p = o.timer / o.maxtime
        ovx = o.vx * p
        ovy = o.vy * p
    end
    self.vx = self.base_vx + ovx
    self.vy = self.base_vy + ovy
    e.x = e.x + self.vx
    e.y = e.y + self.vy
end
