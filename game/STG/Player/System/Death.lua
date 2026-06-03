local base = STG.Player.ComponentBase

---@class STG.Player.System.Death:STG.Player.ComponentBase
---4-stage death animation matching legacy THlib standard:
---  Stage 1 (death==90): death effects + life loss
---  Stage 2 (death==84): hide player
---  Stage 3 (death==50): teleport above, clear bullets
---  Stage 4 (death<50): descend back to play area
local M = Core.Class(base)
STG.Player.System.Death = M

function M:init(player, system)
    base.init(self, player, system)
    self.death_counter = 0
    self._death_stage = -1
    self._respawning = false
end

---Start death animation. Called from Health when no containers remain.
function M:startDeath()
    if self.death_counter > 0 then return end  -- already dying
    self.death_counter = 100
    self._death_stage = 0
    self.system:setPhase("stun")  -- disable input/movement/shooting during animation
end

function M:isDying()
    return self.death_counter > 0
end

---Get current death stage (0=normal, 1-4=dying, -1=unknown)
function M:getDeathStage()
    return self._death_stage
end

function M:update(dt)
    if self.death_counter <= 0 then return end

    self.death_counter = self.death_counter - 1
    local dc = self.death_counter
    local p = self.player
    local prev_stage = self._death_stage

    -- Compute death stage from counter value
    if dc == 0 or dc > 90 then
        self._death_stage = 0  -- normal (or just starting)
    elseif dc == 90 then
        self._death_stage = 1  -- trigger effects + lose life
    elseif dc == 84 then
        self._death_stage = 2  -- hide player
    elseif dc == 50 then
        self._death_stage = 3  -- teleport + bullet clear
    elseif dc < 50 then
        self._death_stage = 4  -- descending
    else
        self._death_stage = -1 -- between stages
    end

    -- Handle stage transitions
    if self._death_stage ~= prev_stage then
        if self._death_stage == 1 then
            self:_onStage1()
        elseif self._death_stage == 2 then
            self:_onStage2()
        elseif self._death_stage == 3 then
            self:_onStage3()
        elseif self._death_stage == 0 and prev_stage ~= 0 then
            self:_onRespawn()
        end
    end

    -- Stage 4: descend
    if self._death_stage == 4 then
        p.y = -224 + (50 - dc) * 1.2  -- descend from above
    end
end

---Stage 1: Death effects + lose life
function M:_onStage1()
    local px, py = self.player.x, self.player.y
    STG.Effect.DeathBurst(px, py, 255, 255, 255, 12)

    -- Actually lose the life now
    local res = self.system.component_sys:getComponent("Resource")
    if res then
        res:loseLife()
    end
end

---Stage 2: Hide the player
function M:_onStage2()
    self.player.hide = true
end

---Stage 3: Teleport above play area, clear bullets
function M:_onStage3()
    local p = self.player
    p.x = 0
    p.y = -224  -- above visible area
    p.hide = false

    -- Clear nearby enemy bullets
    STG.Effect.DeathBurst(p.x, p.y, 255, 180, 100, 8)
end

---Respawn after animation completes
function M:_onRespawn()
    local p = self.player
    p.hide = false

    local res = self.system.component_sys:getComponent("Resource")
    local lives = res and res:getLives() or 0

    if lives <= 0 then
        self.system:setPhase("dead")
    else
        -- Respawn with invincibility
        local health = self.system.component_sys:getComponent("Health")
        if health then
            health:resetContainers()
            health:setInvincible(health.invincible_default * 4)
        end
        self.system:setPhase("normal")
    end
end

---Cancel death (e.g. bomb)
function M:cancelDeath()
    self.death_counter = 0
    self._death_stage = 0
    self.player.hide = false
end

function M:onDeath()
    local run = STG.Run.Get()
    if run then run:onPlayerDeath() end
end
