local base = STG.Player.ComponentBase

---@class STG.Player.System.Bomb : STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Bomb = M

function M:init(player, system)
    base.init(self, player, system)
    self.bomb_count = 3
    self.max_bombs = 8
    self.bomb_active = false
    self.bomb_timer = 0
    self.bomb_duration = 2
    self.bomb_invincible = true
    self.bomb_cooldown = 0
    self.bomb_used_this_frame = false
end

function M:update(dt)
    self.bomb_used_this_frame = false
    local input = self.system:getInput()
    if not input then
        return
    end
    local phase = self.system:getPhase()
    if phase ~= "normal" then
        return
    end
    -- Bomb input: press bomb key (not held)
    local bomb_pressed = input.bomb
    -- Special input: press special key
    local special_pressed = input.special

    if (bomb_pressed or special_pressed) and self.bomb_count > 0 and not self.bomb_active then
        self:useBomb()
    end

    if self.bomb_active then
        self.bomb_timer = self.bomb_timer - dt
        if self.bomb_timer <= 0 then
            self:endBomb()
        end
    end
end

function M:useBomb()
    if self.bomb_count <= 0 then
        return false
    end
    self.bomb_count = self.bomb_count - 1
    self.bomb_active = true
    self.bomb_timer = self.bomb_duration
    self.bomb_used_this_frame = true

    if self.bomb_invincible then
        local health_comp = self.system.component_sys:getComponent("Health")
        if health_comp then
            health_comp:setInvincible(self.bomb_duration)
        end
    end

    -- Notify resource component
    local res_comp = self.system.component_sys:getComponent("Resource")
    if res_comp then
        res_comp:useBomb()
    end

    STG.SE.Play("kira00")

    -- Clear enemy bullets
    STG.Object.BulletDo(function(b)
        if b.group == STG.Object.Group.EnemyBullet or b.group == STG.Object.Group.InDes then
            STG.Effect.DeathBurst(b.x, b.y, 255, 255, 200, 3)
            Core.Object.Del(b)
        end
    end)

    -- Visual effect
    STG.Effect.DeathBurst(self.player.x, self.player.y, 255, 200, 100, 20)

    STG.Event.Fire(STG.Event.Group.PLAYER_BOMB, self.player, self.bomb_count)
    return true
end

function M:endBomb()
    self.bomb_active = false
    self.bomb_timer = 0
    -- Final burst effect
    STG.Effect.DeathBurst(self.player.x, self.player.y, 255, 255, 255, 15)
end

function M:addBomb(n)
    self.bomb_count = min(self.max_bombs, self.bomb_count + (n or 1))
end

function M:getBombCount()
    return self.bomb_count
end

function M:isActive()
    return self.bomb_active
end

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.bomb then
        self.max_bombs = profile.bomb.max_bombs or self.max_bombs
        self.bomb_count = profile.bomb.starting_bombs or self.bomb_count
        self.bomb_duration = profile.bomb.duration or self.bomb_duration
        self.bomb_invincible = profile.bomb.invincible
        if self.bomb_invincible == nil then self.bomb_invincible = true end
    end
end

function M:getViewData()
    return {
        bomb_count = self.bomb_count,
        bomb_active = self.bomb_active,
    }
end

function M:onDeath()
    if self.bomb_active then
        self:endBomb()
    end
end

return M
