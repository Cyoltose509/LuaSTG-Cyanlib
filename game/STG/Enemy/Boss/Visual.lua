---@class STG.Enemy.Boss.Visual
---Boss default visual: swirling "undefined" sprites (matching BossWalkImageSystem mode=0).
---Registered as an enemy component, renders via 2D combat camera (world view).
---Uses Core/STG APIs only — no bare globals.
local M = {}
STG.Enemy.Boss.Visual = M

local lstg = lstg
local SetImageState = lstg.SetImageState
local Render = lstg.Render
local Color = lstg.Color
local cos = math.cos
local sin = math.sin

local BOSS_UNDEFINED_IMG = "stg:enemy.undefined"
local BOSS_UNDEFINED_BLEND = "mul+add"
local BOSS_UNDEFINED_COLOR = Color(128, 255, 255, 255)
local BOSS_UNDEFINED_COLOR_RESET = Color(0xFFFFFFFF)

---Create a boss visual component.
---@param enemy STG.Enemy.Base
---@param system STG.Enemy.System
local Visual = Core.Class()
function Visual:init(enemy, system)
    self._enemy = enemy
    self._system = system
end

function Visual:update()
    -- No-op, rendering is done in render()
end

function Visual:render()
    local e = self._enemy
    local ani = e.timer or 0
    local x, y = e.x, e.y

    -- BossWalkImageSystem mode=0: 4 swirling copies of "undefined"
    -- Exact match to legacy: SetImageState('undefined', 'mul+add', Color(128, 255, 255, 255))
    SetImageState(BOSS_UNDEFINED_IMG, BOSS_UNDEFINED_BLEND, BOSS_UNDEFINED_COLOR)
    Render(BOSS_UNDEFINED_IMG, x + cos(ani * 6 + 180) * 3, y + sin(ani * 6 + 180) * 3, ani * 10)
    Render(BOSS_UNDEFINED_IMG, x + cos(-ani * 6 + 180) * 3, y + sin(-ani * 6 + 180) * 3, -ani * 10)
    Render(BOSS_UNDEFINED_IMG, x + cos(ani * 6) * 3, y + sin(ani * 6) * 3, ani * 20)
    Render(BOSS_UNDEFINED_IMG, x + cos(-ani * 6) * 3, y + sin(-ani * 6) * 3, -ani * 20)
    -- Reset image state to avoid leaking blend mode (match legacy)
    SetImageState(BOSS_UNDEFINED_IMG, "", BOSS_UNDEFINED_COLOR_RESET)
end

function Visual:onRemove() end
function Visual:onDamage() end
function Visual:onDeath() end
function Visual:onPhaseChanged() end

---@param enemy STG.Enemy.Base
---@param system STG.Enemy.System
---@return Visual
function M.New(enemy, system)
    return Visual(enemy, system)
end

return M
