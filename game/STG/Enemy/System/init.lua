---@class STG.Enemy.System
---@field Health STG.Enemy.System.Health
---@field Anim STG.Enemy.System.Anim
---@field SystemBase STG.Enemy.System.SystemBase
---@field Death STG.Enemy.System.Death
---@field Collide STG.Enemy.System.Collide
---@field DamageModifier STG.Enemy.System.DamageModifier
---@field Phase STG.Enemy.System.Phase
local M = Core.Class()
STG.Enemy.System = M

local Object = STG.Object

require("STG.Enemy.System.SystemBase")
require("STG.Enemy.System.Anim")
require("STG.Enemy.System.Health")
require("STG.Enemy.System.Death")
require("STG.Enemy.System.Collide")
require("STG.Enemy.System.DamageModifier")
require("STG.Enemy.System.Phase")
require("STG.Enemy.System.Move")
require("STG.Enemy.System.Shoot")

function M:init(enemy)
    self.enemy = enemy
    self.timer = 0
    self.color_index = 1
    ---@type STG.Enemy.ComponentBase[]
    self.components = {}
    self.health_system = M.Health(enemy, self)
    self.anim_system = M.Anim(enemy, self)
    self.death_system = M.Death(enemy, self)
    self.collide_system = M.Collide(enemy, self)
    self.damage_modifier_system = M.DamageModifier(enemy, self)
    self.phase_system = M.Phase(enemy, self)
    self.move_system = M.Move(enemy, self)
    self.shoot_system = M.Shoot(enemy, self)
    self.view_data = {
        health = self.health_system:getViewData(),
    }
end

function M:update(dt)
    self.timer = self.timer + dt
    self.phase_system:update(dt)
    self.anim_system:update(dt)
    self.health_system:update(dt)
    self.collide_system:update(dt)
    self.move_system:update(dt)
    self.shoot_system:update(dt)

    for _, comp in pairs(self.components) do
        comp:update()
    end
end

function M:render()
    self.anim_system:render()
    for _, comp in pairs(self.components) do
        comp:render()
    end
end

function M:getViewData()
    return self.view_data
end

---应用角色配置文件到系统/玩家
---@param profile STG.Enemy.Profiles.Default
function M:applyProfile(profile)
    profile = profile or STG.Enemy.Profiles.Default
    profile.style_name = profile.style_name or ""
    profile.size = profile.size or 1

    if profile.not_collide then
        self.enemy.group = Object.Group.NotCollide
    end


    --self.hit_system:setProfile(profile)

    local style_data = STG.Enemy.Resource.Get(profile.style_name)
    local collide_r = style_data.collide_r
    self.color_index = style_data.color_index or 1
    self.anim_system:setProfile(profile)
    self:setCollisionSize(profile.size * collide_r)
    self:setScaling(profile.size)

    self.death_system:setProfile(profile)
    self.collide_system:setProfile(profile)
    self.damage_modifier_system:setProfile(profile)
    self.phase_system:setProfile(profile)
    if profile.default_damage_modifier ~= false then
        self.damage_modifier_system:add(M.DamageModifier.Default(self.enemy, self))
    end
    self.health_system:setProfile(profile)
end

---@param field string
---@param base STG.Enemy.System.SystemBase
function M:resetSystem(field, base)
    assert(field:find("_system"), "field must refer to a system")
    self[field] = base(self.enemy, self)
end

---@param variant STG.Enemy.Variant
function M:applyVariant(variant)
    if not variant then
        return
    end
    for k, v in pairs(variant.replace_subsystem or {}) do
        self:resetSystem(k, v)
    end
    for k, v in pairs(variant.components or {}) do
        self:addComponent(k, v)
    end
    self:applyProfile(variant.profiles)
end

---@class STG.Enemy.System.DamageInfo
---@field amount number
---@field bypass_invincible boolean    是否忽略无敌
---@field invincible_time number  覆盖默认无敌时间
---@field source any       来源（子弹/区域/状态）
---@field type string     "hit" | "dot"

---@class STG.Enemy.System.HitInfo
---@field power number
---@field time number
---@field angle number
---@field source any
---@field interrupt boolean

---@param info STG.Enemy.System.DamageInfo
function M:takeDamage(info)
    info = info or {}
    if info.amount <= 0 then
        return false
    end
    if not info.bypass_invincible then
        if self.health_system:isInvincible() then
            return false
        end
    end
    local amount = self.damage_modifier_system:apply(info.amount)

    self.health_system:damage(amount)
    self.anim_system:onDamage(info)
    for _, comp in pairs(self.components) do
        comp:onDamage(info)
    end
    if info.invincible_time then
        self.health_system:setInvincible(info.invincible_time)
    end
end


function M:onDeath()
    for _, comp in pairs(self.components) do
        comp:onDeath()
    end
    self.death_system:onDeath()
    self.phase_system:onDeath()
    Object.Del(self.enemy)
end

function M:setCollisionSize(a, b)
    local p = self.enemy
    p.a = a or 1
    p.b = b or p.a
    return self
end

function M:setScaling(h, v)
    local p = self.enemy
    p.hscale = h or 1
    p.vscale = v or p.hscale
    return self
end


function M:getPhase()
    return self.phase_system:get()
end

function M:getEnterPhaseRatio()
    return self.phase_system:getEnterRatio()
end

function M:addComponent(name, comp)
    if not name or not comp then
        return
    end
    self.components[name] = comp(self.enemy, self)
    return comp
end

function M:removeComponent(name)
    local c = self.components[name]
    if c then
        c:onRemove()
    end
    self.components[name] = nil
    return c
end

function M:getComponent(name)
    return self.components[name]
end

function M:onPhaseChanged(from, to)
    for _, comp in pairs(self.components) do
        comp:onPhaseChanged(from, to)
    end
end

-- ========================================
-- 便捷移动方法 (使用 Core.Task + move_system 实现缓动)
-- ========================================

---相对移动：从当前位置向 (dx, dy) 偏移，duration 帧内完成
---@param dx number   x 方向偏移量
---@param dy number   y 方向偏移量
---@param duration number  动画帧数
---@param easing number?   缓动类型 (Core.Lib.Easing.xxx)，默认线性
function M:requestMoveBy(dx, dy, duration, easing)
    local e     = self.enemy
    local start_x = e.x
    local start_y = e.y
    local end_x   = start_x + dx
    local end_y   = start_y + dy
    self:_moveOverTime(start_x, start_y, end_x, end_y, duration, easing)
end

---绝对移动：移动到 (x, y)，duration 帧内完成
---@param x number   目标 x
---@param y number   目标 y
---@param duration number  动画帧数
---@param easing number?   缓动类型，默认线性
function M:requestMoveTo(x, y, duration, easing)
    local e     = self.enemy
    local start_x = e.x
    local start_y = e.y
    self:_moveOverTime(start_x, start_y, x, y, duration, easing)
end

---内部：使用 Core.Task 逐帧插值移动
---@param sx number
---@param sy number
---@param tx number
---@param ty number
---@param duration number
---@param easing number?
function M:_moveOverTime(sx, sy, tx, ty, duration, easing)
    local e = self.enemy
    -- 暂停当前 move_system 的自动移动
    self.move_system:stop()

    Core.Task.New(e, function()
        local elapsed = 0
        while elapsed < duration do
            elapsed = elapsed + 1
            local t = elapsed / duration
            -- 使用 lstg 引擎的缓动函数
            if easing and easing ~= 0 then
                t = Core.Lib.Easing(easing, t)
            end
            e.x = sx + (tx - sx) * t
            e.y = sy + (ty - sy) * t
            Core.Task.Wait(1)
        end
        e.x = tx
        e.y = ty
    end)
end
