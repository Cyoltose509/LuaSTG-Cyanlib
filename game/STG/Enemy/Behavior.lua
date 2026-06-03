---@class STG.Enemy.Behavior
---Enemy Behavior System
---Composable, declarative behaviors for enemy movement, shooting, and action sequences.
---All behaviors are time-driven through the enemy system's update loop (respects pause).
---
---Usage:
---   e.sys:addBehavior(Sequence(
---       MoveTo(100, 0, 60, QuartOut),
---       Shoot.ring(12, 3, "arrow_big"),
---       Wait(30),
---       MoveBy(-200, 0, 60),
---       Wait(60),
---   ))
---   e.sys:addBehavior(Loop(-1, Shoot.aimed(1, 2, "ball_small", 60)))
local M = {}
STG.Enemy.Behavior = M

local Object = STG.Object
local Constants = STG.Constants
local Easing = Core.Lib.Easing
local PointSet = Core.Math.PointSet

-- ========================================
-- Base Behavior
-- ========================================

---@class STG.Enemy.Behavior.Base
local Base = Core.Class()
M.Base = Base

function Base:init()
    self._started = false
    self._complete = false
    self._timer = 0
    self._enemy = nil
    self._system = nil
end

function Base:bind(enemy, system)
    self._enemy = enemy
    self._system = system
    return self
end

function Base:start()
    self._started = true
    self._complete = false
    self._timer = 0
end

function Base:update(dt)
    if not self._started or self._complete then return end
end

function Base:isComplete()
    return self._complete
end

function Base:reset()
    self._started = false
    self._complete = false
    self._timer = 0
end

-- ========================================
-- Wait
-- ========================================

---@class STG.Enemy.Behavior.Wait : STG.Enemy.Behavior.Base
local Wait = Core.Class(Base)
M.Wait = Wait

function Wait:init(time)
    Base.init(self)
    self._time = time or 0
end

function Wait:update(dt)
    Base.update(self, dt)
    self._timer = self._timer + dt
    if self._timer >= self._time then
        self._complete = true
    end
end

---@param time number Frames to wait
function M.Wait(time)
    return Wait(time)
end

-- ========================================
-- MoveTo
-- ========================================

---@class STG.Enemy.Behavior.MoveTo : STG.Enemy.Behavior.Base
local MoveTo = Core.Class(Base)
M.MoveTo = MoveTo

function MoveTo:init(x, y, time, easing)
    Base.init(self)
    self._target_x = x or 0
    self._target_y = y or 0
    self._time = max(time or 60, 1)
    self._easing = easing or Easing.Linear
    self._start_x = 0
    self._start_y = 0
end

function MoveTo:start()
    Base.start(self)
    local e = self._enemy
    self._start_x = e.x
    self._start_y = e.y
end

function MoveTo:update(dt)
    Base.update(self, dt)
    self._timer = self._timer + dt
    local t = min(self._timer / self._time, 1)
    local et = self._easing(t)
    local e = self._enemy
    e.x = self._start_x + (self._target_x - self._start_x) * et
    e.y = self._start_y + (self._target_y - self._start_y) * et
    if t >= 1 then
        self._complete = true
    end
end

---Move to absolute position over time frames.
---@param x number Target X
---@param y number Target Y
---@param time number Duration in frames
---@param easing function|nil Easing function (default: Linear)
function M.MoveTo(x, y, time, easing)
    return MoveTo(x, y, time, easing)
end

-- ========================================
-- MoveBy
-- ========================================

local MoveBy = Core.Class(Base)
M.MoveBy = MoveBy

function MoveBy:init(dx, dy, time, easing)
    Base.init(self)
    self._dx = dx or 0
    self._dy = dy or 0
    self._time = max(time or 60, 1)
    self._easing = easing or Easing.Linear
    self._start_x = 0
    self._start_y = 0
end

function MoveBy:start()
    Base.start(self)
    local e = self._enemy
    self._start_x = e.x
    self._start_y = e.y
end

function MoveBy:update(dt)
    Base.update(self, dt)
    self._timer = self._timer + dt
    local t = min(self._timer / self._time, 1)
    local et = self._easing(t)
    local e = self._enemy
    e.x = self._start_x + self._dx * et
    e.y = self._start_y + self._dy * et
    if t >= 1 then
        self._complete = true
    end
end

---Move by relative offset over time frames.
function M.MoveBy(dx, dy, time, easing)
    return MoveBy(dx, dy, time, easing)
end

-- ========================================
-- Shoot (bullet patterns)
-- ========================================

---@class STG.Enemy.Behavior.ShootAction : STG.Enemy.Behavior.Base
local ShootAction = Core.Class(Base)

function ShootAction:init(fn)
    Base.init(self)
    self._fn = fn
end

function ShootAction:update(dt)
    Base.update(self, dt)
    if self._fn then
        self._fn(self._enemy, self._system)
    end
    self._complete = true
end

---Shoot factory: creates a shoot behavior + provides pattern helpers.
---Usage: Shoot(fn), Shoot.ring(...), Shoot.aimed(...), Shoot.wave(...)
M.Shoot = setmetatable({}, {__call = function(_, fn) return ShootAction(fn) end})

-- ========================================
-- Pre-built bullet patterns
-- ========================================

---Fire a ring of bullets from the enemy position.
---@param count number Number of bullets
---@param speed number Bullet speed
---@param style string Bullet style name
---@param offset_angle number|nil Starting angle offset (default 0)
---@param target_x number|nil Aim at target (default: straight ring)
---@param target_y number|nil
function M.Shoot.ring(count, speed, style, offset_angle, target_x, target_y)
    return ShootAction(function(e)
        local start_angle = (offset_angle or 0)
        local ex, ey = e.x, e.y
        for a in PointSet.AngleIterator(0, count) do
            local angle = a + start_angle
            if target_x and target_y then
                angle = math.atan(target_y - ey, target_x - ex) + a
            end
            STG.Shots.BulletStraight(ex, ey, style, 1, speed, angle)
        end
    end)
end

---Fire aimed bullets at a target.
---@param count number
---@param speed number
---@param style string
---@param target_x number
---@param target_y number
---@param spread number|nil Spread angle in degrees (default 0)
function M.Shoot.aimed(count, speed, style, target_x, target_y, spread)
    spread = spread or 0
    return ShootAction(function(e)
        local ex, ey = e.x, e.y
        local base_angle = math.atan(target_y - ey, target_x - ex)
        local half_spread = math.rad(spread) / 2
        local step = (count > 1) and (math.rad(spread) / (count - 1)) or 0
        for i = 0, count - 1 do
            local angle = base_angle - half_spread + step * i
            STG.Shots.BulletStraight(ex, ey, style, 1, speed, angle)
        end
    end)
end

-- ========================================
-- Sequence
-- ========================================

---@class STG.Enemy.Behavior.Sequence : STG.Enemy.Behavior.Base
local Sequence = Core.Class(Base)
M.Sequence = Sequence

function Sequence:init(...)
    Base.init(self)
    self._children = {...}
    self._index = 0
end

function Sequence:bind(enemy, system)
    Base.bind(self, enemy, system)
    for _, child in ipairs(self._children) do
        child:bind(enemy, system)
    end
    return self
end

function Sequence:start()
    Base.start(self)
    self._index = 1
    if self._children[1] then
        self._children[1]:start()
    end
end

function Sequence:update(dt)
    Base.update(self, dt)
    if self._index > #self._children then
        self._complete = true
        return
    end
    local current = self._children[self._index]
    if not current then
        self._index = self._index + 1
        return
    end
    current:update(dt)
    if current:isComplete() then
        self._index = self._index + 1
        if self._index <= #self._children then
            self._children[self._index]:start()
        else
            self._complete = true
        end
    end
end

function Sequence:reset()
    Base.reset(self)
    self._index = 0
    for _, child in ipairs(self._children) do
        child:reset()
    end
end

---Run behaviors one after another.
function M.Sequence(...)
    return Sequence(...)
end

-- ========================================
-- Loop
-- ========================================

---@class STG.Enemy.Behavior.Loop : STG.Enemy.Behavior.Base
local Loop = Core.Class(Base)
M.Loop = Loop

function Loop:init(n, behavior)
    Base.init(self)
    self._n = n or 0  -- 0 = infinite, <0 = infinite, >0 = N times
    self._child = behavior
    self._iteration = 0
end

function Loop:bind(enemy, system)
    Base.bind(self, enemy, system)
    if self._child then
        self._child:bind(enemy, system)
    end
    return self
end

function Loop:start()
    Base.start(self)
    self._iteration = 0
    if self._child then
        self._child:start()
    end
end

function Loop:update(dt)
    Base.update(self, dt)
    if not self._child then
        self._complete = true
        return
    end
    self._child:update(dt)
    if self._child:isComplete() then
        self._iteration = self._iteration + 1
        if self._n > 0 and self._iteration >= self._n then
            self._complete = true
        else
            self._child:reset()
            self._child:start()
        end
    end
end

function Loop:reset()
    Base.reset(self)
    self._iteration = 0
    if self._child then
        self._child:reset()
    end
end

---Loop a behavior N times. N <= 0 means infinite.
function M.Loop(n, behavior)
    return Loop(n, behavior)
end

-- ========================================
-- Parallel
-- ========================================

---@class STG.Enemy.Behavior.Parallel : STG.Enemy.Behavior.Base
local Parallel = Core.Class(Base)
M.Parallel = Parallel

function Parallel:init(...)
    Base.init(self)
    self._children = {...}
end

function Parallel:bind(enemy, system)
    Base.bind(self, enemy, system)
    for _, child in ipairs(self._children) do
        child:bind(enemy, system)
    end
    return self
end

function Parallel:start()
    Base.start(self)
    for _, child in ipairs(self._children) do
        child:start()
    end
end

function Parallel:update(dt)
    Base.update(self, dt)
    local all_done = true
    for _, child in ipairs(self._children) do
        if not child:isComplete() then
            child:update(dt)
            all_done = false
        end
    end
    self._complete = all_done
end

function Parallel:reset()
    Base.reset(self)
    for _, child in ipairs(self._children) do
        child:reset()
    end
end

---Run multiple behaviors simultaneously.
function M.Parallel(...)
    return Parallel(...)
end

-- ========================================
-- Compound patterns (defined after all base classes)
-- ========================================

---Fire a ring that rotates over time (wave pattern).
---@param waves number Number of waves
---@param count number Bullets per wave
---@param speed number
---@param style string
---@param interval number Frames between waves
function M.Shoot.wave(waves, count, speed, style, interval)
    interval = interval or 8
    return M.Sequence(
        M.Loop(waves, M.Sequence(
            M.Shoot.ring(count, speed, style),
            M.Wait(interval)
        ))
    )
end

-- ========================================
-- Behavior Manager (attached to enemy system)
-- ========================================

---@class STG.Enemy.Behavior.Manager
local Manager = Core.Class()
M.Manager = Manager

function Manager:init(enemy, system)
    self._enemy = enemy
    self._system = system
    self._behaviors = {}
    self._paused = false
end

---Add a behavior. Replaces the current behavior queue.
---@param behavior STG.Enemy.Behavior.Base
function Manager:add(behavior)
    self:clear()
    if behavior then
        behavior:bind(self._enemy, self._system)
        behavior:start()
        table.insert(self._behaviors, behavior)
    end
end

---Queue a behavior to run after current ones finish.
---@param behavior STG.Enemy.Behavior.Base
function Manager:queue(behavior)
    if behavior then
        behavior:bind(self._enemy, self._system)
        table.insert(self._behaviors, behavior)
        -- Start immediately if it's the only one
        if #self._behaviors == 1 then
            behavior:start()
        end
    end
end

function Manager:update(dt)
    if self._paused then return end
    if #self._behaviors == 0 then return end

    local current = self._behaviors[1]
    if not current then
        table.remove(self._behaviors, 1)
        return
    end

    current:update(dt)

    if current:isComplete() then
        table.remove(self._behaviors, 1)
        -- Start next behavior in queue
        local next_behavior = self._behaviors[1]
        if next_behavior then
            next_behavior:start()
        end
    end
end

function Manager:pause()
    self._paused = true
end

function Manager:resume()
    self._paused = false
end

function Manager:clear()
    for _, b in ipairs(self._behaviors) do
        b:reset()
    end
    self._behaviors = {}
end

function Manager:hasActive()
    return #self._behaviors > 0
end

return M
