local base = STG.Enemy.System.DamageModifier.Base

---@class STG.Enemy.System.DamageModifier.Armor : STG.Enemy.System.DamageModifier.Base
local M = Core.Class(base)
STG.Enemy.System.DamageModifier.Armor = M

function M:init(enemy, system, value)
    base.init(self, enemy, system)
    self.value = value or 1
end

function M:apply(damage)
    return max(0, damage - self.value)
end

function M.Make(value)
    return function(enemy, system)
        return M(enemy, system, value)
    end
end


