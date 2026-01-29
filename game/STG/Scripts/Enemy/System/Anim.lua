local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.Anim : STG.Enemy.System.SystemBase
local M = Core.Class(base)
STG.Enemy.System.Anim = M

function M:init(enemy, system)
    base.init(self, enemy, system)
    self.timer = 0
    self.texture = nil
    self._a, self._r, self._g, self._b = 255, 255, 255, 255
    self._blend = ""
    self.hit_effect_time = 0
    self.hit_effect_time_max = 5
    self.style_name = ""
    ---@type STG.Animator[]
    self.animators = {}
end

function M:update(dt)
    self.timer = self.timer + dt
    local a, r, g, b = self._a, self._r, self._g, self._b
    if self.hit_effect_time > 0 then
        self.hit_effect_time = max(self.hit_effect_time - dt, 0)
        local ratio = self.hit_effect_time_max > 0 and (self.hit_effect_time / self.hit_effect_time_max) or 0
        r = r - r * ratio
        g = g - g * ratio
    end
    for _, ani in ipairs(self.animators) do
        ani:setBlend(ani._alternateBlendMode or self._blend)
        local color = ani._alternateColor
        local ca, cr, cg, cb = 1, 1, 1, 1
        if color then
            ca, cr, cg, cb = color[1] / 255, color[2] / 255, color[3] / 255, color[4] / 255
        end
        ani:setColor(a * ca, r * cr, g * cg, b * cb)
        ani:frame()
    end
end
function M:setMaxHitEffectTime(t)
    self.hit_effect_time_max = t
    return self
end
function M:onDamage()
    self.hit_effect_time = self.hit_effect_time_max
end

function M:render()
    for _, ani in ipairs(self.animators) do
        ani:render()
    end
end

---@param profile STG.Enemy.Profiles.Default
function M:setProfile(profile)
    self.style_name = profile.style_name
    local data = STG.Enemy.Resource.Get(self.style_name)
    for _, entry in ipairs(data.animators) do
        local ani = STG.Animator.New(self.enemy)
        if entry.color ~= Core.Render.Color.Default then
            ani._alternateColor = { entry.color:ARGB() }
        end
        if entry.blend ~= Core.Render.BlendMode.Default then
            ani._alternateBlendMode = entry.blend
        end

        entry.creator(ani)
        --ani:setScale(profile.size)

        table.insert(self.animators, ani)
    end
    return self
end