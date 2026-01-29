---类型定义系统
---用于定义和检查对象类型及继承关系，并创建实例
---@author OLC
---@class Core.Lib.TypeDef
local M = {}
Core.Lib.TypeDef = M

local pairs = pairs
local ipairs = ipairs
local table = table
local error = error
local type = type

---@field typeName string 类型名称
---@field baseType Core.Lib.TypeDef.Type|nil 直接父类型
---@field baseTypes Core.Lib.TypeDef.Type[] 继承链数组，从直接父类到最顶层基类（自动构建）
---@field defaults table|nil 默认属性值
---@field methods table|nil 方法定义

---创建类型定义
---@param typeName string 类型名称
---@param baseType Core.Lib.TypeDef.Type|nil 直接父类型
---@param config table|nil 配置，包含 defaults（默认属性）和 methods（方法）
---@return Core.Lib.TypeDef.Type
function M.Create(typeName, baseType, config)
    config = config or {}

    ---@class Core.Lib.TypeDef.Type
    local typeDef = {
        typeName = typeName,
        baseType = baseType,
        baseTypes = {},
        defaults = config.defaults or {},
        methods = config.methods or {},
    }

    -- 自动构建继承链
    if baseType then
        local chain = { baseType }
        local current = baseType.baseType
        while current do
            table.insert(chain, current)
            current = current.baseType
        end
        typeDef.baseTypes = chain
    end

    return typeDef
end

---从类型定义创建实例
---@param typeDef Core.Lib.TypeDef.Type 类型定义
---@param config table|nil 实例配置，会与默认值合并
---@return table 创建的实例
function M.Instantiate(typeDef, config)
    if not typeDef then
        error("TypeDef is required for instantiation", 2)
    end

    config = config or {}
    local instance = {}

    -- 从继承链中合并默认值（从最顶层基类到当前类）
    if typeDef.baseTypes then
        for i = #typeDef.baseTypes, 1, -1 do
            local baseType = typeDef.baseTypes[i]
            if baseType.defaults then
                for k, v in pairs(baseType.defaults) do
                    if instance[k] == nil then
                        instance[k] = v
                    end
                end
            end
        end
    end

    -- 应用当前类型的默认值
    if typeDef.defaults then
        for k, v in pairs(typeDef.defaults) do
            if instance[k] == nil then
                instance[k] = v
            end
        end
    end

    -- 从继承链中合并方法（从最顶层基类到当前类）
    if typeDef.baseTypes then
        for i = #typeDef.baseTypes, 1, -1 do
            local baseType = typeDef.baseTypes[i]
            if baseType.methods then
                for k, v in pairs(baseType.methods) do
                    if instance[k] == nil then
                        instance[k] = v
                    end
                end
            end
        end
    end

    -- 应用当前类型的方法
    if typeDef.methods then
        for k, v in pairs(typeDef.methods) do
            instance[k] = v
        end
    end

    -- 应用配置（覆盖默认值和方法）
    for k, v in pairs(config) do
        instance[k] = v
    end

    -- 设置类型定义
    instance.typeDef = typeDef

    return instance
end

---检查类型定义是否为指定类型或其子类型
---@param typeDef Core.Lib.TypeDef.Type 类型定义
---@param targetType Core.Lib.TypeDef.Type|string 要检查的类型，可以是 TypeDef 对象或类型名称字符串
---@return boolean
function M.IsTypeOf(typeDef, targetType)
    if not typeDef or not targetType then
        return false
    end

    local targetTypeName
    if type(targetType) == "string" then
        targetTypeName = targetType
    else
        targetTypeName = targetType.typeName
    end

    -- 检查当前类型
    if typeDef.typeName == targetTypeName then
        return true
    end

    -- 检查继承链中的所有类型
    if typeDef.baseTypes then
        for _, baseType in ipairs(typeDef.baseTypes) do
            if baseType.typeName == targetTypeName then
                return true
            end
        end
    end

    return false
end

---获取类型定义的完整继承链（包括自身）
---@param typeDef Core.Lib.TypeDef.Type 类型定义
---@return Core.Lib.TypeDef.Type[] 继承链数组，从当前类型到最顶层基类
function M.GetInheritanceChain(typeDef)
    if not typeDef then
        return {}
    end

    local chain = { typeDef }
    if typeDef.baseTypes then
        for _, baseType in ipairs(typeDef.baseTypes) do
            table.insert(chain, baseType)
        end
    end

    return chain
end

