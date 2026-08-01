--- Flex 布局引擎内自测。
--- 直接在引擎里执行：require("Test.UI.FlexSelfTest") 即可打印 PASS/FAIL。
--- 这些断言对应 game/Core/UI/Layout.lua 中 Flex:applyLayout 的几何算法。
local M = {}
Core.UI.FlexSelfTest = M

local fails = 0
local function check(name, got, exp, tol)
    tol = tol or 1e-4
    local ok = type(got) == "number" and abs(got - exp) <= tol
    if not ok then
        fails = fails + 1
        print("FAIL " .. name .. " got=" .. tostring(got) .. " exp=" .. tostring(exp))
    else
        print("PASS " .. name)
    end
end

---创建一个仅用于测试尺寸的裸节点
local function node(w, h)
    local n = Core.UI.Child("test", 0)
    n:setWH(w, h)
    return n
end

local function container(w, h)
    local f = Core.UI.Layout.Flex()
    f:setWH(w, h)
    return f
end

function M.Run()
    -- Case 1: row, 3x w100, cw400 ch300, justify flex-start, align stretch
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.justify_content = "flex-start"
        c.align_items = "stretch"
        local k = { node(100, 50), node(100, 50), node(100, 50) }
        for _, v in ipairs(k) do
            c:addChild(v)
        end
        c:rebuild()
        check("c1 x0", k[1].arranged_x, -150)
        check("c1 x1", k[2].arranged_x, -50)
        check("c1 x2", k[3].arranged_x, 50)
        check("c1 y", k[1].arranged_y, 0)
        check("c1 vscale", k[1].arranged_vscale, 6.0)
    end

    -- Case 2: justify center
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.justify_content = "center"
        c.align_items = "stretch"
        local k = { node(100, 50), node(100, 50), node(100, 50) }
        for _, v in ipairs(k) do
            c:addChild(v)
        end
        c:rebuild()
        check("c2 x0", k[1].arranged_x, -100)
        check("c2 x2", k[3].arranged_x, 100)
    end

    -- Case 3: space-between
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.justify_content = "space-between"
        c.align_items = "stretch"
        local k = { node(100, 50), node(100, 50), node(100, 50) }
        for _, v in ipairs(k) do
            c:addChild(v)
        end
        c:rebuild()
        check("c3 x0", k[1].arranged_x, -150)
        check("c3 x1", k[2].arranged_x, 0)
        check("c3 x2", k[3].arranged_x, 150)
    end

    -- Case 4: grow
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.justify_content = "flex-start"
        c.align_items = "flex-start"
        local k = { node(100, 50), node(100, 50) }
        k[1].flex_grow = 1
        k[2].flex_grow = 1
        for _, v in ipairs(k) do
            c:addChild(v)
        end
        c:rebuild()
        check("c4 x0", k[1].arranged_x, -100)
        check("c4 x1", k[2].arranged_x, 100)
        check("c4 hscale", k[1].arranged_hscale, 2.0)
        check("c4 y", k[1].arranged_y, 125.0)
    end

    -- Case 5: column-reverse single child, align stretch
    do
        local c = container(400, 300)
        c.flex_direction = "column-reverse"
        c.justify_content = "flex-start"
        c.align_items = "stretch"
        local k = { node(100, 50) }
        c:addChild(k[1])
        c:rebuild()
        check("c5 x", k[1].arranged_x, -50)
        check("c5 y", k[1].arranged_y, -125.0)
        check("c5 hscale", k[1].arranged_hscale, 3.0)
    end

    -- Case 6: absolute positioning
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.align_items = "stretch"
        local k = node(100, 50)
        k.position = "absolute"
        k.inset_left = 10
        k.inset_top = 10
        c:addChild(k)
        c:rebuild()
        check("c6 ax", k.arranged_x, -140)
        check("c6 ay", k.arranged_y, 115)
        check("c6 vscale", k.arranged_vscale, 1.0)
    end

    -- Case 7: wrap into 2 lines
    do
        local c = container(250, 300)
        c.flex_direction = "row"
        c.flex_wrap = "wrap"
        c.justify_content = "flex-start"
        c.align_items = "flex-start"
        local k = { node(100, 50), node(100, 50), node(100, 50) }
        for _, v in ipairs(k) do
            c:addChild(v)
        end
        c:rebuild()
        check("c7 l1x0", k[1].arranged_x, -75)
        check("c7 l1x1", k[2].arranged_x, 25)
        check("c7 l2x0", k[3].arranged_x, -75)
        check("c7 l2y", k[3].arranged_y, 75)
    end

    -- Case 8: absolute 双边都指定（left+right）-> 水平拉伸填满
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.align_items = "stretch"
        local k = node(100, 50)
        k.position = "absolute"
        k.inset_left = 10
        k.inset_right = 0
        c:addChild(k)
        c:rebuild()
        -- left=10,right=0 -> x0=10,x1=400 fcx=205 -> ax=5 ; 宽拉伸 (400-10)/100=3.9
        -- top/bottom 未指定 -> 垂直居中，保留内在高度 vscale=1.0
        check("c8 ax", k.arranged_x, 5)
        check("c8 ay", k.arranged_y, 0)
        check("c8 hscale", k.arranged_hscale, 3.9)
        check("c8 vscale", k.arranged_vscale, 1.0)
    end

    -- Case 9: 百分比 flex-basis（"50%" 相对容器主轴内容尺寸）
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.justify_content = "flex-start"
        c.align_items = "flex-start"
        local k = node(100, 50)
        k.flex_basis = "50%"
        c:addChild(k)
        c:rebuild()
        check("c9 basis", k._flex_main, 200)
        check("c9 ax", k.arranged_x, -100)
    end

    -- Case 10: display:none 的子项不参与布局
    do
        local c = container(400, 300)
        c.flex_direction = "row"
        c.justify_content = "flex-start"
        c.align_items = "flex-start"
        local k1 = node(100, 50)
        local k2 = node(100, 50)
        k2.display = "none"
        c:addChild(k1)
        c:addChild(k2)
        c:rebuild()
        check("c10 k1 ax", k1.arranged_x, -150)
        check("c10 k2 untouched", k2.arranged_x, 0)
    end

    print("\nFlexSelfTest FAILS: " .. tostring(fails))
    return fails
end

-- 直接 require 时自动跑一遍
M.Run()

return M
