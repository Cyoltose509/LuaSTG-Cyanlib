---@class Core.UI.Immediate : Core.UI.Child
local Immediate = Core.Class(Core.UI.Child)
Core.UI.Immediate = Immediate

---@alias Core.UI.Immediate.New Core.UI.Immediate|fun(name:string, layer:number,renderEvent:fun(), frameEvent:fun()):Core.UI.Immediate
function Immediate:init(name, layer, renderEvent, frameEvent)
    Core.UI.Child.init(self, name, layer)
    self.can_serialize = false
    self.renderEvent = renderEvent or function()
    end
    self.frameEvent = frameEvent or function()
    end

end
function Immediate:update()
    self:frameEvent()
end
function Immediate:draw()
    self:renderEvent()
    Core.UI.Child.draw(self)
end