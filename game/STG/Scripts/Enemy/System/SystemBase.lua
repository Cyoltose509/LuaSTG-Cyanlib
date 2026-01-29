---@class STG.Enemy.System.SystemBase
local M = Core.Class()
STG.Enemy.System.SystemBase = M

---@param enemy STG.Enemy.Base
---@param system STG.Enemy.System
function M:init(enemy, system)
    self.enemy = enemy
    self.system = system
end

function M:setProfile()
end

function M:update()
end

function M:getViewData()
    return nil
end

function M:onDamage(info)
    
end

function M:onDeath()
    
end

