local base = STG.Player.System.SystemBase
---@class STG.Player.System.Shoot:STG.Player.System.SystemBase
local M = Core.Class(base)
STG.Player.System.Shoot = M

function M:init(player, system)
    base.init(self, player, system)

    self.cooldown = 0
    self.shoot_dir = Core.Math.Vector2.up
    self.move_inertia = 0.2

    self.speed = 5
    self.bullet_velocity = 5
    self.dmg = 10
    self.knockback = 10
    self.bullet_life = 2
end
function M:update(dt)
    local phase = self.system:getPhase()
    if phase ~= "normal" then
        return
    end
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end
    --self.shoot_dir =
    local shoot = self.system:getInput().shoot
    if shoot and self.cooldown <= 0 then
        self:shoot(self.shoot_dir)
        -- Core.Resource.Sound.Get("shoot"):play()
        self.cooldown = 1 / self.speed
    end
end
function M:getDir()
    return self.shoot_dir
end
function M:shoot(dir)
    local player = self.player
    STG.Player.Shots.Spawn(player.x, player.y, {
        speed = self.bullet_velocity,
        speed_dir = dir,
        dmg = self.dmg,
        knockback = self.knockback,
        life_time = self.bullet_life,
    })


end

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.shoot then
        local s = profile.shoot
        self.speed = s.speed or self.speed
        self.dmg = s.dmg or self.dmg
        self.knockback = s.knockback or self.knockback

        self.bullet_velocity = s.bullet_velocity or self.bullet_velocity
        self.bullet_life = s.bullet_life or self.bullet_life
    end
end
