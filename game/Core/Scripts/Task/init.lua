---@class Core.Task
---@field Move Core.Task.Move
---@field Object Core.Task.Object
local M = {}
Core.Task = M

local stack = {}
---@type thread[]
local threads = {}

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
                    local _, errmsg = coroutine.resume(co)
                    if errmsg then
                        error(tostring(errmsg) ..
                                "\n========== coroutine traceback ==========\n" ..
                                debug.traceback(co) ..
                                "\n========== C traceback ==========")
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

---等待t帧，在task环境内
---t是非负整数
---@param t number
function M.Wait(t)
    t = max(0, int(t or 1))
    if t == 1 then
        coroutine.yield()
    else
        for _ = 1, t do
            coroutine.yield()
        end
    end
end

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

---等待t帧，在task环境内
---t可以是小数，处理方法是把小数部分集起来，多出了1再wait1帧
---@param t number
function M.Wait2(t)
    t = max(0, t or 1)
    if t == 1 then
        coroutine.yield()
    else
        for _ = 1, t do
            coroutine.yield()
        end
        local curco = threads[#threads]
        frame_cache[curco] = frame_cache[curco] or 0
        frame_cache[curco] = frame_cache[curco] + (t - int(t))
        while frame_cache[curco] >= 1 do
            coroutine.yield()
            frame_cache[curco] = frame_cache[curco] - 1
        end
    end
end

---增量模式
M.INC_MODE = {
    SET = 0,
    ADD = 1,
    MUL = 2
}

---平滑设置一个对象的变量
---@param valname string|number|function @索引或者一个变量设置函数
---@param y number @增量
---@param t number @持续时间
---@param mode number @参见移动模式
---@param setter function @变量设置函数
---@param starttime number @等待时间
---@param vmode number @INC_MODE.SET, INC_MODE.ADD, INC_MODE.MUL，增量模式
function M.smoothSetValueTo(valname, y, t, mode, setter, starttime, vmode)
    local self = M.getSelf()
    M.Wait(starttime or 0)
    t = max(1, int(t))
    local ys = setter and valname() or self[valname]
    local dy = y - ys
    vmode = vmode or 0
    if vmode == 1 then
        dy = y
    elseif vmode == 2 then
        dy = ys * y - ys
    end
    if setter then
        for s = 1, t do
            s = Core.Lib.Easing[mode](s / t)
            setter(ys + s * dy)
            coroutine.yield()
        end
    else
        for s = 1, t do
            s = Core.Lib.Easing[mode](s / t)
            self[valname] = ys + s * dy
            coroutine.yield()
        end
    end
end

require("Core.Scripts.Task.Move")
require("Core.Scripts.Task.Object")

