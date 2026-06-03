---@class STG.Player.System
---@field Input STG.Player.System.Input
---@field Move STG.Player.System.Move
---@field Anim STG.Player.System.Anim
---@field Effect STG.Player.System.Effect
---@field Health STG.Player.System.Health
---@field Hit STG.Player.System.Hit
---@field Shoot STG.Player.System.Shoot
---@field Phase STG.Player.System.Phase
---@field Death STG.Player.System.Death
---@field Graze STG.Player.System.Graze
---@field Bomb STG.Player.System.Bomb
---@field Resource STG.Player.System.Resource
---玩家系统的基类
---如果以此系统只想改动子系统，可以通过 resetXXXSystem 替换子系统
---如果玩家系统逻辑与此有较大不同，可以继承此类重写
local M = Core.Class()
STG.Player.System = M

require("STG.Player.System.Input")
require("STG.Player.System.Health")
require("STG.Player.System.Effect")
require("STG.Player.System.Anim")
require("STG.Player.System.Move")
require("STG.Player.System.Hit")
require("STG.Player.System.Shoot")
require("STG.Player.System.Phase")
require("STG.Player.System.Death")
require("STG.Player.System.Graze")
require("STG.Player.System.Bomb")
require("STG.Player.System.Resource")
require("STG.Player.Profiles")

---@param player STG.Player.Base
function M:init(player)
    self.player = player
    self.timer = 0
    ---@class STG.Player.System.ComponentSystem:Core.Lib.ComponentSystem
    self.component_sys = Core.Lib.ComponentSystem(self)
                             :addComponent("Input", M.Input(player, self))
                             :addComponent("Anim", M.Anim(player, self))
                             :addComponent("Move", M.Move(player, self))
                             :addComponent("Graze", M.Graze(player, self))
                             :addComponent("Effect", M.Effect(player, self))
                             :addComponent("Resource", M.Resource(player, self))
                             :addComponent("Health", M.Health(player, self))
                             :addComponent("Hit", M.Hit(player, self))
                             :addComponent("Bomb", M.Bomb(player, self))
                             :addComponent("Shoot", M.Shoot(player, self))
                             :addComponent("Phase", M.Phase(player, self))
                             :addComponent("Death", M.Death(player, self))

    self.view_data = {}
end
function M:update(dt)
    self.timer = self.timer + dt
    self:requestComponentDo(function(comp)
        if comp.update then
            comp:update(dt)
        end
    end)
end
function M:render()
    self:requestComponentDo(function(comp)
        if comp.render then
            comp:render()
        end
    end)
end

---@param func fun(comp:STG.Player.ComponentBase)
function M:requestComponentDo(func)
    self.component_sys:requestDo(func)
end

---@return STG.Player.System.Input
function M:getInput()
    return self.component_sys:getComponent("Input")
end

function M:isSlow()
    return self:getInput().slow
end

---应用角色配置文件到系统/玩家
---@param profile STG.Player.Profiles.Default
function M:applyProfile(profile)
    profile = profile or STG.Player.Profiles.Default
    self.colR = profile.color[1] or 189
    self.colG = profile.color[2] or 252
    self.colB = profile.color[3] or 201
    self:setCollisionSize(profile.size)
    self:requestComponentDo(function(comp)
        if comp.setProfile then
            comp:setProfile(profile)
        end
    end)
end

function M:getViewData()
    local data = self.view_data
    data.colR = self.colR
    data.colG = self.colG
    data.colB = self.colB
    self:requestComponentDo(function(comp)
        if comp.getViewData then
            data[comp:getName()] = comp:getViewData()
        end
    end)
    return data
end

function M:isInvincible()
    local health = self.component_sys:getComponent("Health")
    if health and health:isInvincible() then return true end
    local death = self.component_sys:getComponent("Death")
    if death and death:isDying() then return true end
    return false
end

function M:getPhase()
    ---@type STG.Player.System.Phase
    local phase_comp = self.component_sys:getComponent("Phase")
    return phase_comp:get()
end

function M:setPhase(phase)
    ---@type STG.Player.System.Phase
    local phase_comp = self.component_sys:getComponent("Phase")
    phase_comp:set(phase)
    return self
end

function M:damage(amount)
    local health = self.component_sys:getComponent("Health")
    if health then
        health:damage(amount or 1)
    end
end

function M:hitByEnemyBullet(bullet)
    if self:isInvincible() then return end
    self:damage(1)
    -- Trigger flash effect only (no knockback displacement)
    local hit = self.component_sys:getComponent("Hit")
    if hit then hit:apply() end
end

function M:hitByEnemy(enemy)
    if self:isInvincible() then return end
    self:damage(1)
    local hit = self.component_sys:getComponent("Hit")
    if hit then hit:apply() end
end

function M:onDeath()
    self:requestComponentDo(function(comp)
        if comp.onDeath then
            comp:onDeath()
        end
    end)
end
function M:setCollisionSize(r)
    local p = self.player
    p.r = r or 1
    p.a = p.r
    p.b = p.r
end

function M:onPhaseChanged(from, to)
    self:requestComponentDo(function(comp)
        if comp.onPhaseChanged then
            comp:onPhaseChanged(from, to)
        end
    end)
end


