local base = STG.Player.ComponentBase

---@class STG.Player.System.Phase:STG.Player.ComponentBase
local M = Core.Class(base)
STG.Player.System.Phase = M

---@class STG.Player.System.Phase.Context
---@field system STG.Player.System.Phase
---@field stun_time number

function M:init(player, system)
    base.init(self, player, system)

    self.phase_timer = 0
    self.timer = 0

    self.sm = Core.Lib.StateMachine.New()
    self.sm:registerState("normal")
    self.sm:registerState("stun")
    self.sm:registerState("dead")
    self.sm:setContext("system", self)


    self.sm:setState("normal")
    self.sm:setOnStateChanged(function(from, to)
        self.phase_timer = 0
        if system.onPhaseChanged then
            system:onPhaseChanged(from, to)
        end
    end)
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

function M:setContext(key, value)
    self.sm:setContext(key, value)
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
    for _, v in ipairs(profile.new_phases or {}) do
        self:addPhase(v.toPhase, v.fromPhase, v.condition)
    end
end
function M:onDeath()
    self:set("dead")
end