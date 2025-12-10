---@class Core.Time
---实验性功能
local M = {}
Core.Time = M

---@private
M._Delta = 1 / 60
M.Delta = 1 / 60
M.RealDelta = 1 / 60
M.Speed = 1

function M.SetSpeed(s)
    M.Speed = s
    M.Delta = M._Delta * s
end

function M.GetSpeed()
    return M.Speed
end

function M.GetDelta()
    return M.Delta
end

function M.GetRealDelta()
    return M.RealDelta
end


local MainLoop = Core.MainLoop
local watch = lstg.StopWatch()
local last_time = 0

MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Time.RealDelta",
    func = function()
        local now = watch:GetElapsed()
        local delta = now - last_time
        M.RealDelta = delta
        last_time = now
    end,
    level = -10000
})