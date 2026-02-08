local base = STG.Player.ComponentBase

---@class STG.Player.System.Hit:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Hit = M

function M:init(player, system)
    base.init(self, player, system)
    self.timer = 0
    self.hit_time = 0
    self.angle = 0
end
function M:update(dt)
    if self.hitting then
        self.timer = self.timer + dt
        local p = self.power * (1 - self.timer / self.hit_time)
        self.player.transform.x = self.player.transform.x + cos(self.angle) * p * dt
        self.player.transform.y = self.player.transform.y + sin(self.angle) * p * dt
        if self.timer >= self.hit_time then
            self.hitting = false
        end
    end
end
---@param info STG.Player.System.HitInfo
function M:apply(info)
    self.angle = info.angle
    self.power = info.power or 20
    self.hit_time = info.time or 0.5
    self.hitting = true
    self.timer = 0
end

function M:setProfile(profile)
    if not profile then
        return
    end
end
