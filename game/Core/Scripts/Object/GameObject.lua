---@author OLC
---@class Core.Object.GameObject
local M = {}
Core.Object.GameObject = M

local pairs = pairs
local error = error

local GameObjectMixin = Core.Object.GameObjectMixin
local TypeDef = Core.Lib.TypeDef

M.GameObjectType = TypeDef.Create("Core.GameObject")

---@class Core.GameObject : lstg.GameObject
---@field typeDef Core.Lib.TypeDef.Type 类型定义
---@field _componentSystem Core.Lib.ComponentSystem 组件系统
---@field _lifecycleStarted boolean 生命周期是否已开始（Start 是否已调用）
---@field _listener Core.Lib.EventListener|nil 事件监听器（延迟初始化）
---@field Awake fun(self: Core.GameObject)|nil 对象创建后立即调用（在 init 中）
---@field Start fun(self: Core.GameObject)|nil 第一次 frame 之前调用
---@field Update fun(self: Core.GameObject)|nil 每帧更新（在组件更新之前）
---@field LateUpdate fun(self: Core.GameObject)|nil 每帧更新后（在组件更新之后）
---@field OnRender fun(self: Core.GameObject)|nil 渲染时调用
---@field OnCollision fun(self: Core.GameObject, other: lstg.GameObject)|nil 碰撞时调用
---@field OnDelete fun(self: Core.GameObject)|nil 删除时调用（简单销毁回调）
---@field OnDestroy fun(self: Core.GameObject)|nil 销毁时调用（执行特定事件）
local GameObject = Core.Object.Define()

---初始化对象
function GameObject:init()
    GameObjectMixin.Mixin(self)

    self._lifecycleStarted = false

    self._listener = nil
end

---帧更新
function GameObject:frame()
    -- 第一次调用时触发 Start
    if not self._lifecycleStarted then
        self._lifecycleStarted = true
        local start = self.Start
        if start then
            start(self)
        end

        -- 处理组件 Start 生命周期（第一次调用时，在 GameObject Update 之前）
        self:startComponents()
    end

    -- 调用 Update 生命周期（在组件更新之前）
    local update = self.Update
    if update then
        update(self)
    end

    -- 更新组件 Update 生命周期
    self:updateComponents()
end

---渲染
function GameObject:render()
    -- 调用 OnRender 生命周期
    local onRender = self.OnRender
    if onRender then
        onRender(self)
    else
        Core.Object.DefaultRender(self)
    end

    -- 渲染组件系统
    self:renderComponents()
end

---碰撞回调
---@param other lstg.GameObject
function GameObject:colli(other)
    -- 调用 OnCollision 生命周期
    local onCollision = self.OnCollision
    if onCollision then
        onCollision(self, other)
    end
end

---删除回调（简单销毁对象，不执行特定事件）
function GameObject:del()
    -- 调用 OnDelete 生命周期
    local onDelete = self.OnDelete
    if onDelete then
        onDelete(self)
    end
end

---销毁回调（执行特定事件）
function GameObject:kill()
    -- 调用 OnDestroy 生命周期
    local onDestroy = self.OnDestroy
    if onDestroy then
        onDestroy(self)
    end
end

---创建 GameObject 实例
---@param typeDef Core.Lib.TypeDef.Type 类型定义（必需）
---@param config table|nil 可选的配置，包含生命周期方法等
---@return Core.GameObject
function M.Create(typeDef, config)
    if not typeDef then
        error("TypeDef is required", 2)
    end
    local self = Core.Object.New(GameObject)

    local typeDefInstance = TypeDef.Instantiate(typeDef, config)

    for k, v in pairs(typeDefInstance) do
        self[k] = v
    end

    if self.Awake then
        self:Awake()
    end

    return self
end

---检查对象是否为指定类型或其子类型
---@param targetType Core.Lib.TypeDef.Type|string 要检查的类型，可以是 TypeDef 对象或类型名称字符串
---@return boolean
function GameObject:isTypeOf(targetType)
    if not self.typeDef then
        return false
    end
    return TypeDef.IsTypeOf(self.typeDef, targetType)
end

function M.AfterFrame()
    ---@param obj Core.GameObject
    for obj in Core.Object.ObjList(-1) do
        if Core.Object.IsValid(obj) then
            if obj.typeDef and obj.isTypeOf and obj:isTypeOf(M.GameObjectType) then
                local lateUpdate = obj.LateUpdate
                if lateUpdate then
                    lateUpdate(obj)
                end
                if obj.lateUpdateComponents then
                    obj:lateUpdateComponents()
                end
            end
        end
    end
end


