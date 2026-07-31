---@class STG.Animator
---@author OLC
---
--- 入口文件：定义 M 表 + 核心方法，子模块按需注入。
--- 文件已拆分为：
---   STG/Animator/EnemyDefaults.lua   — setupEnemyDefaultStates
---   STG/Animator/PlayerDefaults.lua  — setupPlayerDefaultStates
---   STG/Animator/LegacyWalk.lua     — setupLegacyWalkImage
local M = {}
STG.Animator = M
M.__index = M

local setmetatable = setmetatable

-- ========================================
-- 辅助函数
-- ========================================

local function easeInOutQuad(t)
    if t < 0.5 then return 2 * t * t
    else return 1 - 2 * (1 - t) * (1 - t) end
end

local function buildFrameData(prefix, ids)
    local result = {}
    for i = 1, #ids do
        result[i] = prefix .. ids[i]
    end
    return result
end

-- ========================================
-- 核心生命周期
-- ========================================

function M:init(obj, texture)
    self.walkSystem = Core.Animator.Sprite.New(obj, texture)
    self.color = Core.Render.Color.Default
    self.obj = obj
    self.obj.cast = self.obj.cast or 0
    self.obj.cast_t = self.obj.cast_t or 0
    return self
end

-- ========================================
-- 注入子模块方法（必须在 M 定义后、外部引用前）
-- ========================================

require("STG.Animator.EnemyDefaults")(M)
require("STG.Animator.PlayerDefaults")(M)
require("STG.Animator.LegacyWalk")(M, buildFrameData)

-- ========================================
-- 工具方法（薄封装 -> Core.Animator.Sprite）
-- ========================================

function M:registerFrame(id, x, y, w, h, texture)
    self.walkSystem:registerFrame(id, x, y, w, h, texture)
    return self
end

function M:registerFrameGroup(idPrefix, startX, startY, w, h, cols, rows, texture)
    self.walkSystem:registerFrameGroup(idPrefix, startX, startY, w, h, cols, rows, texture)
    return self
end

function M:registerAnimation(name, frameData, interval, loop)
    self.walkSystem:registerAnimation(name, frameData, interval, loop)
    return self
end

function M:copyAnimation(name, sourceName, reverse, mirror)
    self.walkSystem:copyAnimation(name, sourceName, reverse, mirror)
    return self
end

function M:fastCopyAnimation()
    self:copyAnimation("idle_left", "idle_right", false, true)
        :copyAnimation("move_left_enter", "move_right_enter", false, true)
        :copyAnimation("move_left_loop", "move_right_loop", false, true)
        :copyAnimation("move_right_exit", "move_right_enter", true)
        :copyAnimation("move_left_exit", "move_left_enter", true)
    return self
end

function M:setBlend(blend)
    self.walkSystem:setBlend(blend)
    return self
end

function M:setColor(a, r, g, b)
    self.walkSystem:setColor(a, r, g, b)
    return self
end

function M:setScale(h, v)
    h = h or 1
    v = v or h
    self.walkSystem:setContext("hscale", h)
    self.walkSystem:setContext("vscale", v)
    return self
end

function M:startCast(duration)
    if duration ~= nil then self.obj.cast_t = duration
    else self.obj.cast_t = 1 end
    self.obj.cast = 1
    return self
end

function M:stopCast()
    self.obj.cast_t = 0
    self.obj.cast = 0
    return self
end

function M:frame(dt)
    dt = dt or 1
    local obj = self.obj
    if obj.cast_t > 0 then
        obj.cast_t = obj.cast_t - dt
        if obj.cast_t > 0 then obj.cast = obj.cast + dt
        else obj.cast = 0 end
    elseif obj.cast_t == 0 then
        obj.cast = 0
    elseif obj.cast_t < 0 then
        obj.cast = 0
        obj.cast_t = 0
    end
    self.walkSystem:update(dt)
end

function M:render()
    self.walkSystem:render()
end

function M:getCurrentState()
    return self.walkSystem:getCurrentState()
end

function M:setState(stateName)
    self.walkSystem:setState(stateName)
    return self
end

function M.New(obj, texture)
    local instance = setmetatable({}, M)
    instance:init(obj, texture)
    return instance
end

return M
