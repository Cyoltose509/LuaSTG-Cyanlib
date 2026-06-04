local base = STG.Player.ComponentBase
---@class STG.Player.System.Shoot:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Shoot = M

function M:init(player, system)
    base.init(self, player, system)
end
function M:update(dt)
end

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.shoot then
    end
end
