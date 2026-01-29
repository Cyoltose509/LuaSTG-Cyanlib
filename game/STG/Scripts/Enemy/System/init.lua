---@class STG.Enemy.System
---@field Health STG.Enemy.System.Health
---@field Anim STG.Enemy.System.Anim
---@field SystemBase STG.Enemy.System.SystemBase
---@field Death STG.Enemy.System.Death
---@field Collide STG.Enemy.System.Collide
---@field DamageModifier STG.Enemy.System.DamageModifier
---@field Move STG.Enemy.System.Move
---@field Phase STG.Enemy.System.Phase
local M = Core.Class()
STG.Enemy.System = M

local Object = STG.Object

require("STG.Scripts.Enemy.System.SystemBase")
require("STG.Scripts.Enemy.System.Anim")
require("STG.Scripts.Enemy.System.Health")
require("STG.Scripts.Enemy.System.Death")
require("STG.Scripts.Enemy.System.Collide")
require("STG.Scripts.Enemy.System.DamageModifier")
require("STG.Scripts.Enemy.System.Move")
require("STG.Scripts.Enemy.System.Phase")

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
    self.move_system = M.Move(enemy, self)
    self.phase_system = M.Phase(enemy, self)
    self.view_data = {
        health = self.health_system:getViewData(),
    }
end

function M:update(dt)
    self.timer = self.timer + dt
    self.phase_system:update(dt)
    self.move_system:update(dt)
    self.anim_system:update(dt)
    self.health_system:update(dt)
    self.collide_system:update(dt)

    --self.hit_system:update(dt)
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
    self.move_system:setProfile(profile)
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
---@param hit STG.Enemy.System.HitInfo
function M:takeDamage(info, hit)
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

    if hit then
        self:hit(hit)
    end
    self.health_system:damage(amount)
    self.anim_system:onDamage(info)
    for _, comp in pairs(self.components) do
        comp:onDamage(info)
    end
    if info.invincible_time then
        self.health_system:setInvincible(info.invincible_time)
    end
end

---@param info STG.Enemy.System.HitInfo
function M:hit(info)
    info = info or {}
    info.time = info.time or 0.2
    self.move_system:knockback(info.angle, info.power, info.time)
    --self.hit_system:apply(info)
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

function M:requestMoveTo(x, y, time, mode)
    self.move_system:moveTo(x, y, time, mode)
end
function M:requestMoveBy(dx, dy, time, mode)
    local e = self.enemy
    local x, y = e.x, e.y
    self.move_system:moveTo(x + dx, y + dy, time, mode)
end

function M:requestMoveDir(x, y, time)
    self.move_system:moveWithDir(x, y, time)
end

function M:applyImpulse(vx, vy, time)
    self.move_system:impulse(vx, vy, time)
end

function M:requestMoveStop()
    self.move_system:stop()
end

function M:enableMove(v)
    self.move_system:enableMove(v)
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
