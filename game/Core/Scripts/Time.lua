---@class Core.Time
---实验性功能
local M = {}
Core.Time = M

M.Delta = 0
M.RealDelta = 0
M.Speed = 1

M.Elapsed = 0
M.RealElapsed = 0
function M.SetSpeed(s)
    M.Speed = s
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

---返回一个节拍器
---Returns a beat timer
---@param interval number 节拍间隔，单位为秒
---@return fun():boolean 调用该函数会返回一个布尔值，表示是否到达了该节拍
function M.Beat(interval)
    if interval == 0 then
        return function()
            return true
        end
    end
    local last = Core.Time.Elapsed
    return function()
        local t = Core.Time.Elapsed
        local cur = int(t / interval)
        if cur > last then
            last = cur
            return true
        end
    end
end

---返回一个实时节拍器
---Returns a realtime beat timer
---@param interval number 节拍间隔，单位为秒
---@return fun():boolean 调用该函数会返回一个布尔值，表示是否到达了该节拍
function M.RealBeat(interval)
    if interval == 0 then
        return function()
            return true
        end
    end
    local last = Core.Time.RealElapsed
    return function()
        local t = Core.Time.RealElapsed
        local cur = int(t / interval)
        if cur > last then
            last = cur
            return true
        end
    end
end

MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Time.Delta",
    func = function()
        local now = watch:GetElapsed()
        local delta = now - last_time
        M.RealDelta = delta
        M.Delta = delta * M.Speed
        last_time = now
        M.Elapsed = M.Elapsed + M.Delta
        M.RealElapsed = M.RealElapsed + M.RealDelta
    end,
    level = -10000
})

