local base = STG.Player.System.SystemBase

---@class STG.Player.System.Health :STG.Player.System.SystemBase
local M = Core.Class(base)
STG.Player.System.Health = M

---@class STG.Player.System.Health.Container
local container = Core.Class()
function container:init(full)
    self.capacity = 10
    self.current = full and self.capacity or 0
    self.once = false
    self.prior = 1
    self.tag = "normal"
    self.trashed = false
    self.hurt_eff = 0
    self.hurt_eff_dt = 0.5
    self:setDrawInfo()
end
function container:setDrawInfo(hue)
    self.hue = hue or 0
    self.trash_wait = 1
    self.time_since_trash = 0
end
function container:add(h)
    if self.current + h <= self.capacity then
        self.current = self.current + h
        return 0
    else
        local overflow = self.current + h - self.capacity
        self.current = self.capacity
        return overflow
    end
end
function container:update(dt)
    self.hurt_eff = max(0, self.hurt_eff - dt / self.hurt_eff_dt)
end
function container:remove(h)
    self.hurt_eff = 1
    if self.current - h >= 0 then
        self.current = self.current - h
        return 0
    else
        local overflow = h - self.current
        self.current = 0
        return overflow
    end
end
function container:get()
    return self.current
end
function container:broke()


end

---@class STG.Player.System.Health.Shield : STG.Player.System.Health.Container
local shield = Core.Class(container)
function shield:init(full)
    container.init(self, full)
    self.once = true
    self.prior = 2
    self.tag = "shield"
    self:setDrawInfo(180)
end

M.Container = {
    Normal = container,
    Shield = shield,
}

function M:init(player, system)
    base.init(self, player, system)
    self.max_container = 10
    ---@type STG.Player.System.Health.Container[]
    self.containers = {}
    ---@type STG.Player.System.Health.ViewData[]
    self.view_data = {}
    self.trashed = {}
    self.invincible_timer = 0
    self.invincible = false
    self.invincible_default = 0.5
end

function M:update(dt)
    for i = #self.containers, 1, -1 do
        local ctn = self.containers[i]
        ctn:update(dt)
        if ctn.trashed then
            ctn.time_since_trash = ctn.time_since_trash + dt
            if ctn.time_since_trash >= ctn.trash_wait then
                table.remove(self.containers, i)
            end
        end
    end
    if self.invincible then
        self.invincible_timer = self.invincible_timer - dt
        if self.invincible_timer <= 0 then
            self.invincible = false
        end
    end
    self:viewUpdate(dt)
end
function M:viewUpdate(dt)
    local vd = self.view_data
    for i = #vd + 1, #self.containers do
        ---@class STG.Player.System.Health.ViewData
        vd[i] = {
            x = -20,
            y = 0,
            alpha = 0,
            fill = 0,
        }
    end
    for i, ctn in ipairs(self.containers) do
        ---@type STG.Player.System.Health.ViewData
        local v = vd[i]
        v.id = i
        v.tag = ctn.tag
        v.current = ctn.current
        v.capacity = ctn.capacity
        v.fill = Core.Math.ExpInterp(v.fill, ctn.current / ctn.capacity, dt * 6)
        v.hue = ctn.hue
        v.hurt_eff = ctn.hurt_eff
        v.x = Core.Math.ExpInterp(v.x, 0, dt * 10)
        v.trashing = min(1, ctn.time_since_trash / ctn.trash_wait)
    end
    -- 截断
    for i = #self.containers + 1, #vd do
        vd[i] = nil
    end
end
function M:getViewData()
    return self.view_data
end
function M:death()
    --  self.system.sm:setState("dead")
end

---添加一个容器
---@param type STG.Player.System.Health.Container
---@param full boolean 是否满
---@param bottom boolean 是否在底部
---@return STG.Player.System.Health.Container
function M:addContainer(type, full, bottom)
    if #self.containers >= self.max_container then
        return nil
    end
    local ctn = type(full)
    if bottom then
        table.insert(self.containers, 1, ctn)
    else
        table.insert(self.containers, ctn)
    end
    return ctn
end

---移除一个容器
---@param tag string 容器的标签
function M:removeContainer(tag)
    tag = tag or "normal"
    for _, ctn in ipairs(self.containers) do
        if ctn.tag == tag then
            ctn.trashed = true
            return
        end
    end
end
---@return STG.Player.System.Health.Container
function M:getDamageTarget(tag)
    local best
    local best_prior = -math.huge
    for i = #self.containers, 1, -1 do
        local ctn = self.containers[i]
        if not tag or ctn.tag == tag then
            if not ctn.trashed and ctn.prior > best_prior and ctn.current > 0 then
                best = ctn
                best_prior = ctn.prior
            end
        end
    end
    return best
end

function M:damage(count)
    if count <= 0 then
        return
    end
    local ctn = self:getDamageTarget()
    if not ctn then
        self:death()
        return
    end
    local overflow = ctn:remove(count)
    if ctn:get() == 0 and ctn.once then
        ctn.trashed = true
    end
    if overflow > 0 then
        self:damage(overflow)
    end
    return ctn
end

function M:isAlive()
    return self:getDamageTarget() and true or false
end

function M:isInvincible()
    return self.invincible
end
function M:setInvincible(time)
    self.invincible = true
    self.invincible_timer = max(self.invincible_timer, time or 0.5)
end

---@param profile STG.Player.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    if profile.health then
        self.invincible_default = profile.health.invincible_time or self.invincible_default
        self.max_container = profile.health.max_containers or self.max_container
        for _, ctn_type in ipairs(profile.health.init_containers or {}) do
            self:addContainer(ctn_type, true)
        end
    end
end

