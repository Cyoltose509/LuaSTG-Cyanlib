---@author OLC
---@class Core.Lib.ComponentSystem
local M = Core.Class()
Core.Lib.ComponentSystem = M

local ipairs = ipairs
local pairs = pairs
local type = type
local error = error
local string = string

local TypeDef = Core.Lib.TypeDef

M.ComponentType = TypeDef.Create("Core.Component", nil, {
    defaults = {
        enabled = true,
        executePriority = 0,
    },
})



function M:init(owner)
    self.owner = owner
    self.components = {}
    self.updateComponents = nil
    self.renderComponents = nil
    self.componentCount = 0
    self.updateComponentCount = 0
    self.renderComponentCount = 0
    self.componentsByType = {}
    self.componentAliases = {}
    self.sortDirty = false
    self.updateSortDirty = false
    self.renderSortDirty = false
    self._startedComponents = {}
end

---@class Core.Object.ComponentSystem.Component
---@field enabled boolean
---@field executePriority number|nil update优先级，数字越大越先执行（可选，默认0）
---@field renderPriority number|nil render优先级（可选，默认使用executePriority）
---@field owner any
---@field typeDef Core.Lib.TypeDef.Type 类型定义
---@field executeBefore string[]|nil update时在这些组件之前执行
---@field executeAfter string[]|nil update时在这些组件之后执行
---@field renderBefore string[]|nil render时在这些组件之前渲染
---@field renderAfter string[]|nil render时在这些组件之后渲染
---@field isTypeOf fun(self: Core.Object.ComponentSystem.Component, targetType: Core.Lib.TypeDef.Type|string): boolean 检查是否为指定类型或其子类型
---@field Awake fun(self: Core.Object.ComponentSystem.Component)|nil 添加时回调，在 addComponent 时立即调用
---@field Start fun(self: Core.Object.ComponentSystem.Component)|nil 第一次 update 之前调用，用于解析依赖
---@field Update fun(self: Core.Object.ComponentSystem.Component)|nil 每帧更新
---@field LateUpdate fun(self: Core.Object.ComponentSystem.Component)|nil 每帧更新后
---@field OnRender fun(self: Core.Object.ComponentSystem.Component)|nil 渲染回调
---@field OnDestroy fun(self: Core.Object.ComponentSystem.Component)|nil 移除时回调
---添加组件
---@param component Core.Object.ComponentSystem.Component 组件实例
function M:addComponent(component)
    -- 检查 component 是否已经挂载在其他对象上
    if component.owner and component.owner ~= self.owner then
        local componentTypeName = (component.typeDef and component.typeDef.typeName) or component.typeName or "unknown"
        error(string.format(
                "Cannot add component '%s' to object: component is already attached to another object",
                componentTypeName
        ), 2)
    end

    -- 检查组件是否有类型定义
    if not component.typeDef then
        error("Component must have typeDef. Use TypeDef.instantiate() to create components.", 2)
    end

    -- 设置 owner
    component.owner = self.owner

    -- 添加 isTypeOf 方法（如果还没有）
    if not component.isTypeOf then
        function component:isTypeOf(targetType)
            if not self.typeDef then
                return false
            end
            return TypeDef.IsTypeOf(self.typeDef, targetType)
        end
    end

    local count = self.componentCount + 1
    self.componentCount = count
    self.components[count] = component

    -- 按类型分组（使用 typeName）
    local typeName = component.typeDef.typeName
    if typeName then
        local typeList = self.componentsByType[typeName]
        if not typeList then
            typeList = { count = 0 }
            self.componentsByType[typeName] = typeList
        end
        local typeCount = typeList.count + 1
        typeList.count = typeCount
        typeList[typeCount] = component

        -- 注册组件别名（如果组件定义了 alias）
        if component.alias then
            if type(component.alias) == "string" then
                self.componentAliases[component.alias] = typeName
            elseif type(component.alias) == "table" then
                for _, alias in ipairs(component.alias) do
                    self.componentAliases[alias] = typeName
                end
            end
        end
    end

    self.sortDirty = true
    self.updateSortDirty = true
    self.renderSortDirty = true

    -- 立即调用 Awake 生命周期
    local awake = component.Awake
    if awake then
        awake(component)
    end
    return self
end

---批量添加组件
---@vararg Core.Object.ComponentSystem.Component 组件实例
function M:addComponents(...)
    local components = { ... }
    for _, component in ipairs(components) do
        self:addComponent(component)
    end
    return self
end

---移除组件
---@param componentOrType Core.Object.ComponentSystem.Component|string 组件实例或类型名称
function M:removeComponent(componentOrType)
    if not componentOrType then
        return
    end

    local component
    if type(componentOrType) == "string" then
        component = self:getComponent(componentOrType)
    else
        component = componentOrType
    end

    if component then
        self:_doRemoveComponent(component)
    end
    return self
end

---批量移除组件
---@vararg Core.Object.ComponentSystem.Component|string 组件实例或类型名称
function M:removeComponents(...)
    local args = { ... }
    for _, componentOrType in ipairs(args) do
        if componentOrType then
            self:removeComponent(componentOrType)
        end
    end
    return self
end

---根据类型获取组件列表
---@param componentType string
---@return Core.Object.ComponentSystem.Component[]|nil
function M:getComponents(componentType)
    return self.componentsByType[componentType]
end

---根据类型获取第一个组件（支持别名）
---@param componentType string
---@return Core.Object.ComponentSystem.Component|nil
function M:getComponent(componentType)
    -- 先尝试直接查找
    local list = self.componentsByType[componentType]
    if list and list.count > 0 then
        return list[1]
    end
    -- 尝试通过别名查找
    local actualType = self.componentAliases[componentType]
    if actualType then
        list = self.componentsByType[actualType]
        if list and list.count > 0 then
            return list[1]
        end
    end
    return nil
end

---处理所有组件的 Start 生命周期（第一次调用时）
function M:Start()
    -- 清理被删除的组件
    if self.sortDirty then
        self:_compact()
        self:_sortComponents()
        self.sortDirty = false
    end

    -- 处理所有组件的 Start 生命周期（在第一次调用时）
    local components = self.components
    local count = self.componentCount
    for i = 1, count do
        local component = components[i]
        if component and not self._startedComponents[component] then
            self._startedComponents[component] = true
            local start = component.Start
            if start then
                start(component)
            end
        end
    end
end

---更新所有组件的 Update 生命周期
function M:Update()
    -- 清理被删除的组件
    if self.sortDirty then
        self:_compact()
        self:_sortComponents()
        self.sortDirty = false
    end

    -- 如果需要，构建并排序update组件列表
    if self.updateSortDirty or not self.updateComponents then
        self:_sortUpdateComponents()
        self.updateSortDirty = false
    end

    local updateComponents = self.updateComponents
    local updateCount = self.updateComponentCount

    -- 调用 Update 生命周期
    for i = 1, updateCount do
        local component = updateComponents[i]
        if component and component.enabled then
            local update = component.Update
            if update then
                update(component)
            end
        end
    end
end

---更新所有组件的 LateUpdate 生命周期
function M:LateUpdate()
    -- 如果需要，构建并排序update组件列表
    if self.updateSortDirty or not self.updateComponents then
        self:_sortUpdateComponents()
        self.updateSortDirty = false
    end

    local updateComponents = self.updateComponents
    local updateCount = self.updateComponentCount

    -- 调用 LateUpdate 生命周期
    for i = 1, updateCount do
        local component = updateComponents[i]
        if component and component.enabled then
            local lateUpdate = component.LateUpdate
            if lateUpdate then
                lateUpdate(component)
            end
        end
    end
end

---渲染所有组件
function M:OnRender()
    -- 如果需要，构建并排序render组件列表
    if self.renderSortDirty or not self.renderComponents then
        self:_sortRenderComponents()
        self.renderSortDirty = false
    end

    local components = self.renderComponents
    local count = self.renderComponentCount

    -- 调用 OnRender 生命周期
    for i = 1, count do
        local component = components[i]
        if component and component.enabled then
            local onRender = component.OnRender
            if onRender then
                onRender(component)
            end
        end
    end
end

---清空所有组件
function M:clear()
    local components = self.components
    local count = self.componentCount

    for i = 1, count do
        local component = components[i]
        if component then
            local onDestroy = component.OnDestroy
            if onDestroy then
                onDestroy(component)
            end
        end
    end

    self.components = {}
    self.componentCount = 0
    self.componentsByType = {}
    self._startedComponents = {}
    return self
end

---启用/禁用组件
---@param componentId number
---@param enabled boolean
function M:setComponentEnabled(componentId, enabled)
    local component = self.components[componentId]
    if component then
        component.enabled = enabled
    end
    return self
end


---内部方法：实际移除组件
---@private
---@param component Core.Object.ComponentSystem.Component 组件实例
function M:_doRemoveComponent(component)
    if not component then
        return
    end

    -- 调用 OnDestroy 生命周期
    local onDestroy = component.OnDestroy
    if onDestroy then
        onDestroy(component)
    end

    -- 清理别名
    if component.alias and component.typeDef and component.typeDef.typeName then
        if type(component.alias) == "string" then
            self.componentAliases[component.alias] = nil
        elseif type(component.alias) == "table" then
            for _, alias in ipairs(component.alias) do
                self.componentAliases[alias] = nil
            end
        end
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

    -- 从类型索引中移除
    if component.typeDef and component.typeDef.typeName then
        local typeName = component.typeDef.typeName
        local typeList = self.componentsByType[typeName]
        if typeList then
            for i = 1, typeList.count do
                if typeList[i] == component then
                    -- 将最后一个元素移到当前位置
                    if i < typeList.count then
                        typeList[i] = typeList[typeList.count]
                    end
                    typeList[typeList.count] = nil
                    typeList.count = typeList.count - 1
                    break
                end
            end
            -- 如果该类型没有组件了，清理
            if typeList.count == 0 then
                self.componentsByType[typeName] = nil
            end
        end
    end

    -- 清理 owner 引用
    component.owner = nil

    -- 需要在update时清理
    self.sortDirty = true
    self.updateSortDirty = true
    self.renderSortDirty = true
end

---@private
---排序组件（根据priority和依赖关系）
function M:_sortComponents()
    local components = self.components
    local count = self.componentCount

    if count <= 1 then
        return
    end

    -- 构建组件名称到组件的映射（包括别名）
    local nameToComp = {}
    local nameToIndex = {}
    for i = 1, count do
        local comp = components[i]
        if comp and comp.typeDef and comp.typeDef.typeName then
            local typeName = comp.typeDef.typeName
            nameToComp[typeName] = comp
            nameToIndex[typeName] = i

            -- 添加别名映射
            if comp.alias then
                if type(comp.alias) == "string" then
                    nameToComp[comp.alias] = comp
                elseif type(comp.alias) == "table" then
                    for _, alias in ipairs(comp.alias) do
                        nameToComp[alias] = comp
                    end
                end
            end
        end
    end

    -- 构建依赖图（入度统计）
    local inDegree = {}  -- 入度：有多少组件需要在这个组件之前执行
    local adjList = {}   -- 邻接表：这个组件需要在哪些组件之前执行

    for i = 1, count do
        local comp = components[i]
        if comp and comp.typeDef and comp.typeDef.typeName then
            local typeName = comp.typeDef.typeName
            inDegree[typeName] = 0
            adjList[typeName] = {}
        end
    end

    -- 处理 executeAfter 和 executeBefore
    for i = 1, count do
        local comp = components[i]
        if comp and comp.typeDef and comp.typeDef.typeName then
            local typeName = comp.typeDef.typeName
            -- executeAfter: 这个组件要在某些组件之后执行
            -- 意味着：那些组件 -> 这个组件（依赖）
            if comp.executeAfter then
                for _, afterName in ipairs(comp.executeAfter) do
                    if nameToComp[afterName] then
                        -- afterName 组件要在 comp 之前
                        if not adjList[afterName] then
                            adjList[afterName] = {}
                        end
                        adjList[afterName][typeName] = true
                        inDegree[typeName] = inDegree[typeName] + 1
                    end
                end
            end

            -- executeBefore: 这个组件要在某些组件之前执行
            -- 意味着：这个组件 -> 那些组件（依赖）
            if comp.executeBefore then
                for _, beforeName in ipairs(comp.executeBefore) do
                    if nameToComp[beforeName] then
                        -- comp 要在 beforeName 之前
                        adjList[typeName][beforeName] = true
                        inDegree[beforeName] = inDegree[beforeName] + 1
                    end
                end
            end
        end
    end

    -- 拓扑排序（Kahn算法）
    local queue = {}
    local queueStart = 1
    local queueEnd = 0

    -- 将入度为0的节点加入队列
    for name, degree in pairs(inDegree) do
        if degree == 0 then
            queueEnd = queueEnd + 1
            queue[queueEnd] = name
        end
    end

    local sorted = {}
    local sortedCount = 0

    while queueStart <= queueEnd do
        local current = queue[queueStart]
        queueStart = queueStart + 1

        sortedCount = sortedCount + 1
        sorted[sortedCount] = current

        -- 处理邻接节点
        if adjList[current] then
            for nextName in pairs(adjList[current]) do
                inDegree[nextName] = inDegree[nextName] - 1
                if inDegree[nextName] == 0 then
                    queueEnd = queueEnd + 1
                    queue[queueEnd] = nextName
                end
            end
        end
    end

    -- 检查是否有环
    if sortedCount ~= count then
        -- 有环，回退到简单优先级排序
        self:_sortByPriority()
        return
    end

    -- 应用拓扑排序结果，同时考虑priority作为二级排序
    local newComponents = {}
    local used = {}
    local newIdx = 0

    -- 按拓扑顺序和优先级排列
    for _, name in ipairs(sorted) do
        local comp = nameToComp[name]
        if comp and not used[name] then
            newIdx = newIdx + 1
            newComponents[newIdx] = comp
            used[name] = true
        end
    end

    -- 对于同一层级的组件，使用priority排序（稳定排序）
    -- 这里简化处理：已经按拓扑顺序，priority作为tie-breaker

    self.components = newComponents
end

---@private
---简单的优先级排序
function M:_sortByPriority()
    local components = self.components
    local count = self.componentCount

    for i = 1, count - 1 do
        for j = i + 1, count do
            local compA = components[i]
            local compB = components[j]
            if compA and compB then
                local prioA = compA.executePriority or 0
                local prioB = compB.executePriority or 0
                if prioB > prioA then
                    components[i] = compB
                    components[j] = compA
                end
            end
        end
    end
end

---@private
---通用的组件排序方法
---@param filterFunc function 过滤函数，返回true表示包含该组件
---@param priorityField string 优先级字段名
---@param beforeField string "在...之前"字段名
---@param afterField string "在...之后"字段名
---@return table, number 排序后的组件数组和数量
function M:_sortComponentsByType(filterFunc, priorityField, beforeField, afterField)
    local components = self.components
    local count = self.componentCount

    -- 收集符合条件的组件
    local filtered = {}
    local filteredCount = 0
    for i = 1, count do
        local comp = components[i]
        if comp and filterFunc(comp) then
            filteredCount = filteredCount + 1
            filtered[filteredCount] = comp
        end
    end

    -- 检查是否有依赖关系
    local hasDeps = false
    for i = 1, filteredCount do
        local comp = filtered[i]
        local before = comp[beforeField]
        local after = comp[afterField]
        if (before and #before > 0) or (after and #after > 0) then
            hasDeps = true
            break
        end
    end

    -- 没有依赖，使用简单排序
    if not hasDeps then
        self:_simplePrioritySort(filtered, filteredCount, priorityField)
        return filtered, filteredCount
    end

    -- 有依赖，使用拓扑排序
    local sorted = self:_topologicalSort(filtered, filteredCount, priorityField, beforeField, afterField)
    return sorted, filteredCount
end

---@private
---简单的优先级排序
function M:_simplePrioritySort(components, count, priorityField)
    for i = 1, count - 1 do
        for j = i + 1, count do
            local compA = components[i]
            local compB = components[j]
            if compA and compB then
                local prioA = compA[priorityField] or compA.executePriority or 0
                local prioB = compB[priorityField] or compB.executePriority or 0
                if prioB > prioA then
                    components[i] = compB
                    components[j] = compA
                end
            end
        end
    end
end

---@private
---拓扑排序
function M:_topologicalSort(components, count, priorityField, beforeField, afterField)
    -- 建立名称到组件的映射（包括别名）
    local nameToComp = {}
    for i = 1, count do
        local comp = components[i]
        if comp and comp.typeDef and comp.typeDef.typeName then
            local typeName = comp.typeDef.typeName
            nameToComp[typeName] = comp

            -- 添加别名映射
            if comp.alias then
                if type(comp.alias) == "string" then
                    nameToComp[comp.alias] = comp
                elseif type(comp.alias) == "table" then
                    for _, alias in ipairs(comp.alias) do
                        nameToComp[alias] = comp
                    end
                end
            end
        end
    end

    -- 建立图
    local adjList = {}
    local inDegree = {}

    for i = 1, count do
        local comp = components[i]
        if comp and comp.typeDef and comp.typeDef.typeName then
            local typeName = comp.typeDef.typeName
            inDegree[typeName] = 0
        end
    end

    -- 构建依赖关系
    for i = 1, count do
        local comp = components[i]
        if comp and comp.typeDef and comp.typeDef.typeName then
            local name = comp.typeDef.typeName
            -- before: 我在这些之前
            local before = comp[beforeField]
            if before then
                for _, target in ipairs(before) do
                    if nameToComp[target] then
                        if not adjList[name] then
                            adjList[name] = {}
                        end
                        adjList[name][target] = true
                        inDegree[target] = (inDegree[target] or 0) + 1
                    end
                end
            end

            -- after: 我在这些之后
            local after = comp[afterField]
            if after then
                for _, source in ipairs(after) do
                    if nameToComp[source] then
                        if not adjList[source] then
                            adjList[source] = {}
                        end
                        adjList[source][name] = true
                        inDegree[name] = inDegree[name] + 1
                    end
                end
            end
        end
    end

    -- Kahn算法
    local queue = {}
    local queueStart = 1
    local queueEnd = 0

    for name, degree in pairs(inDegree) do
        if degree == 0 then
            queueEnd = queueEnd + 1
            queue[queueEnd] = name
        end
    end

    local sorted = {}
    local sortedCount = 0

    while queueStart <= queueEnd do
        local current = queue[queueStart]
        queueStart = queueStart + 1

        sortedCount = sortedCount + 1
        sorted[sortedCount] = current

        if adjList[current] then
            for nextName in pairs(adjList[current]) do
                inDegree[nextName] = inDegree[nextName] - 1
                if inDegree[nextName] == 0 then
                    queueEnd = queueEnd + 1
                    queue[queueEnd] = nextName
                end
            end
        end
    end

    -- 检查环
    if sortedCount ~= count then
        -- 有环，回退到简单排序
        self:_simplePrioritySort(components, count, priorityField)
        return components
    end

    -- 应用拓扑排序结果
    local result = {}
    for i = 1, sortedCount do
        result[i] = nameToComp[sorted[i]]
    end

    return result
end

---@private
---排序update组件
function M:_sortUpdateComponents()
    local components, count = self:_sortComponentsByType(
            function(comp)
                return comp.Update ~= nil or comp.LateUpdate ~= nil
            end,
            "executePriority",
            "executeBefore",
            "executeAfter"
    )
    self.updateComponents = components
    self.updateComponentCount = count
end

---@private
---排序render组件
function M:_sortRenderComponents()
    local components, count = self:_sortComponentsByType(
            function(comp)
                return comp.OnRender ~= nil
            end,
            "renderPriority",
            "renderBefore",
            "renderAfter"
    )
    self.renderComponents = components
    self.renderComponentCount = count
end

---@private
---压缩数组，移除nil元素
function M:_compact()
    local components = self.components
    local newComponents = {}
    local newCount = 0

    for i = 1, self.componentCount do
        local comp = components[i]
        if comp then
            newCount = newCount + 1
            newComponents[newCount] = comp
        end
    end

    self.components = newComponents
    self.componentCount = newCount

    -- 重建类型索引和别名
    self.componentsByType = {}
    self.componentAliases = {}
    for i = 1, newCount do
        local comp = newComponents[i]
        if comp and comp.typeDef and comp.typeDef.typeName then
            local typeName = comp.typeDef.typeName
            local typeList = self.componentsByType[typeName]
            if not typeList then
                typeList = { count = 0 }
                self.componentsByType[typeName] = typeList
            end
            local typeCount = typeList.count + 1
            typeList.count = typeCount
            typeList[typeCount] = comp

            -- 注册组件别名
            if comp.alias then
                if type(comp.alias) == "string" then
                    self.componentAliases[comp.alias] = typeName
                elseif type(comp.alias) == "table" then
                    for _, alias in ipairs(comp.alias) do
                        self.componentAliases[alias] = typeName
                    end
                end
            end
            local count = typeList.count + 1
            typeList.count = count
            typeList[count] = comp
        end
    end
end


