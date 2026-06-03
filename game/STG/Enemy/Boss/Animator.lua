---@class STG.Enemy.Boss.Animator : STG.Animator
local M = Core.Class(STG.Animator)
STG.Enemy.Boss.Animator = M

function M:init(obj, texture)
    STG.Animator.init(self, obj, texture)
    self.shake_timer = 0
    self.shake_intensity = 0
    self.shake_duration = 0
    self.flash_timer = 0
    self.flash_duration = 0.1
    return self
end

---Trigger a shake effect on the boss sprite.
---@param duration number
---@param intensity number
function M:shake(duration, intensity)
    self.shake_timer = 0
    self.shake_duration = duration or 0.2
    self.shake_intensity = intensity or 3
end

---Trigger a white flash on the boss sprite.
function M:flashOnDamage()
    self.flash_timer = self.flash_duration
end

function M:update(dt)
    STG.Animator.update(self, dt)
    if self.shake_timer < self.shake_duration then
        self.shake_timer = self.shake_timer + dt
        local p = 1 - self.shake_timer / self.shake_duration
        local intensity = self.shake_intensity * p
        self.obj.dx = (math.random() - 0.5) * 2 * intensity
        self.obj.dy = (math.random() - 0.5) * 2 * intensity
    end
    if self.flash_timer > 0 then
        self.flash_timer = max(0, self.flash_timer - dt)
    end
end

function M:getColor()
    if self.flash_timer > 0 then
        local t = self.flash_timer / self.flash_duration
        return Core.Render.Color.ARGB(255, 255, 255, 255)
    end
    return self.color or Core.Render.Color.Default
end

return M
