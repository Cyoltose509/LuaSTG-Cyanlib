local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.DamageModifier : STG.Enemy.System.SystemBase
---@field Armor STG.Enemy.System.DamageModifier.Armor
---@field Percent STG.Enemy.System.DamageModifier.Percent
---@field Shield STG.Enemy.System.DamageModifier.Shield
---@field Default STG.Enemy.System.DamageModifier.Default
local M = Core.Class(base)
STG.Enemy.System.DamageModifier = M

function M:init(enemy, system)
    base.init(self, enemy, system)
    ---@type STG.Enemy.System.DamageModifier.Base[]
    self.modifiers = {}
    self._is_dirty = false
end

--- 添加一个 modifier
function M:add(mod)
    table.insert(self.modifiers, mod)
    mod.master = self
    self._is_dirty = true
end
--- 移除 modifier
function M:remove(mod)
    mod.is_trashed = true
end

--- 应用所有 modifier
function M:apply(damage)
    if self._is_dirty then
        ---这里是降序排序是因为后面应用时是倒序，所以本质上还是升序应用
        table.sort(self.modifiers, function(a, b)
            return a.level > b.level
        end)
        self._is_dirty = false
    end
    local value = damage
    for i = #self.modifiers, 1, -1 do
        local m = self.modifiers[i]
        if m.is_trashed then
            table.remove(self.modifiers, i)
        elseif m:isEnabled() then
            value = m:apply(value)
            if value <= 0 then
                return 0
            end
        end
    end
    return value
end

---@param profile STG.Enemy.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.damage_modifier then
        for level, modc in ipairs(profile.damage_modifier) do
            local mod = modc(self.enemy, self.system)
            mod:setLevel(level)
            self:add(mod)
        end
    end
end

---@class STG.Enemy.System.DamageModifier.Base
local Base = Core.Class()
M.Base = Base

---@param enemy STG.Enemy.Base
---@param system STG.Enemy.System
function Base:init(enemy, system)
    self.enemy = enemy
    self.system = system
    self.level = 0
    self.enabled = true
    self.master = nil
    self.is_trashed = false
end

function Base:setLevel(l)
    self.level = l
    if self.master then
        self.master._is_dirty = true
    end
end

--- 对伤害进行修正
---@param damage number
function Base:apply(damage)
    return damage
end

function Base:isEnabled()
    return self.enabled
end

function Base:setEnabled(v)
    self.enabled = v
end

function Base:remove()
    self.is_trashed = true
end

require("STG.Scripts.Enemy.System.DamageModifier.Armor")
require("STG.Scripts.Enemy.System.DamageModifier.Percent")
require("STG.Scripts.Enemy.System.DamageModifier.Shield")
require("STG.Scripts.Enemy.System.DamageModifier.Default")



