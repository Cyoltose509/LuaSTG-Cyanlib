---@author OLC
---@class Core.Lib.ComponentSystem
local M = Core.Class()
Core.Lib.ComponentSystem = M

function M:init(owner)
    self.owner = owner
    ---@type Core.Lib.ComponentBase[]
    self.components = {}
    self.componentCount = 0
    ---@type Core.Lib.ComponentBase[]
    self.componentsByName = {}
    self._sortDirty = true
end

---可以指定位置、优先度等
---@class Core.Lib.ComponentSystem.AddOption
---@field name string
---@field level number
---@field func function
---@field before string|nil
---@field after string|nil
---添加组件
---@param component Core.Lib.ComponentBase 组件实例
---@param opt Core.Lib.ComponentSystem.AddOption|nil
function M:addComponent(name, component, opt)
    opt = opt or {}

    local list = self.components
    local function calcLevel(refName, dir)
        local ref = self:getComponent(refName)

        local idx = 1
        for i, v in ipairs(list) do
            if v == ref then
                idx = i
                break
            end
        end
        local ptr
        if dir == -1 then
            ptr = max(idx - 1, 1)
            local before = list[ptr]
            return before and (before._level + ref._level) / 2 or ref._level - 1
        elseif dir == 1 then
            ptr = min(idx + 1, #list)
            local after = list[ptr]
            return after and (ref._level + after._level) / 2 or ref._level + 1
        end
    end
    local level = opt.level
    local before = opt.before
    local after = opt.after
    if before then
        level = calcLevel(before, -1)
    elseif after then
        level = calcLevel(after, 1)
    elseif not level then
        local last = list[#list]
        if last then
            level = last._level + 1
        else
            level = 0
        end
    end

    component._level = level
    component:setEnable(true)
    component:setName(name)
    if self.componentsByName[name] then
        for i = 1, self.componentCount do
            if self.components[i].name == name then
                self:_doRemoveComponent(self.components[i])
                self.components[i] = component
                break
            end
        end
    else
        local count = self.componentCount + 1
        self.componentCount = count
        self.components[count] = component
    end
    self.componentsByName[name] = component

    self._sortDirty = true

    return self
end

---移除组件
---@param component Core.Lib.ComponentBase|string 组件实例或名称
function M:removeComponent(component)
    if not component then
        return
    end
    if type(component) == "string" then
        component = self:getComponent(component)
    end
    if component then
        self:_doRemoveComponent(component)
    end
    return self
end

---根据类型获取第一个组件（支持别名）
---@param name string
---@return Core.Lib.ComponentBase
function M:getComponent(name)
    return self.componentsByName[name]
end

---清空所有组件
function M:clear()
    for _, c in ipairs(self.components) do
        if c.onDestroy then
            c:onDestroy()
        end
    end
    self.components = {}
    self.componentCount = 0
    self.componentsByName = {}
    return self
end

---内部方法：实际移除组件
---@private
---@param component Core.Lib.ComponentBase 组件实例
function M:_doRemoveComponent(component)
    if not component then
        return
    end

    if component.onDestroy then
        component:onDestroy()
    end

    self._startedComponents[component] = nil

    -- 从 components 数组中移除
    local components = self.components
    for i = 1, self.componentCount do
        if components[i] == component then
            components[i] = nil
            break
        end
    end

    component._level = nil
    component._name = nil

    self.componentCount = self.componentCount - 1
    self._sortDirty = true
end

---@private
function M:_sortComponents()
    table.sort(self.components, function(a, b)
        return (a._level or 0) < (b._level or 0)
    end)
end

---对所有启用的组件执行指定函数
---@param func fun(comp:Core.Lib.ComponentBase)
function M:requestDo(func)
    if self._sortDirty then
        self:_sortComponents()
        self._sortDirty = false
    end
    for _, c in ipairs(self.components) do
        if c:isEnabled() then
            func(c)
        end
    end
end


