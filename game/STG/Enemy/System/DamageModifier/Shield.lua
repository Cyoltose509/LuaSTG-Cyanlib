local base = STG.Enemy.System.DamageModifier.Base

---@class STG.Enemy.System.DamageModifier.Shield : STG.Enemy.System.DamageModifier.Base
local M = Core.Class(base)
STG.Enemy.System.DamageModifier.Shield = M

function M:init(enemy, system, shield)
    base.init(self, enemy, system)
    self.shield = shield or 10
end

function M:apply(damage)
    if self.shield <= 0 then
        self:remove()
        return damage
    end
    local absorb = min(self.shield, damage)
    self.shield = self.shield - absorb
    return damage - absorb
end

function M.Make(shield)
    return function(enemy, system)
        return M(enemy, system, shield)
    end
end