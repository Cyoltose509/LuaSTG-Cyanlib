local base = STG.Player.ComponentBase

---@class STG.Player.System.Hit:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Hit = M

function M:init(player, system)
    base.init(self, player, system)
    self.hit_flash_timer = 0
    self.hit_flash_duration = 0.25
end

function M:update(dt)
    if self.hit_flash_timer > 0 then
        self.hit_flash_timer = self.hit_flash_timer - dt
    end
end

---Trigger hit flash effect (no displacement).
function M:apply(info)
    self.hit_flash_timer = self.hit_flash_duration
end

function M:isFlashing()
    return self.hit_flash_timer > 0
end

function M:setProfile(profile)
end
