---@class STG.Event
local M = {}
STG.Event = M

local EventListener = Core.Lib.EventListener

---@type Core.Lib.EventListener
local bus = EventListener()

-- ========================================
-- Event group constants (avoid magic strings)
-- ========================================
M.Group = {
    PLAYER_DAMAGE     = "stg.player.damage",
    PLAYER_DEATH      = "stg.player.death",
    PLAYER_BOMB       = "stg.player.bomb",
    PLAYER_POWER      = "stg.player.power",
    PLAYER_GRAZE      = "stg.player.graze",
    PLAYER_LIFE       = "stg.player.life",
    PLAYER_SCORE      = "stg.player.score",
    ENEMY_SPAWN       = "stg.enemy.spawn",
    ENEMY_DEATH       = "stg.enemy.death",
    ENEMY_PHASE       = "stg.enemy.phase",
    ENEMY_DAMAGE      = "stg.enemy.damage",
    BOSS_SPAWN        = "stg.boss.spawn",
    BOSS_DEATH        = "stg.boss.death",
    BOSS_SPELL_START  = "stg.boss.spell_start",
    BOSS_SPELL_END    = "stg.boss.spell_end",
    BULLET_SPAWN      = "stg.bullet.spawn",
    BULLET_DELETE     = "stg.bullet.delete",
    ITEM_COLLECT      = "stg.item.collect",
    ITEM_SPAWN        = "stg.item.spawn",
    SCORE_CHANGE      = "stg.score.change",
    DIFFICULTY_CHANGE = "stg.difficulty.change",
    GAME_START        = "stg.game.start",
    GAME_OVER         = "stg.game.over",
    GAME_CLEAR        = "stg.game.clear",
    GAME_RESTART      = "stg.game.restart",
    GAME_QUIT         = "stg.game.quit",
    STAGE_START       = "stg.stage.start",
    STAGE_CLEAR       = "stg.stage.clear",
    PAUSE             = "stg.pause.enter",
    RESUME            = "stg.pause.exit",
    REPLAY_START      = "stg.replay.start",
    REPLAY_STOP       = "stg.replay.stop",
    REPLAY_SYNC       = "stg.replay.sync",
    REPLAY_DESYNC     = "stg.replay.desync",
}

-- Initialize all event groups
for _, name in pairs(M.Group) do
    bus:create(name)
end

---Register a listener on an event group.
---@param group string Event group name (use STG.Event.Group.XXX)
---@param name string Unique listener name
---@param func function Callback
---@param level number|nil Priority (higher = earlier)
function M.On(group, name, func, level)
    bus:addEvent(group, name, level or 0, func)
end

---Remove a listener.
---@param group string
---@param name string
function M.Off(group, name)
    bus:remove(group, name)
end

---Fire an event.
---@param group string Event group name
---@param ... any Event arguments
function M.Fire(group, ...)
    bus:dispatch(group, ...)
end

---Get the raw event bus (for advanced use).
---@return Core.Lib.EventListener
function M.GetBus()
    return bus
end

return M
