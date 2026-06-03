local base = STG.Enemy.System.DamageModifier.Base

---@class STG.Enemy.System.DamageModifier.Percent : STG.Enemy.System.DamageModifier.Base
local M = Core.Class(base)
STG.Enemy.System.DamageModifier.Percent = M

function M:init(enemy, system, ratio)
    base.init(self, enemy, system)
    self.ratio = ratio or 0.2
end

function M:apply(damage)
    return damage * (1 - self.ratio)
end

function M.Make(ratio)
    return function(enemy, system)
        return M(enemy, system, ratio)
    end
end
