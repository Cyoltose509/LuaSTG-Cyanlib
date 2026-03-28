---@class Core.Menu.Base
local M = Core.Class()
Core.Menu.Base = M

local Smooth = Core.Math.ExpInterp

function M:update(dt)
end
function M:updateClosing(dt, alpha_decay)
    self.alpha = self.alpha or 1
    if self.is_closing then
        self.alpha = max(self.alpha - dt * (alpha_decay or 5), 0)
        self.locked = true
        if self.alpha == 0 then
            Core.Menu.Pop()
        end
    else
        self.alpha = Smooth(self.alpha, 1, dt * 8)
    end
end
function M:close()
    self.is_closing = true
end
function M:release()

end
function M:updateInput(mx, my)

end
function M:render()

end
function M:isKilled()
    return self.is_closing
end