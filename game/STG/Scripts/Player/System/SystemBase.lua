---@class STG.Player.System.SystemBase
local M = Core.Class()
STG.Player.System.SystemBase = M

---@param player STG.Player.Base
---@param system STG.Player.System
function M:init(player, system)
    self.player = player
    self.system = system
end

function M:setProfile()
end

function M:update()
end

function M:getViewData()
    return nil
end

function M:onDeath()

end
function M:onDamage()

end
---@param from number
---@param to number
function M:onPhaseChanged(from, to)

end

