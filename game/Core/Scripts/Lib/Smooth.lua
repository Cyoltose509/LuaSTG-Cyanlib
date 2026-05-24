---@class Core.Lib.Smooth
local M = {}
Core.Lib.Smooth = M

local exp = math.exp
local max = math.max

---@class Core.Lib.Smooth.Smoother
---@field value number
---@field velocity number
---@field update fun(self: Core.Lib.Smooth.Smoother, target: number, dt: number): number

---First Order
---一阶惯性（指数平滑）
---@param speed number
---@return Core.Lib.Smooth.Smoother
function M.FirstOrder(speed)
    speed = max(speed or 1, 0.0001)
    return {
        value = 0,
        update = function(self, target, dt)
            local k = 1 - exp(-speed * dt)
            self.value = self.value + (target - self.value) * k
            return self.value
        end
    }
end

---Second Order
---二阶系统
---@param wn number
---@param zeta number
---@return Core.Lib.Smooth.Smoother
function M.SecondOrder(wn, zeta)
    wn = max(wn or 8, 0.0001)
    zeta = zeta or 1
    return {
        value = 0,
        velocity = 0,

        update = function(self, target, dt)
            local accel =
            wn * wn * (target - self.value) - 2 * zeta * wn * self.velocity

            -- semi-implicit euler
            self.velocity = self.velocity + accel * dt
            self.value = self.value + self.velocity * dt

            return self.value
        end
    }
end


---Spring
---二阶系统语义糖
---@param smoothTime number
---@param damping number|nil
---@return table
function M.Spring(smoothTime, damping)
    smoothTime = max(smoothTime or 0.25, 0.0001)
    damping = damping or 1

    local wn = 2 / smoothTime
    return M.SecondOrder(wn, damping)
end

---Oscillator
---振荡器
---@param frequency number
---@param damping number|nil
---@return table
function M.Oscillator(frequency, damping)
    frequency = max(frequency or 10, 0.0001)
    damping = damping or 0.3

    return M.SecondOrder(frequency, damping)
end