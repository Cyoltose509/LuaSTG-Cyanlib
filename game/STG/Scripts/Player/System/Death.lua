local base = STG.Player.ComponentBase

---@class STG.Player.System.Death:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Death = M

function M:onDeath()
    local run = STG.Run.Get()
    run:onPlayerDeath()
end