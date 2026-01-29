---通用游戏对象工具函数
---为对象添加组件系统支持和事件系统支持
---@author OLC
---@class Core.Object.GameObjectMixin
local M = {}
Core.Object.GameObjectMixin = M

---为对象初始化组件系统
---@param obj table
function M.InitComponentSystem(obj)
    obj._componentSystem = Core.Lib.ComponentSystem(obj)
end

---添加组件
---@param obj table
---@param component Core.Object.ComponentSystem.Component
function M.AddComponent(obj, component)
    obj._componentSystem:addComponent(component)
end

---批量添加组件
---@param obj table
---@vararg Core.Object.ComponentSystem.Component 组件实例
function M.AddComponents(obj, ...)
    obj._componentSystem:addComponents(...)
end

---移除组件
---@param obj table
---@param componentOrType Core.Object.ComponentSystem.Component|string 组件实例或类型名称
function M.RemoveComponent(obj, componentOrType)
    obj._componentSystem:removeComponent(componentOrType)
end

---批量移除组件
---@param obj table
---@vararg Core.Object.ComponentSystem.Component|string 组件实例或类型名称
function M.RemoveComponents(obj, ...)
    obj._componentSystem:removeComponents(...)
end

---根据类型获取组件
---@param obj table
---@param componentType string
---@return Core.Object.ComponentSystem.Component|nil
function M.GetComponent(obj, componentType)
    return obj._componentSystem:getComponent(componentType)
end

---根据类型获取所有组件
---@param obj table
---@param componentType string
---@return table|nil
function M.GetComponents(obj, componentType)
    return obj._componentSystem:getComponents(componentType)
end

---处理组件 Start 生命周期
---@param obj table
function M.StartComponents(obj)
    obj._componentSystem:Start()
end

---更新组件 Update 生命周期
---@param obj table
function M.UpdateComponents(obj)
    obj._componentSystem:Update()
end

---更新组件 LateUpdate 生命周期
---@param obj table
function M.LateUpdateComponents(obj)
    obj._componentSystem:LateUpdate()
end

---渲染组件
---@param obj table
function M.RenderComponents(obj)
    obj._componentSystem:OnRender()
end

---获取或创建事件监听器（延迟初始化）
---@param obj table
---@return Core.Lib.EventListener
local function _getListener(obj)
    if not obj._listener then
        obj._listener = Core.Lib.EventListener()
    end
    return obj._listener
end

---分发事件
---@param obj table
---@param group string
function M.DispatchEvent(obj, group, ...)
    local listener = _getListener(obj)
    return listener:dispatch(group, obj, ...)
end

---注册事件监听
---@param obj table
---@param group string
---@param name string
---@param priority number 优先级
---@param callback function 回调函数
function M.RegisterEvent(obj, group, name, priority, callback)
    local listener = _getListener(obj)
    listener:addEvent(group, name, priority, callback)
end

---@param obj table
---@param group string
---@param name string
function M.UnregisterEvent(obj, group, name)
    local listener = _getListener(obj)
    listener:remove(group, name)
end

---为对象混入组件系统方法和事件系统方法
---@param obj Core.GameObject
function M.Mixin(obj)
    obj.addComponent = M.AddComponent
    obj.addComponents = M.AddComponents
    obj.removeComponent = M.RemoveComponent
    obj.removeComponents = M.RemoveComponents
    obj.getComponent = M.GetComponent
    obj.getComponents = M.GetComponents
    obj.startComponents = M.StartComponents
    obj.updateComponents = M.UpdateComponents
    obj.lateUpdateComponents = M.LateUpdateComponents
    obj.renderComponents = M.RenderComponents
    obj.registerEvent = M.RegisterEvent
    obj.unregisterEvent = M.UnregisterEvent
    obj.dispatchEvent = M.DispatchEvent
    obj._getListener = _getListener
    M.InitComponentSystem(obj)
end


