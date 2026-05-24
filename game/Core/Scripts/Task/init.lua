---@class Core.Task
local M = {}
Core.Task = M

local stack = {}
---@type thread[]
local threads = {}
local max, int = max, int

local coroutine = coroutine

function M.New(unit, f)
    if not unit.task then
        unit.task = {}
    end
    if f then
        local rt = coroutine.create(f)
        unit.task[#unit.task + 1] = rt
        return rt, #unit.task
    end
end

function M.Do(unit)
    if unit.task then
        for i = #unit.task, 1, -1 do
            local co = unit.task[i]
            if co then
                if coroutine.status(co) ~= 'dead' then
                    stack[#stack + 1] = unit
                    threads[#threads + 1] = co
                    local ok, err = coroutine.resume(co)
                    if not ok then
                        error(
                                tostring(err) ..
                                        "\n========== coroutine traceback ==========\n" ..
                                        debug.traceback(co) ..
                                        "\n========== C traceback =========="
                        )
                    end
                    stack[#stack] = nil
                    threads[#threads] = nil
                else
                    table.remove(unit.task, i)
                end
            end
        end
    end
end

function M.Clear(unit, keepCurtask)
    if keepCurtask then
        local flag = false
        local co = threads[#threads]
        for i = 1, #unit.task do
            if unit.task[i] == co then
                flag = true
                break
            end
        end
        unit.task = {}
        if flag then
            unit.task = { co }
        end
    else
        unit.task = {}
    end
end

function M.Del(unit, delco)
    for i = #unit.task, 1, -1 do
        local t = unit.task[i]
        if t == delco then
            table.remove(unit.task, i)
        end
    end
end

M.Yield = coroutine.yield

function M.getSelf()
    local c = stack[#stack]
    if c.taskself then
        return c.taskself
    else
        return c
    end
end

---小数位的缓存
local frame_cache = setmetatable({  }, { __mode = "k" })
local second_cache = setmetatable({  }, { __mode = "k" })

---等待f帧，在task环境内
---Wait for t frames in the task environment
---@param frame number
---@param save_frac boolean 是否保存小数部分
function M.Wait(frame, save_frac)
    frame = max(0, frame or 1)
    if frame == 1 then
        coroutine.yield()
    else
        for _ = 1, frame do
            coroutine.yield()
        end
        if save_frac then
            local frac = frame - int(frame)
            if frac > 0 then
                local curco = threads[#threads]
                frame_cache[curco] = frame_cache[curco] or 0
                frame_cache[curco] = frame_cache[curco] + frac
                while frame_cache[curco] >= 1 do
                    coroutine.yield()
                    frame_cache[curco] = frame_cache[curco] - 1
                end
            end
        end
    end
end

---等待t秒
---由Core.Time.GetDelta赞助播出
---Wait for t seconds
---Sponsored by Core.Time.GetDelta
---@param sec number
function M.Wait2(sec)
    local get = Core.Time.GetDelta
    local _t = 0
    local curco = threads[#threads]
    second_cache[curco] = second_cache[curco] or 0
    sec = sec - second_cache[curco]
    second_cache[curco] = max(-sec, 0)
    while _t < sec do
        coroutine.yield()
        _t = _t + get()
    end
    local frac = _t - sec
    second_cache[curco] = second_cache[curco] + frac
end
