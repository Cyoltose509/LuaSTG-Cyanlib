local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.Collide : STG.Enemy.System.SystemBase
local M = Core.Class(base)
STG.Enemy.System.Collide = M

function M:init(enemy, system)
    base.init(self, enemy, system)
end
function M:update()
end

function M:withPlayerShots(other)
    self.system:takeDamage({
        amount = other.dmg,
        type = "hit:shoot",
    })
end
function M:withWall(info)

end