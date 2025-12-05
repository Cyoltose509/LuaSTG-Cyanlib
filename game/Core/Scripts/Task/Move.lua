---@class Core.Task.Move
local M = {}
Core.Task.Move = M

local Task = Core.Task
local Easing = Core.Lib.Easing

---随机移动模式
M.WANDER_MODE = {
    ---0
    TO_PLAYER = 0,
    ---1
    TO_PLAYER_X = 1,
    ---2
    TO_PLAYER_Y = 2,
    ---3
    RANDOM = 3
}

function M.LinearTo(x, y, t, mode)
    t = max(1, int(t))
    local self = Task.getSelf()
    local dx = x - self.x
    local dy = y - self.y
    local slast = 0
    for s = 1, t do
        s = Easing[mode](s / t)
        self.x = self.x + (s - slast) * dx
        self.y = self.y + (s - slast) * dy
        slast = s
        coroutine.yield()
    end
end

function M.LinearToTarget(target, t, mode)
    t = max(1, int(t))
    local self = Task.getSelf()
    local x, y = self.x, self.y
    for s = 1, t do
        if IsValid(target) then
            s = Easing[mode](s / t)
            self.x = x + s * (target.x - x)
            self.y = y + s * (target.y - y)
            coroutine.yield()
        end
    end
end

function M.AddTo(x, y, t, mode)
    t = max(1, int(t))
    local self = Task.getSelf()
    local dx = x
    local dy = y
    local slast = 0
    for s = 1, t do
        s = Easing[mode](s / t)
        self.x = self.x + (s - slast) * dx
        self.y = self.y + (s - slast) * dy
        coroutine.yield()
        slast = s
    end
end

--TODO：待改
function M.Wander(t, x1, x2, y1, y2, dxmin, dxmax, dymin, dymax, mmode, dmode)
    t = t or 60
    x1, x2 = x1 or -200, x2 or 200
    y1, y2 = y1 or 100, y2 or 160
    dxmin, dxmax = dxmin or 50, dxmax or 60
    dymin, dymax = dymin or 20, dymax or 40
    mmode = mmode or 2
    dmode = dmode or 1
    local dirx, diry = ran:Sign(), ran:Sign()
    local self = Task.getSelf()
    local p = player
    if dmode < 2 then
        if self.x > p.x then
            dirx = -1
        else
            dirx = 1
        end
    end
    if dmode == 0 or dmode == 2 then
        if self.y > p.y then
            diry = -1
        else
            diry = 1
        end
    end
    local dx = ran:Float(dxmin, dxmax)
    local dy = ran:Float(dymin, dymax)
    if self.x + dx * dirx < x1 then
        dirx = 1
    end
    if self.x + dx * dirx > x2 then
        dirx = -1
    end
    if self.y + dy * diry < y1 then
        diry = 1
    end
    if self.y + dy * diry > y2 then
        diry = -1
    end
    if t == 0 then
        return self.x + dx * dirx, self.y + dy * diry
    else
        M.LinearTo(self.x + dx * dirx, self.y + dy * diry, t, mmode)
    end
end

function M.BezierTo(t, mode, ...)
    local arg = { ... }
    local self = Task.getSelf()
    t = max(1, int(t))
    local count = (#arg) / 2
    local x = { self.x }
    local y = { self.y }
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end
    local com_num = {}
    for i = 0, count do
        com_num[i + 1] = combinNum(i, count)
    end
    local _x, _y, da
    for s = 1, t do
        s = Easing[mode](s / t)
        _x, _y = 0, 0
        for j = 0, count do
            da = com_num[j + 1] * (1 - s) ^ (count - j) * s ^ j
            _x = _x + x[j + 1] * da
            _y = _y + y[j + 1] * da
        end
        self.x = _x
        self.y = _y
        coroutine.yield()
    end
end

---@author 青山
function M.CatmullRomTo(t, mode, ...)
    local self = Task.getSelf()
    local arg = { ... }
    local count = (#arg) / 2
    local x = { self.x }
    local y = { self.y }
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end
    table.insert(x, 2 * x[#x] - x[#x - 1])
    table.insert(x, 1, 2 * x[1] - x[2])

    table.insert(y, 2 * y[#y] - y[#y - 1])
    table.insert(y, 1, 2 * y[1] - y[2])

    t = max(1, int(t))

    local timeMark = {}
    for i = 1, t do
        timeMark[i] = count * Easing[mode](i / t)
    end
    local s, j, _x, _y, j2, j3
    local st, s1t, s2t, s3t
    for i = 1, t - 1 do
        s = math.floor(timeMark[i]) + 1
        j = timeMark[i] % 1
        j2 = j * j
        j3 = j * j * j
        st = -0.5 * j3 + j2 - 0.5 * j
        s1t = 1.5 * j3 - 2.5 * j2 + 1
        s2t = -1.5 * j3 + 2 * j2 + 0.5 * j
        s3t = 0.5 * j3 - 0.5 * j2
        _x = x[s] * st + x[s + 1] * s1t + x[s + 2] * s2t + x[s + 3] * s3t
        _y = y[s] * st + y[s + 1] * s1t + y[s + 2] * s2t + y[s + 3] * s3t
        self.x = _x
        self.y = _y
        coroutine.yield()
    end
    self.x = x[count + 2]
    self.y = y[count + 2]
    coroutine.yield()
end

---@author Xiliusha
function M.Basis2To(t, mode, ...)
    --获得基本参数
    local self = Task.getSelf()
    local arg = { ... }
    t = math.max(1, math.floor(t))
    --构造采样点列表
    local count = (#arg) / 2
    local x = { self.x }
    local y = { self.y }
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end
    --检查采样点数量，如果不足3个，则插值到3个
    if count < 2 then
        --只有两个采样点时，取中点插值
        x[3] = x[2]
        y[3] = y[2]
        x[2] = x[1] + 0.5 * (x[3] - x[1])
        y[2] = y[1] + 0.5 * (y[3] - y[1])
    elseif count < 1 then
        --只有一个采样点时，只能这样了
        for i = 2, 3 do
            x[i] = x[1]
            y[i] = y[1]
        end
    end
    count = math.max(2, count)
    --储存末点，给末尾使用
    local fx, fy = x[#x], y[#y]
    --对首末采样点特化处理
    do
        x[1] = x[2] + 2 * (x[1] - x[2])
        y[1] = y[2] + 2 * (y[1] - y[2])
        --末点处理
        x[count + 1] = x[count] + 2 * (x[count + 1] - x[count])
        y[count + 1] = y[count] + 2 * (y[count + 1] - y[count])
        --插入尾数据解决越界报错
        x[count + 2] = x[count + 1]
        y[count + 2] = y[count + 1]
    end--首点处理
    --准备采样方式函数
    --开始运动
    local j, se, ct, _x, _y
    local set, se1t, se2t
    for i = 1, t do
        j = (count - 1) * Easing[mode](i / t)--采样方式
        se = math.floor(j) + 1        --3采样选择
        ct = j - math.floor(j)        --切换
        set = 0.5 * (ct - 1) * (ct - 1)
        se1t = 0.5 * (-2 * ct * ct + 2 * ct + 1)
        se2t = 0.5 * ct * ct
        _x = x[se] * set + x[se + 1] * se1t + x[se + 2] * se2t
        _y = y[se] * set + y[se + 1] * se1t + y[se + 2] * se2t
        self.x, self.y = _x, _y
        coroutine.yield()
    end
    --末尾处理，解决曲线采样带来的误差
    self.x, self.y = fx, fy
end