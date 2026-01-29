local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.Death : STG.Enemy.System.SystemBase
local M = Core.Class(base)
STG.Enemy.System.Death = M

function M:onDeath()
    local x, y = self.enemy.x, self.enemy.y
    local color = STG.Enemy.Color[self.system.color_index]
    local radius = self.enemy.a
    -- Core.Resource.Sound.Get("explode1"):play()
    --Core.Effect.Wave(x, y, 2, 0, 120, 0.5, r, g, b)
    --Core.Effect.Sparkle(x, y, 0.5, 120, r, g, b)
    STG.Effect.EnemyDeathEffect(x, y, color.r, color.g, color.b, radius * 3)
end