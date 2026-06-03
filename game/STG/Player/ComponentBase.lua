---@class STG.Player.ComponentBase:Core.Lib.ComponentBase
local M = Core.Class(Core.Lib.ComponentBase)
STG.Player.ComponentBase = M

---@param player STG.Player.Base
---@param system STG.Player.System
function M:init(player, system)
    self.player = player
    self.system = system
end

function M:update()
end

function M:render()

end

function M:setProfile()
end

function M:getViewData()
    return nil
end

function M:onDeath()

end
function M:onDamage()

end
function M:onPhaseChanged(from, to)

end