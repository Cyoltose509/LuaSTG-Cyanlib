local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.Health : STG.Enemy.System.SystemBase
local M = Core.Class(base)
STG.Enemy.System.Health = M


--TODO
function M:init(enemy, system)
    base.init(self, enemy, system)
    self.max_hp = 30
    self.hp = self.max_hp
    self.invincible = false
    self.invincible_timer = 0
    self.view_data = {
        max_hp = self.max_hp,
        hp = self.hp,
        show_hp = self.hp,
        open = false,
        show_timer = 999,
        show = 0,
    }
end

function M:update(dt)
    if self.invincible then
        self.invincible_timer = self.invincible_timer - dt
        if self.invincible_timer <= 0 then
            self.invincible = false
        end
    end
    if self.hp <= 0 then
        self.hp = 0
        if self.system then
            self.system:onDeath()
        end
    end
    local vd = self.view_data
--[[
    if vd.open then
        vd.show_hp = Core.Math.ExpInterp(vd.show_hp, self.hp, 0.1)
        vd.hp = self.hp
        vd.max_hp = self.max_hp
        vd.show_timer = vd.show_timer + dt
        if vd.show_timer < 0.5 then
            vd.show = Core.Lib.Easing.QuartOut(vd.show_timer / 0.5)
        elseif vd.show_timer < 3 then
            vd.show = 1
        else
            vd.show = max(0, 1 - Core.Lib.Easing.QuartIn((vd.show_timer - 3) / 0.5))
            if vd.show == 0 then
                vd.open = false
            end
        end
    end--]]
end

function M:damage(count)
    if self.invincible or count <= 0 then
        return
    end
    self.hp = self.hp - count
    --[[
    local vd=self.view_data
    if not vd.open then
        vd.show_timer = 0
        vd.open = true
    else
        vd.show_timer = min(vd.show_timer, 0.5)
    end--]]



end

function M:heal(amount)
    if amount <= 0 then
        return
    end
    self.hp = min(self.max_hp, self.hp + amount)
end

function M:setInvincible(time)
    self.invincible = true
    self.invincible_timer = max(self.invincible_timer, time or 0.5)
end

function M:isInvincible()
    return self.invincible
end

---@param profile STG.Enemy.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    self.hp = profile.hp or self.hp
    self.max_hp = self.hp
end

function M:getViewData()
    return self.view_data
end

