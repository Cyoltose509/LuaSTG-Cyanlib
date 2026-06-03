---@class STG.Enemy.ComponentBase
local M = Core.Class()
STG.Enemy.ComponentBase = M

---@param enemy STG.Enemy.Base
---@param system STG.Enemy.System
function M:init(enemy, system)
    self.enemy = enemy
    self.system = system
    self.config = {}
    return self
end

---可选钩子，子组件实现细化逻辑
function M:update()
end

function M:render()
end
function M:getViewData()
    return nil
end

---@param info STG.Enemy.System.DamageInfo
function M:onDamage(info)
end

function M:onDeath()
end

function M:onRemove()


end
function M:onPhaseChanged()

end
