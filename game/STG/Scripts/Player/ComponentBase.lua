---@class STG.Player.ComponentBase
local M = Core.Class()
STG.Player.ComponentBase = M

function M:init(player, system)
    self.owner = player
    self.system = system
    self.config = {}
    return self
end

function M:update()
end

function M:render()

end
function M:getViewData()
    return nil
end
---@param info STG.Player.System.onDamageInfo
function M:onDamage(info)
end

function M:onDeath()
end

function M:onRemove()

end
function M:onPhaseChanged()

end
