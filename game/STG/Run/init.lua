---@class STG.Run
---@field Base STG.Run.Base
---@field GameScene STG.Run.GameScene
local M = {}
STG.Run = M

local Event = STG.Event
local Config = STG.Config
local Constants = STG.Constants
local StateMachine = Core.Lib.StateMachine

-- ========================================
-- Run State
-- ========================================

---@class STG.Run.State
---@field state string Current state name
---@field difficulty string
---@field stage number Current stage (1-based)
---@field player STG.Player.Base|nil
---@field score number
---@field lives number
---@field bombs number
---@field power number
---@field graze number
---@field continues number
---@field frame_count number
---@field stage_timer number Elapsed frames in current stage
---@field replay_mode string|nil "recording" | "playback" | nil (live)
---@field clear_status string|nil "clear" | "gameover" | nil

---@class STG.Run.Base
local Base = Core.Class()
M.Base = Base

M.Current = nil

function Base:init(opt)
    opt = opt or {}
    self.sm = StateMachine.New()
    self:_setupStates()
    self:_listenEvents()

    self.difficulty = opt.difficulty or Config.Get("difficulty") or "NORMAL"
    self.stage = opt.stage or 1
    self.player = nil
    self.score = 0
    self.lives = opt.lives or Config.Get("starting_lives") or 3
    self.bombs = opt.bombs or Config.Get("starting_bombs") or 3
    self.power = 0
    self.graze = 0
    self.continues = 0
    self.frame_count = 0
    self.stage_timer = 0
    self.replay_mode = opt.replay_mode or nil
    self.clear_status = nil
    self.boss_active = false

    -- Replay integration
    self.recorder = nil
    self.replay_player = nil
    if opt.replay_mode == "recording" then
        self.recorder = STG.Replay.Recorder(M.NewData({
            difficulty = self.difficulty,
            stage = self.stage,
        }))
        self.recorder:start(opt.seed or 0)
    elseif opt.replay_mode == "playback" and opt.replay_data then
        self.replay_player = STG.Replay.Player(opt.replay_data)
        self.replay_player:start()
    end

    M.Current = self
end

function Base:_setupStates()
    self.sm:registerState("init")
    self.sm:registerState("playing")
    self.sm:registerState("paused")
    self.sm:registerState("continue")
    self.sm:registerState("result")
    self.sm:registerState("ending")
    self.sm:setState("init")
end

function Base:_listenEvents()
    -- Listen for score changes from player resource component
    Event.On(Event.Group.SCORE_CHANGE, "Run.ScoreChange", function(player, amount, total)
        self.score = total
    end)
    Event.On(Event.Group.PLAYER_LIFE, "Run.LifeChange", function(player, lives, delta)
        self.lives = lives
        if lives <= 0 then
            self:onGameOver()
        end
    end)
    Event.On(Event.Group.PLAYER_BOMB, "Run.BombChange", function(player, bombs)
        self.bombs = bombs
    end)
    Event.On(Event.Group.PLAYER_POWER, "Run.PowerChange", function(player, power)
        self.power = power
    end)
    Event.On(Event.Group.PLAYER_GRAZE, "Run.GrazeChange", function(player, graze)
        self.graze = graze
    end)
    Event.On(Event.Group.BOSS_SPAWN, "Run.BossSpawn", function(boss)
        self.boss_active = true
    end)
    Event.On(Event.Group.BOSS_DEATH, "Run.BossDeath", function(boss)
        self.boss_active = false
    end)
    Event.On(Event.Group.ENEMY_DEATH, "Run.EnemyDeath", function(enemy, score)
        if self.player and self.player.sys and self.player.sys.component_sys then
            local res = self.player.sys.component_sys:getComponent("Resource")
            if res and score > 0 then
                res:addScore(score)
            end
        end
    end)
end

-- ========================================
-- Game Flow
-- ========================================

function Base:start()
    self.sm:setState("playing")
    Event.Fire(Event.Group.GAME_START, self)
    Event.Fire(Event.Group.STAGE_START, self.stage)
end

function Base:update(dt)
    self.frame_count = self.frame_count + 1
    if self.sm:getCurrentStateName() == "playing" then
        self.stage_timer = self.stage_timer + dt
        -- Check pause input
        STG.Pause.Update()
    end
end

function Base:pause()
    if self.sm:getCurrentStateName() == "playing" then
        STG.Pause.Pause()
        self.sm:setState("paused")
    end
end

function Base:resume()
    if self.sm:getCurrentStateName() == "paused" then
        STG.Pause.Resume()
        self.sm:setState("playing")
    end
end

-- ========================================
-- Player Lifecycle
-- ========================================

function Base:onPlayerDeath()
    local res_comp = nil
    if self.player and self.player.sys and self.player.sys.component_sys then
        res_comp = self.player.sys.component_sys:getComponent("Resource")
    end
    if res_comp then
        self.lives = res_comp:getLives()
    end

    if self.lives <= 0 then
        self:onGameOver()
    end
end

function Base:onContinue()
    self.continues = self.continues + 1
    self.lives = Config.Get("starting_lives") or 3
    self.bombs = Config.Get("starting_bombs") or 3
    self.sm:setState("playing")
end

-- ========================================
-- Stage Progression
-- ========================================

function Base:onStageClear()
    self.stage = self.stage + 1
    Event.Fire(Event.Group.STAGE_CLEAR, self.stage - 1)
    -- Check if this was the last stage
    -- (stage count is game-specific, override this)
    self:nextStage()
end

function Base:nextStage()
    Event.Fire(Event.Group.STAGE_START, self.stage)
end

-- ========================================
-- Game End
-- ========================================

function Base:onGameOver()
    self.clear_status = "gameover"
    self.sm:setState("result")
    Event.Fire(Event.Group.GAME_OVER, self)
    self:_finalizeReplay()
end

function Base:onGameClear()
    self.clear_status = "clear"
    self.sm:setState("ending")
    Event.Fire(Event.Group.GAME_CLEAR, self)
    self:_finalizeReplay()
end

function Base:onRestart()
    STG.Pause.ForceResume()
    Event.Fire(Event.Group.GAME_RESTART)
    Core.SceneManager.Restart()
end

function Base:onReturnToTitle()
    STG.Pause.ForceResume()
    Event.Fire(Event.Group.GAME_QUIT)
    self:_finalizeReplay()
    -- Scene transition handled by game-specific code
end

function Base:_finalizeReplay()
    if self.recorder then
        self.recorder:stop()
        self.recorder:save()
    end
    if self.replay_player then
        self.replay_player:stop()
    end
end

-- ========================================
-- Difficulty
-- ========================================

function Base:getDifficultyMultiplier()
    return Constants.DIFFICULTY[self.difficulty] or 1.0
end

-- ========================================
-- View Data (for HUD)
-- ========================================

function Base:getViewData()
    return {
        state = self.sm:getCurrentStateName(),
        difficulty = self.difficulty,
        stage = self.stage,
        score = self.score,
        lives = self.lives,
        bombs = self.bombs,
        power = self.power,
        graze = self.graze,
        continues = self.continues,
        frame_count = self.frame_count,
        stage_timer = self.stage_timer,
        replay_mode = self.replay_mode,
        clear_status = self.clear_status,
        boss_active = self.boss_active,
    }
end

-- ========================================
-- Static accessor
-- ========================================

---@return STG.Run.Base|nil
function M.Get()
    return M.Current
end

---Create a new run with a player.
---@param opt table
---@return STG.Run.Base
function M.New(opt)
    return Base(opt)
end

require("STG.Run.GameScene")

return M
