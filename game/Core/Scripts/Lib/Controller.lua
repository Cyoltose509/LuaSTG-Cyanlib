---@class Core.Lib.Controller
local M = {}
Core.Lib.Controller = M

---@class Core.Lib.Controller.Child
---@field onInit fun(self:Core.Lib.Controller.Child)
---@field onEnable fun(self:Core.Lib.Controller.Child)
---@field onDisable fun(self:Core.Lib.Controller.Child)
---@field onUpdate fun(self:Core.Lib.Controller.Child)
---@field addOnFinishStateHandler fun(self:Core.Lib.Controller.Child, handler:fun(event:string))

---@param opt Core.Lib.Controller.Child
function M.NewChild(opt)
    return {
        onInit = opt.onInit or function()
        end,
        onEnable = opt.onEnable or function()
        end,
        onDisable = opt.onDisable or function()
        end,
        onUpdate = opt.onUpdate or function()
        end,
        addOnFinishStateHandler = opt.addOnFinishStateHandler or function()
        end
    }
end

---@class Core.Lib.Controller.Group:Core.Lib.Controller.Child
local Group = Core.Class()

function Group:init(controllers)
    self.controllers = controllers or {}
    self.callbacks = {}
    -- 注册子控制器完成回调
    for _, ctrl in ipairs(self.controllers) do
        ctrl:addOnFinishStateHandler(function(...)
            self:_onChildFinish(...)
        end)
    end
end

function Group:addController(controller)
    table.insert(self.controllers, controller)
    controller:addOnFinishStateHandler(function(...)
        self:_onChildFinish(...)
    end)
end

function Group:removeController()
    
end

function Group:_onChildFinish(event)
    for _, cb in ipairs(self.callbacks) do
        cb(event)
    end
end

function Group:addOnFinishStateHandler(handler)
    table.insert(self.callbacks, handler)
end

function Group:onInit()
    for _, ctrl in ipairs(self.controllers) do
        ctrl:onInit()
    end
end

function Group:onEnable()
    for _, ctrl in ipairs(self.controllers) do
        ctrl:onEnable()
    end
end

function Group:onDisable()
    for _, ctrl in ipairs(self.controllers) do
        ctrl:onDisable()
    end
end

function Group:onUpdate()
    for _, ctrl in ipairs(self.controllers) do
        ctrl:onUpdate()
    end
end

---@param controllers Core.Lib.Controller.Child[]
function M.NewGroup(controllers)
    return Group(controllers)
end

