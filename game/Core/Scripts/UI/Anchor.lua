---@class Core.UI.Anchor : Core.UI.Child
local M = Core.Class(Core.UI.Child)
Core.UI.Anchor = M

---@alias Core.UI.Anchor.New Core.UI.Anchor|fun(image:string):Core.UI.Anchor
function M:init()
    Core.UI.Child.init(self, "Anchor", 0)
end