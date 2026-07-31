local base = STG.Player.ComponentBase

---@class STG.Player.System.Death:STG.Player.ComponentBase
---玩家死亡/复活系统
local M = Core.Class(base)
STG.Player.System.Death = M

local CT = STG.Constants

function M:init(player, system)
    base.init(self, player, system)
    self.death_timer = 0
    self.respawning = false
    self.death_animation_done = false
end

function M:update(dt)
    if not self.respawning then return end

    self.death_timer = self.death_timer + dt

    -- 死亡后等待60帧再复活
    if self.death_timer >= 60 and not self.death_animation_done then
        self.death_animation_done = true
        -- 检查残机
        local health = self.system.component_sys:getComponent("Health")
        if not health or health:isDead() then
            -- 游戏结束
            self.respawning = false
            return
        end
        -- 复活
        self:_respawn()
    end
end

---触发死亡
function M:onDeath()
    local phase = self.system:getPhase()
    if phase == "dead" then return end

    self.respawning = true
    self.death_timer = 0
    self.death_animation_done = false

    -- 设置死亡阶段
    self.system:setPhase("dead")

    -- 灵力减半
    local shoot = self.system.component_sys:getComponent("Shoot")
    if shoot then
        shoot:halvePower()
    end
end

---复活
function M:_respawn()
    local p = self.player
    -- 移动到初始位置
    p.x = CT.PLAYER_SPAWN_X
    p.y = CT.PLAYER_SPAWN_Y

    -- 设置复活无敌
    local health = self.system.component_sys:getComponent("Health")
    if health then
        health:setInvincible(CT.PLAYER_RESPAWN_INVINCIBLE)
    end

    -- 设置正常阶段
    self.system:setPhase("normal")
    self.respawning = false
end

---请求立即复活 (用于续关等)
function M:forceRespawn()
    self._respawn()
end

function M:getName()
    return "Death"
end

return M
