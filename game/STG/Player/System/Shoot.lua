local base = STG.Player.ComponentBase
---@class STG.Player.System.Shoot:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Shoot = M

function M:init(player, system)
    base.init(self, player, system)
    self.cooldown = 0
    self.shoot_dir = Core.Math.Vector2.up
    self.speed = 5
    self.bullet_velocity = 12
    self.dmg = 10
    self.bullet_life = 60
end

function M:update(dt)
    local phase = self.system:getPhase()
    if phase ~= "normal" then return end
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end
    local shoot = self.system:getInput().shoot
    if shoot and self.cooldown <= 0 then
        self:shoot(self.shoot_dir)
        self.cooldown = 1 / (self.speed * self:getPowerMultiplier())
    end
end

function M:shoot(dir)
    local player = self.player
    STG.Player.Shots.Spawn(player.x, player.y, {
        speed = self.bullet_velocity,
        speed_dir = dir,
        dmg = self.dmg,
        life_time = self.bullet_life,
    })
    STG.SE.Play("gun00", 0.3)
end

function M:getPowerMultiplier()
    local res_comp = self.system.component_sys:getComponent("Resource")
    if not res_comp then return 1 end
    return 1 + res_comp:getPower() * 0.5
end

function M:setProfile(profile)
    if not profile then return end
    if profile.shoot then
        local s = profile.shoot
        self.speed = s.speed or self.speed
        self.dmg = s.dmg or self.dmg
        self.bullet_velocity = s.bullet_velocity or self.bullet_velocity
        self.bullet_life = s.bullet_life or self.bullet_life
    end
end
