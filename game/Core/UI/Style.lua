---@class Core.UI.Style
---样式注册与级联系统（对应 CSS 的 class 与继承）。
---
---用法：
---  Core.UI.Style.Define("panel", { padding = {8,8,8,8}, align_items = "center", gap = 4 })
---  Core.UI.Style.Define("title", { font = "exo2", color = Core.Render.Color.White, flex_grow = 0 })
---  local t = Core.UI.Text():addStyle("panel"):addStyle("title")
---  t:setInlineStyle({ color = Core.Render.Color.Red })  -- 内联优先级最高
---
---级联优先级（低 -> 高）：父节点继承的可继承属性 < 命名样式(按 addStyle 顺序) < 内联样式。
---可继承属性（font / color / text_align）会沿树向下传递，子节点未覆盖时自动继承。
local M = {}
Core.UI.Style = M

---@type table<string, table>
local registry = {}

---注册一个命名样式（类似 CSS 类）。可链式返回 M。
---@param name string
---@param props table
function M.Define(name, props)
    registry[name] = props or {}
    return M
end

---获取已注册的命名样式
---@param name string
function M.Get(name)
    return registry[name]
end

---把所有 key 统一成下划线形式（"justify-content" -> "justify_content"），方便 CSS 风格与 Lua 风格混用
---@param k string
local function norm(k)
    return (k:gsub("-", "_"))
end

---布局相关字段：改变它们需要触发重排
local layoutKeys = {
    padding = true,
    gap = true,
    row_gap = true,
    column_gap = true,
    flex_direction = true,
    flex_wrap = true,
    justify_content = true,
    align_items = true,
    align_content = true,
    margin = true,
    flex_grow = true,
    flex_shrink = true,
    flex_basis = true,
    align_self = true,
    order = true,
    min_width = true,
    max_width = true,
    min_height = true,
    max_height = true,
    position = true,
    inset_top = true,
    inset_right = true,
    inset_bottom = true,
    inset_left = true,
    display = true,
    locked_scale = true,
    exclude_from_layout = true,
}

---需要通过节点 setter 应用的视觉/可继承属性
local setterKeys = {
    font = function(node, v)
        if node.setFont then
            node:setFont(v)
        end
    end,
    color = function(node, v)
        if node.setColor then
            node:setColor(v)
        end
    end,
    text_align = function(node, v)
        local h = v == "left" and -1 or v == "right" and 1 or 0
        if node.setAlignValue then
            node:setAlignValue(h, 0)
        end
    end,
}

---可继承属性集合（沿树向下传递）
local inheritable = {
    font = true,
    color = true,
    text_align = true,
}

---合并样式：父继承 < 命名样式(顺序) < 内联。返回归一化后的有效属性表。
---@param node Core.UI.Child
---@param inherited table|nil 父节点传下来的可继承属性
---@return table
function M.Resolve(node, inherited)
    local eff = {}
    if inherited then
        for k, v in pairs(inherited) do
            eff[k] = v
        end
    end
    for _, name in ipairs(node.style_names) do
        local s = registry[name]
        if s then
            for k, v in pairs(s) do
                eff[norm(k)] = v
            end
        end
    end
    for k, v in pairs(node.inline_style) do
        eff[norm(k)] = v
    end
    return eff
end

---把有效属性应用到节点上，返回需要向下继承的属性集合（可继承键的子集）。
---@param node Core.UI.Child
---@param eff table
---@return table|nil
function M.Apply(node, eff)
    local layoutChanged = false
    for k, v in pairs(eff) do
        local setter = setterKeys[k]
        if setter then
            setter(node, v)
        elseif layoutKeys[k] then
            if k == "padding" or k == "margin" then
                if type(v) == "table" then
                    node[k] = { v[1], v[2], v[3], v[4] }
                else
                    node[k] = v
                end
            else
                node[k] = v
            end
            layoutChanged = true
        else
            node[k] = v
        end
    end
    if layoutChanged and node.setDirty then
        node:setDirty()
    end
    local own
    for k in pairs(inheritable) do
        if eff[k] ~= nil then
            own = own or {}
            own[k] = eff[k]
        end
    end
    return own
end
