local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.Health : STG.Enemy.System.SystemBase
local M = Core.Class(base)
STG.Enemy.System.Health = M


function M:init(enemy, system)
    base.init(self, enemy, system)
end


