---@class Core.Lib.ComponentBase
local M = Core.Class()
Core.Lib.ComponentBase = M

function M:setEnable(flag)
    self.enabled = flag
end
function M:isEnabled()
    return self.enabled
end

function M:setName(name)
    self._name = name
end
function M:getName()
    return self._name
end
function M:onDestroy()

end
