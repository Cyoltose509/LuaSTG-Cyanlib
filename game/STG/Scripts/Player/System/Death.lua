local base = STG.Player.System.SystemBase

---@class STG.Player.System.Death:STG.Player.System.SystemBase
local M = Core.Class(base)
STG.Player.System.Death = M

function M:onDeath()
    local run = STG.Run.Get()
    run:onPlayerDeath()
end