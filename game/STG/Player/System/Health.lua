local base = STG.Player.ComponentBase

---@class STG.Player.System.Health:STG.Player.ComponentBase
---玩家生命值系统：残机、炸弹、无敌帧、被弹处理
local M = Core.Class(base)
STG.Player.System.Health = M

local CT = STG.Constants

function M:init(player, system)
    base.init(self, player, system)
    self:reset()
end

---重置到初始状态
function M:reset()
    self.lives = CT.PLAYER_INITIAL_LIVES
    self.bombs = CT.PLAYER_INITIAL_BOMBS
    self.max_lives = 8
    self.max_bombs = 8
    ---无敌帧剩余
    self.invincible_timer = 0
    ---是否处于被弹无敌
    self.hit_invincible = false
end

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then return end
    if profile.health then
        self.lives = profile.health.lives or self.lives
        self.bombs = profile.health.bombs or self.bombs
    end
end

function M:update(dt)
    if self.invincible_timer > 0 then
        self.invincible_timer = self.invincible_timer - dt
        if self.invincible_timer <= 0 then
            self.invincible_timer = 0
            self.hit_invincible = false
        end
    end
end

---检查是否无敌
---@return boolean
function M:isInvincible()
    return self.invincible_timer > 0
end

---设置无敌时间
---@param frames number 帧数
function M:setInvincible(frames)
    self.invincible_timer = math.max(self.invincible_timer, frames)
end

---被弹处理
---@return boolean 是否被弹 (是否有残机)
function M:onHit()
    if self:isInvincible() then
        return true -- 已无敌，不处理
    end

    -- 阶段检查 (死亡/击晕状态不处理)
    local phase = self.system:getPhase()
    if phase == "dead" or phase == "stun" then
        return true
    end

    -- 减少残机
    self.lives = self.lives - 1
    self.invincible_timer = CT.PLAYER_HIT_INVINCIBLE
    self.hit_invincible = true

    -- 触发死亡回调
    self.system:onDeath()

    return self.lives > 0
end

---获取残机数
---@return number
function M:getLives()
    return self.lives
end

---增加残机
---@param amount number
function M:addLife(amount)
    self.lives = math.min(self.lives + (amount or 1), self.max_lives)
end

---获取炸弹数
---@return number
function M:getBombs()
    return self.bombs
end

---增加炸弹
---@param amount number
function M:addBomb(amount)
    self.bombs = math.min(self.bombs + (amount or 1), self.max_bombs)
end

---使用炸弹
---@return boolean 是否成功使用
function M:useBomb()
    if self.bombs <= 0 then return false end
    self.bombs = self.bombs - 1
    return true
end

---检查是否死亡状态
---@return boolean
function M:isDead()
    return self.lives <= 0
end

---获取无敌闪烁可见性 (用于渲染闪烁效果)
---@return boolean
function M:isInvincibleVisible()
    if not self:isInvincible() then return true end
    -- 每 6 帧闪烁一次
    return math.floor(self.invincible_timer / 3) % 2 == 0
end

function M:getViewData()
    return {
        lives = self.lives,
        bombs = self.bombs,
        invincible = self.invincible_timer > 0,
    }
end

function M:getName()
    return "Health"
end

return M
