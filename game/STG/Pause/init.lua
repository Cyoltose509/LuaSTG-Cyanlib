---@class STG.Pause
local M = {}
STG.Pause = M

local Time = Core.Time
local Event = STG.Event
local Input = Core.Input

M.is_paused = false
M._prev_speed = 1

-- ========================================
-- Core pause logic
-- ========================================

function M.Pause()
    if M.is_paused then
        return
    end
    M.is_paused = true
    M._prev_speed = Time.GetSpeed()
    Time.SetSpeed(0)
    --Core.System.Log(Core.System.LogType.Info, "[Pause] PAUSED, firing PAUSE event")
    Event.Fire(Event.Group.PAUSE)
end

function M.Resume()
    if not M.is_paused then
        return
    end
    M.is_paused = false
    Time.SetSpeed(M._prev_speed)
    --Core.System.Log(Core.System.LogType.Info, "[Pause] RESUMED, firing RESUME event")
    Event.Fire(Event.Group.RESUME)
end

function M.Toggle()
    if M.is_paused then
        M.Resume()
    else
        M.Pause()
    end
end

function M.IsPaused()
    return M.is_paused
end

function M.Update()
    if Input.ButtonDown("Player.Pause") then
        -- Core.System.Log(Core.System.LogType.Info, "[Pause] ButtonDown detected, toggling. is_paused=" .. tostring(M.is_paused))
        M.Toggle()
    end
end

function M.ForceResume()
    if M.is_paused then
        M.is_paused = false
        Time.SetSpeed(M._prev_speed)
    end
end

require("STG.Pause.Menu")

