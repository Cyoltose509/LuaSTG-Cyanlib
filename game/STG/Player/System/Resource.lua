local base = STG.Player.ComponentBase

---@class STG.Player.System.Resource : STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Resource = M

function M:init(player, system)
    base.init(self, player, system)
    self.power = 0
    self.max_power = 4.0
    self.score = 0
    self.lives = 3
    self.bombs = 3
    self.max_bombs = 8
    self.max_lives = 8
    self.graze = 0
end

-- ========================================
-- Power
-- ========================================

---@param amount number Power points to add (raw, not level)
function M:addPower(amount)
    if amount <= 0 then
        return
    end
    local old = self.power
    self.power = min(self.max_power, self.power + amount)
    STG.Event.Fire(STG.Event.Group.PLAYER_POWER, self.player, self.power, old)
end

function M:getPower()
    return self.power
end

-- ========================================
-- Score
-- ========================================

---@param amount number
function M:addScore(amount)
    if amount <= 0 then
        return
    end
    self.score = self.score + amount
    STG.Event.Fire(STG.Event.Group.SCORE_CHANGE, self.player, amount, self.score)
    STG.Event.Fire(STG.Event.Group.PLAYER_SCORE, self.player, self.score)
end

function M:getScore()
    return self.score
end

-- ========================================
-- Lives
-- ========================================

function M:addLife(n)
    self.lives = min(self.max_lives, self.lives + (n or 1))
    STG.Event.Fire(STG.Event.Group.PLAYER_LIFE, self.player, self.lives, n or 1)
end

---Lose a life. Returns remaining lives.
---@return number remaining
function M:loseLife()
    self.lives = max(0, self.lives - 1)
    STG.Event.Fire(STG.Event.Group.PLAYER_LIFE, self.player, self.lives, -1)
    if self.lives <= 0 then
        STG.Event.Fire(STG.Event.Group.PLAYER_DEATH, self.player)
    end
    return self.lives
end

function M:getLives()
    return self.lives
end

-- ========================================
-- Bombs
-- ========================================

function M:addBomb(n)
    self.bombs = min(self.max_bombs, self.bombs + (n or 1))
end

function M:useBomb()
    self.bombs = max(0, self.bombs - 1)
    STG.Event.Fire(STG.Event.Group.PLAYER_BOMB, self.player, self.bombs)
end

function M:getBombs()
    return self.bombs
end

-- ========================================
-- Graze
-- ========================================

---@param n number
function M:addGraze(n)
    self.graze = self.graze + (n or 1)
    STG.Event.Fire(STG.Event.Group.PLAYER_GRAZE, self.player, self.graze)
end

function M:getGraze()
    return self.graze
end

-- ========================================
-- Profile
-- ========================================

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.resource then
        self.max_power = profile.resource.max_power or self.max_power
        self.max_lives = profile.resource.max_lives or self.max_lives
        self.max_bombs = profile.resource.max_bombs or self.max_bombs
        if profile.resource.starting_lives then
            self.lives = profile.resource.starting_lives
        end
        if profile.resource.starting_bombs then
            self.bombs = profile.resource.starting_bombs
        end
    end
end

function M:getViewData()
    return {
        power = self.power,
        max_power = self.max_power,
        score = self.score,
        lives = self.lives,
        bombs = self.bombs,
        graze = self.graze,
    }
end

return M
