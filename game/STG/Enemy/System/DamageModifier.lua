local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.DamageModifier : STG.Enemy.System.SystemBase
---Damage modifier subsystem. Stacks multipliers from multiple sources.
local M = Core.Class(base)
STG.Enemy.System.DamageModifier = M

function M:init(enemy, system)
    base.init(self, enemy, system)
    self.modifiers = {}
end

---Apply all modifiers to incoming damage.
---@param amount number
---@return number
function M:apply(amount)
    local result = amount
    for _, mod in ipairs(self.modifiers) do
        if mod.apply then
            result = mod:apply(result)
        end
    end
    return result
end

---Add a modifier instance.
---@param modifier table
function M:add(modifier)
    table.insert(self.modifiers, modifier)
end

---Remove all modifiers.
function M:clear()
    self.modifiers = {}
end

function M:setProfile(profile)
end

---Default pass-through modifier.
---@param enemy STG.Enemy.Base
---@param system STG.Enemy.System
function M.Default(enemy, system)
    return {
        apply = function(self, amount)
            return amount
        end,
    }
end

return M
