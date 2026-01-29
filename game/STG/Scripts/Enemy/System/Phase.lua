local base = STG.Enemy.System.SystemBase

---@class STG.Enemy.System.Phase:STG.Enemy.System.SystemBase
local M = Core.Class(base)
STG.Enemy.System.Phase = M

---@class STG.Enemy.System.Phase.Context
---@field system STG.Enemy.System.Phase

function M:init(enemy, system)
    base.init(self, enemy, system)

    self.enter_time = 0.5

    self.phase_timer = 0
    self.timer = 0

    self.sm = Core.Lib.StateMachine.New()
    self.sm:registerState("enter")
    self.sm:registerState("alive")
    self.sm:registerState("dead")
    self.sm:setContext("system", self)
    self.sm:addTransition("enter", "alive", function()
        return self.phase_timer >= self.enter_time
    end)

    self.sm:setOnStateChanged(function(from, to)
        self.phase_timer = 0
        if system.onPhaseChanged then
            system:onPhaseChanged(from, to)
        end
    end)

    self.sm:setState("enter")
end

function M:update(dt)
    self.phase_timer = self.phase_timer + dt
    self.timer = self.timer + dt
    self.sm:update(dt)
end

function M:get()
    return self.sm:getCurrentStateName(), self.phase_timer
end

function M:set(phase)
    self.sm:setState(phase)
end

function M:getEnterRatio()
    if self:get() ~= "enter" then
        return 1
    end
    if self.enter_time <= 0 then
        return 1
    end
    return min(self.phase_timer / self.enter_time, 1)
end

function M:addPhase(name, fromState, condition)
    if not self.sm:hasState(name) then
        self.sm:registerState(name)
    end
    if fromState and condition then
        self.sm:addTransition(fromState, name, condition)
    end
end
---@param profile STG.Enemy.Profiles.Default
function M:setProfile(profile)
    if not profile then
        return
    end
    self.enter_time = profile.enter_time or self.enter_time
    for _, v in ipairs(profile.new_phases or {}) do
        self:addPhase(v.toPhase, v.fromPhase, v.condition)
    end
end
function M:onDeath()
    self:set("dead")
end