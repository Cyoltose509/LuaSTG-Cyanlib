---@class Core.Time
---实验性功能
local M = {}
Core.Time = M

M.delta = 0
M.real_delta = 0
M.speed = 1

M.elapsed = 0
M.real_elapsed = 0
function M.SetSpeed(s)
    M.speed = s
end

function M.GetSpeed()
    return M.speed
end

function M.GetDelta()
    return M.delta
end

function M.GetRealDelta()
    return M.real_delta
end
local watch = lstg.StopWatch()
local last_time = 0
local int = int

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
    local last = M.elapsed
    return function()
        local t = M.elapsed
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
    local last = M.real_elapsed
    return function()
        local t = M.real_elapsed
        local cur = int(t / interval)
        if cur > last then
            last = cur
            return true
        end
    end
end

Core.MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Time.Delta",
    func = function()
        local now = watch:GetElapsed()
        local delta = now - last_time
        M.real_delta = delta
        M.delta = delta * M.speed
        last_time = now
        M.elapsed = M.elapsed + M.delta
        M.real_elapsed = M.real_elapsed + M.real_delta
    end,
    level = -10000
})

