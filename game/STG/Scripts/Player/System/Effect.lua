local base = STG.Player.ComponentBase

---@class STG.Player.System.Effect:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Effect = M

function M:init(player, system)
    base.init(self, player, system)
    self.timer = 0
end

function M:update(dt)
    self.timer = self.timer + dt
end

function M:setProfile(profile)
    if not profile then
        return
    end
    self.config = self.config or {}
end

function M:render()
end