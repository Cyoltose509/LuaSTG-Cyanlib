---@class STG.Constants
local M = {}
STG.Constants = M

-- ========================================
-- Frame timing
-- ========================================
M.FRAME = {
    FPS = 60,
    UNIT = 1 / 60,
}

-- ========================================
-- Player
-- ========================================
M.PLAYER = {
    HIGH_SPEED = 10,
    LOW_SPEED = 5,
    INVINCIBLE_TIME = 0.5,
    DEFAULT_SIZE = 1,
    GRAZE_RADIUS = 48,
    GRAZE_PARTICLE_COUNT_MIN = 8,
    GRAZE_PARTICLE_COUNT_MAX = 13,
    SLOW_TRANSITION_FRAMES = 30,
    AURA_SPEED = 1.5,
}

-- ========================================
-- Player Shoot
-- ========================================
M.PLAYER_SHOOT = {
    DEFAULT_SPEED = 5,
    DEFAULT_DMG = 10,
    DEFAULT_KNOCKBACK = 15,
    DEFAULT_BULLET_LIFE = 60,
    DEFAULT_BULLET_VELOCITY = 10,
}

-- ========================================
-- Player Health
-- ========================================
M.PLAYER_HEALTH = {
    CONTAINER_CAPACITY = 10,
    MAX_CONTAINERS = 10,
    HURT_EFF_DURATION = 0.5,
    TRASH_WAIT = 1,
    VIEW_INTERP_SPEED_FILL = 6,
    VIEW_INTERP_SPEED_X = 10,
}

-- ========================================
-- Enemy
-- ========================================
M.ENEMY = {
    DEFAULT_HP = 30,
    DEFAULT_SIZE = 1,
    DEFAULT_COLLIDE_R = 10,
    ENTER_TIME = 0.5,
    MOVE_SPEED = 20,
    DEFAULT_KNOCKBACK_TIME = 0.15,
    DEFAULT_IMPULSE_TIME = 0.2,
    INVINCIBLE_TIME = 0.5,
}

-- ========================================
-- Enemy Death Effect
-- ========================================
M.ENEMY_DEATH = {
    BREAK_LIFETIME = 30,
    DRAW_LIFETIME = 45,
    SIMPLE_PARTICLE_LIFETIME_MIN = 70,
    SIMPLE_PARTICLE_LIFETIME_MAX = 90,
    SIMPLE_PARTICLE_VELOCITY_MIN = 0.8,
    SIMPLE_PARTICLE_VELOCITY_MAX = 2,
    PARTICLE_COUNT_MIN = 4,
    PARTICLE_COUNT_MAX = 8,
}

-- ========================================
-- Boss
-- ========================================
M.BOSS = {
    HP_BAR_SHOW_DURATION = 0.5,
    HP_BAR_HOLD_DURATION = 3,
    HP_BAR_HIDE_DURATION = 0.5,
    SPELL_BONUS_BASE = 100000,
    DEFAULT_SPELL_TIME = 30,
}

-- ========================================
-- Bullet
-- ========================================
M.BULLET = {
    FOG_TIME = 11,
    LAYER_OFFSET = -50,
    COLOR_ALPHA = 192,
}

-- ========================================
-- Laser
-- ========================================
M.LASER = {
    COLLIDER_INTERVAL = 32,
}

-- ========================================
-- Item
-- ========================================
M.ITEM = {
    FALL_V = 3.4,
    FALL_A = 0.06,
    COLLECT_ATTRACT_V = 8,
    ATTRACT_THRESHOLD = 8,
    DROP_POINT_ATTRACT_V = 16,
    DROP_POINT_IMPULSE_VY_MIN = 6.5,
    DROP_POINT_IMPULSE_VY_MAX = 7.5,
}

-- ========================================
-- Effect (Hinter / Fade)
-- ========================================
M.EFFECT = {
    FADE_DEFAULT_LIFETIME = 11,
}

-- ========================================
-- Difficulty multipliers
-- ========================================
M.DIFFICULTY = {
    EASY = 0.5,
    NORMAL = 1.0,
    HARD = 1.5,
    LUNATIC = 2.0,
}

-- ========================================
-- Scoring
-- ========================================
M.SCORE = {
    GRAZE_BASE = { 100, 200, 500, 1000 },
    POINT_ITEM_BASE = 100,
    POWER_ITEM_VALUE = 1,
    BIG_POWER_ITEM_VALUE = 3,
    LIFE_FRAGMENT_COUNT = 5,
    BOMB_FRAGMENT_COUNT = 4,
}

-- ========================================
-- Replay
-- ========================================
M.REPLAY = {
    VERSION = 1,
    DESYNC_CHECK_INTERVAL = 60,
    MAX_FRAMES = 3600 * 60 * 2,
}

-- ========================================
-- Pause
-- ========================================
M.PAUSE = {
    TIME_SCALE_TARGET = 0,
}

-- ========================================
-- World boundary defaults
-- ========================================
M.WORLD = {
    MARGIN_ITEM = 16,
    MARGIN_DROP_POINT = 8,
}
