local base = STG.Player.ComponentBase

---@class STG.Player.System.Move:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Move = M

function M:init(player, system)
    -- component base init
    base.init(self, player, system)
    self.high_speed = 10
    self.low_speed = 5
    self.move_vec = Core.Math.Vector2.New(0, 0)
end

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.move then
        local move = profile.move
        self.high_speed = move.high_speed or self.high_speed
        self.low_speed = move.low_speed or self.low_speed
    end
end
function M:update(dt)
    local phase = self.system:getPhase()
    if phase ~= "normal" then
        return
    end
    local p = self.player
    local input = self.system:getInput()
    local speed = self.system:isSlow() and self.low_speed or self.high_speed
    self.move_vec = input.move * speed * dt
    p.x = p.x + self.move_vec.x
    p.y = p.y + self.move_vec.y

    -- Clamp to player boundaries (tighter than world, matching legacy)
    local w = Core.World.GetMain()
    p.x = clamp(p.x, (w.pl or w.l) + 8, (w.pr or w.r) - 8)
    p.y = clamp(p.y, (w.pb or w.b) + 16, (w.pt or w.t) - 32)
end

function M:getVector()
    return self.move_vec
end
