---@class STG.Player.System
---@field Input STG.Player.System.Input
---@field Move STG.Player.System.Move
---@field Anim STG.Player.System.Anim
---@field Effect STG.Player.System.Effect
---@field Health STG.Player.System.Health
---@field Hit STG.Player.System.Hit
---@field Shoot STG.Player.System.Shoot
---@field Phase STG.Player.System.Phase
---@field SystemBase STG.Player.System.SystemBase
---@field Death STG.Player.System.Death
---玩家系统的基类
---如果以此系统只想改动子系统，可以通过 resetXXXSystem 替换子系统
---如果玩家系统逻辑与此有较大不同，可以继承此类重写
local M = Core.Class()
STG.Player.System = M

require("STG.Scripts.Player.System.SystemBase")
require("STG.Scripts.Player.System.Input")
require("STG.Scripts.Player.System.Health")
require("STG.Scripts.Player.System.Effect")
require("STG.Scripts.Player.System.Anim")
require("STG.Scripts.Player.System.Move")
require("STG.Scripts.Player.System.Hit")
require("STG.Scripts.Player.System.Shoot")
require("STG.Scripts.Player.System.Phase")
require("STG.Scripts.Player.System.Death")
require("STG.Scripts.Player.Profiles")

---@param player STG.Player.Base
function M:init(player)
    self.player = player
    self.timer = 0
    ---@type STG.Player.ComponentBase[]
    self.components = {}
    self.input_system = M.Input(player, self)
    self.move_system = M.Move(player, self)
    self.anim_system = M.Anim(player, self)
    self.effect_system = M.Effect(player, self)
    self.health_system = M.Health(player, self)
    self.hit_system = M.Hit(player, self)
    self.shoot_system = M.Shoot(player, self)
    self.phase_system = M.Phase(player, self)
    self.death_system = M.Death(player, self)

    self.stun_time = 0
    self.view_data = {
        move = self.move_system:getViewData(),
        anim = self.anim_system:getViewData(),
        effect = self.effect_system:getViewData(),
        hit = self.hit_system:getViewData(),
        health = self.health_system:getViewData(),
        shoot = self.shoot_system:getViewData(),
        colR = self.colR,
        colG = self.colG,
        colB = self.colB,
    }
end
function M:update(dt)
    self.timer = self.timer + dt
    self.input_system:update(dt)
    self.death_system:update(dt)
    self.phase_system:update(dt)
    self.move_system:update(dt)
    self.shoot_system:update(dt)
    self.hit_system:update(dt)
    self.health_system:update(dt)
    self.anim_system:update(dt)
    self.effect_system:update(dt)
    for _, comp in pairs(self.components) do
        comp:render()
    end
end
function M:render()
    self.effect_system:render()
    self.anim_system:render()
    for _, comp in pairs(self.components) do
        comp:render()
    end
end

function M:getInput()
    return self.input_system
end

---应用角色配置文件到系统/玩家
---@param profile STG.Player.Profiles.Default
function M:applyProfile(profile)
    profile = profile or STG.Player.Profiles.Default
    self.colR = profile.color[1] or 189
    self.colG = profile.color[2] or 252
    self.colB = profile.color[3] or 201
    self:setSize(profile.size)
    self.move_system:setProfile(profile)
    self.anim_system:setProfile(profile)
    self.effect_system:setProfile(profile)
    self.health_system:setProfile(profile)
    self.hit_system:setProfile(profile)
    self.shoot_system:setProfile(profile)
    self.phase_system:setProfile(profile)
end

---@param field string
---@param base STG.Player.System.SystemBase
function M:resetSystem(field, base)
    assert(field:find("_system"), "field must refer to a system")
    self[field] = base(self.player, self)
end

function M:getViewData()
    self.view_data.colR = self.colR
    self.view_data.colG = self.colG
    self.view_data.colB = self.colB
    return self.view_data
end

function M:getMoveSpeed()
    local dt = Core.Time.Delta
    local vec = self.move_system:getVector()
    return hypot(vec.x, vec.y) / dt
end
function M:getMoveVec()
    return self.move_system:getVector()
end

function M:isInvincible()
    return self.health_system:isInvincible()
end

function M:getPhase()
    return self.phase_system:get()
end

function M:setPhase(phase)
    self.phase_system:set(phase)
end

function M:setStun(time)
    self.phase_system:setContext("stun_time", time or 0.5)
    self.phase_system:set("stun")
end



---@class STG.Player.System.DamageInfo
---@field amount number
---@field bypass_invincible boolean    是否忽略无敌
---@field invincible_time number  覆盖默认无敌时间
---@field source any       来源（子弹/区域/状态)
---@field type string     "hit" | "dot"

---@class STG.Player.System.onDamageInfo
---@field type string
---@field container STG.Player.System.Health.Container
---@field detail STG.Player.System.DamageInfo

---@param info STG.Player.System.DamageInfo
---@param hit STG.Player.System.HitInfo
function M:damage(info, hit)
    if info.amount <= 0 then
        return false
    end
    if not info.bypass_invincible then
        if self.health_system:isInvincible() then
            return false
        end
    end
    local container = self.health_system:damage(info.amount)
    if self.health_system:isAlive() then
        if container then

            if hit then
                self:hit(hit)
            end
            local on_dmg_info = {
                type = info.type or "hit",
                container = container,
                detail = info,
            }
            self.move_system:onDamage(on_dmg_info)
            self.anim_system:onDamage(on_dmg_info)
            self.effect_system:onDamage(on_dmg_info)
            self.health_system:onDamage(on_dmg_info)
            self.hit_system:onDamage(on_dmg_info)
            self.shoot_system:onDamage(on_dmg_info)
            for _, comp in pairs(self.components) do
                comp:onDamage(on_dmg_info)
            end
            if not info.bypass_invincible then
                local inv_t = info.invincible_time or self.health_system.invincible_default
                if self.health_system then
                    self.health_system:setInvincible(inv_t)
                end
            end
            return true
        end
    else
        self:onDeath()

    end
end

function M:onDeath()
    --TODO:??
    self:setPhase("dead")
    self.player.colli = false
    self.death_system:onDeath()
    self.move_system:onDeath()
    self.anim_system:onDeath()
    self.effect_system:onDeath()
    self.health_system:onDeath()
    self.hit_system:onDeath()
    self.shoot_system:onDeath()

    for _, comp in pairs(self.components) do
        comp:onDeath()
    end
end

---@class STG.Player.System.HitInfo
---@field power number
---@field time number
---@field angle number
---@field source any
---@field interrupt boolean

---@param info STG.Player.System.HitInfo
function M:hit(info)
    info.time = info.time or 0.3
    if info.interrupt ~= false and self:getPhase() ~= "stun" then
        self:setStun(info.time)
    end
    if self.hit_system then
        self.hit_system:apply(info)
    end
end

function M:setSize(r)
    local p = self.player
    p.r = r or 1
    p.a = p.r
    p.b = p.r
end

function M:addComponent(name, comp)
    if not name or not comp then
        return
    end
    self.components[name] = comp(self.player, self)
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
    self.move_system:onPhaseChanged(from, to)
    self.anim_system:onPhaseChanged(from, to)
    self.effect_system:onPhaseChanged(from, to)
    self.health_system:onPhaseChanged(from, to)
    self.hit_system:onPhaseChanged(from, to)
    self.shoot_system:onPhaseChanged(from, to)
    for _, comp in pairs(self.components) do
        comp:onPhaseChanged(from, to)
    end
end


