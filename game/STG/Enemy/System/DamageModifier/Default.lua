local base = STG.Enemy.System.DamageModifier.Base

---@class STG.Enemy.System.DamageModifier.Default : STG.Enemy.System.DamageModifier.Base
local M = Core.Class(base)
STG.Enemy.System.DamageModifier.Default = M

function M:init(enemy, system)
    base.init(self, enemy, system)
    self.ratio = 0.2
end

function M:apply(damage)
    local t = self.system.timer
    if t > 0.5 then
        self:remove()
        return damage
    end
    local ratio = (1-self.ratio) * (1 - t / 0.5)
    return damage * ratio
end