local base = STG.Player.ComponentBase

---@class STG.Player.System.Health :STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Health = M


function M:init(player, system)
    base.init(self, player, system)
end


---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.health then
    end
end

