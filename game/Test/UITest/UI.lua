---@class Test.UITest.UI
---CSS Flex 布局 2D 测试场景（v3 · 扁平固定尺寸版）。
---
---## 设计原则（v3）
---v2 问题：Section→DemoEntry→header/controls/demo 嵌套过深 + 内容过多，
---标签 2-6 坐标计算崩塌，所有元素堆到屏幕中心。
---
---v3 方案：
---(1)干掉 Section/DemoEntry 多层包装 → 面板内扁平 list
---(2)所有 demo 容器给固定像素宽高（不依赖 stretch 传播）
---(3)每标签 ≤ 4 个演示块
---(4)说明文字精简为单行 Label 紧贴 demo 上方
---(5)± 按钮仅 justify/wrap 保留
local M = {}
Test.UITest.UI = M

local Core = Core
local UI = Core.UI
local P = Core.UI.Pattern
local Render = Core.Render
local Color = Render.Color

local function C(r, g, b, a)
    return Color(r, g, b, a or 255)
end

local COL = {
    bg = C(16, 18, 24), panel = C(30, 34, 44), panel2 = C(40, 46, 58),
    item = C(44, 50, 64), accent = C(86, 140, 220), accent2 = C(220, 120, 70),
    accent3 = C(120, 200, 140), text = C(228, 234, 244), muted = C(150, 160, 176),
    title = C(120, 200, 255), navActive = C(58, 86, 140),
    btnBg = C(60, 70, 90), btnHover = C(80, 95, 120),
}

-- ════════════════════════════════════════════════════════════
-- § 基础构件
-- ════════════════════════════════════════════════════════════

local function Label(text, opts)
    opts = opts or {}
    local t = UI.Text()
    t:setFont(opts.font or "songti")
    t:setText(text)
    t:setSize(opts.size or 22)
    t:setColor(opts.color or COL.text)
    if opts.align == "left" then t:setAlignValue(-1, 0)
    elseif opts.align == "right" then t:setAlignValue(1, 0)
    elseif opts.align == P.ALIGN_ITEMS.CENTER then t:setAlignValue(0, 0) end
    t:ignoreLayoutScale(true)
    return t
end

local function Box(dir, opts)
    opts = opts or {}
    local f = UI.Layout.Flex()
    f.flex_direction = dir
    if opts.gap then f:setSpacing(opts.gap) end
    if opts.padding then
        local p = opts.padding
        f:setPadding(p[1] or 0, p[3] or 0, p[4] or 0, p[2] or 0)
    end
    if opts.justify then f.justify_content = opts.justify end
    if opts.align then f.align_items = opts.align end
    if opts.wrap then f.flex_wrap = opts.wrap end
    if opts.position then f.position = opts.position end
    if opts.inset then
        f.inset_top, f.inset_right, f.inset_bottom, f.inset_left =
            opts.inset[1], opts.inset[2], opts.inset[3], opts.inset[4]
    end
    if opts.z then f:setZIndex(opts.z) end
    if opts.display then f.display = opts.display end
    if opts.background or opts.gradient then
        local bg = UI.Draw.Rect("_bg", 0)
        bg.position = P.POSITION.ABSOLUTE
        bg.inset_top, bg.inset_right, bg.inset_bottom, bg.inset_left = 0, 0, 0, 0
        if opts.gradient then
            bg:setGradient(opts.gradient[1], opts.gradient[2], opts.gradient[3])
        else
            bg:setState(Render.BlendMode.Default, opts.background)
        end
        if opts.hover_color then bg:setHoverColor(opts.hover_color) end
        if opts.hover_scale then bg:setHoverScale(opts.hover_scale) end
        f:addChild(bg)
        f._bg = bg
    end
    if opts.wh then f:setWH(opts.wh[1], opts.wh[2]) end
    return f
end

local function Swatch(w, h, color)
    local r = UI.Draw.Rect("swatch", 0)
    r:setWH(w, h)
    r:setState(Render.BlendMode.Default, color)
    return r
end

local function TagSquare(letter, color, w, h, fg)
    local b = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, wh = { w or 40, h or 40 }, background = color })
    b:addChild(Label(letter, { size = 17, color = fg or C(255, 255, 255) }))
    return b
end

local function Btn(text_, onClick, opts)
    opts = opts or {}
    local b = Box(P.FLEX_DIRECTION.ROW, {
        align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER,
        padding = { 4, 10, 4, 10 },
        background = opts.bg or COL.btnBg,
        hover_color = opts.hover or COL.btnHover,
        hover_scale = 1.05,
    })
    b:addChild(Label(text_, { size = opts.size or 16, color = opts.color or COL.text }))
    if onClick then b.on_click = onClick end
    return b
end

-- ════════════════════════════════════════════════════════════
-- § 标签构建函数（扁平结构）
-- ════════════════════════════════════════════════════════════

---标签①：flex-direction（4 种）
local function buildDirection()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 14, padding = { 12, 16, 12, 16 } })
    p:addChild(Label("flex-direction：主轴方向", { size = 20, color = COL.title }))
    p:addChild(Label("reverse 翻转视觉顺序但不改变 DOM 顺序", { size = 14, color = COL.muted }))

    -- row / row-reverse（横排，固定宽高容器）
    local rowDemo = Box(P.FLEX_DIRECTION.ROW, { gap = 10, align = P.ALIGN_ITEMS.CENTER, background = COL.item })
    rowDemo:setWH(0, 48)
    for i = 1, 4 do rowDemo:addChild(TagSquare(tostring(i), i % 2 == 0 and COL.accent2 or COL.accent, 38, 38)) end
    p:addChild(Label("flex-direction: row          → 从左到右（默认）", { size = 15, color = COL.text }))
    p:addChild(rowDemo)

    local rrDemo = Box(P.FLEX_DIRECTION.ROW_REVERSE, { gap = 10, align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.FLEX_END, background = COL.item })
    rrDemo:setWH(0, 48)
    for i = 1, 4 do rrDemo:addChild(TagSquare(tostring(i), i % 2 == 0 and COL.accent2 or COL.accent, 38, 38)) end
    p:addChild(Label("flex-direction: row-reverse  ← 从右到左（顺序翻转）", { size = 15, color = COL.text }))
    p:addChild(rrDemo)

    -- column / column-reverse（竖排）
    local colDemo = Box(P.FLEX_DIRECTION.COLUMN, { gap = 8, align = P.ALIGN_ITEMS.CENTER, wh = { 200, 174 }, background = COL.item })
    colDemo.align_self = P.ALIGN_ITEMS.FLEX_START
    for i = 1, 4 do colDemo:addChild(TagSquare(tostring(i), i % 2 == 0 and COL.accent2 or COL.accent, 38, 38)) end
    p:addChild(Label("flex-direction: column       ↓ 从上到下", { size = 15, color = COL.text }))
    p:addChild(colDemo)

    local crDemo = Box(P.FLEX_DIRECTION.COLUMN, { gap = 8, align = P.ALIGN_ITEMS.CENTER, wh = { 200, 174 }, background = COL.item })
    crDemo.align_self = P.ALIGN_ITEMS.FLEX_START
    for i = 1, 4 do crDemo:addChild(TagSquare(tostring(i), i % 2 == 0 and COL.accent2 or COL.accent, 38, 38)) end
    p:addChild(Label("flex-direction: column-reverse ↑ 从下到上（顺序翻转）", { size = 15, color = COL.text }))
    p:addChild(crDemo)

    return p
end

---标签②：justify-content（6 种模式，带 ± 按钮调元素数）
local function buildJustify()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 10, padding = { 12, 16, 12, 16 } })
    p:addChild(Label("justify-content：主轴对齐方式（点 ± 改变元素数）", { size = 20, color = COL.title }))
    p:addChild(Label("剩余空间如何分配给子项间空隙。加到 6+ 个元素才能看出 space-between / evenly 的区别", { size = 14, color = COL.muted }))

    local modes = {
        { P.ALIGN_ITEMS.FLEX_START,    "贴起点靠左" },
        { P.ALIGN_ITEMS.FLEX_END,      "贴终点靠右" },
        { P.ALIGN_ITEMS.CENTER,        "整体居中" },
        { P.JUSTIFY_CONTENT.SPACE_BETWEEN, "首尾贴边中间等距" },
        { P.JUSTIFY_CONTENT.SPACE_AROUND,  "两侧等距端留半" },
        { P.JUSTIFY_CONTENT.SPACE_EVENLY,  "所有空隙含端相等" },
    }
    local jColors = { COL.accent, COL.accent2, COL.accent3, COL.title, COL.accent3, COL.accent2 }

    for idx, m in ipairs(modes) do
        -- 单行说明（不再用双 Label 行 → 彻底避免重叠）
        p:addChild(Label(("justify-content: %-14s → %s"):format(m[1], m[2]), { size = 15, color = COL.text }))

        -- ± 控制行
        local count = 4
        local ctrlRow = Box(P.FLEX_DIRECTION.ROW, { gap = 8, align = P.ALIGN_ITEMS.FLEX_START })
        local cntLbl = Label(("n=%d"):format(count), { size = 13, color = COL.muted })
        local btnMinus = Btn("－", nil, { size = 13, bg = COL.panel2 })
        local btnPlus = Btn("＋", nil, { size = 13, bg = COL.panel2 })
        ctrlRow:addChild(btnMinus); ctrlRow:addChild(cntLbl); ctrlRow:addChild(btnPlus)
        p:addChild(ctrlRow)

        -- demo 容器（宽度由 stretch 自动撑满，高度固定）
        local demo = Box(P.FLEX_DIRECTION.ROW, { justify = m[1], align = P.ALIGN_ITEMS.CENTER, gap = 6, background = COL.item })
        demo:setWH(0, 46)

        local function rebuildItems()
            local toRm = {}
            for _, ch in ipairs(demo.children) do if ch ~= demo._bg then table.insert(toRm, ch) end end
            for _, ch in ipairs(toRm) do demo:removeChild(ch) end
            for i = 1, count do
                local ci = (i - 1) % #jColors + 1
                demo:addChild(TagSquare(tostring(i), jColors[ci], 34, 34))
            end
            -- demo 使用 stretch 自适应宽度，只需重置高度防止被覆盖
            demo:setWH(0, 46)
            demo:setDirty()
        end
        rebuildItems()

        btnMinus.on_click = function()
            if count > 1 then count = count - 1; rebuildItems(); cntLbl:setText(("n=%d"):format(count)) end
        end
        btnPlus.on_click = function()
            if count < 12 then count = count + 1; rebuildItems(); cntLbl:setText(("n=%d"):format(count)) end
        end

        p:addChild(demo)
    end
    return p
end

---标签③：align-items / align-self / align-content
local function buildAlign()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 18, padding = { 12, 16, 12, 16 } })
    p:addChild(Label("align-items / align-self / align-content", { size = 20, color = COL.title }))

    -- § align-items：4 种模式（2×2 网格，避免单行过宽挤压）
    p:addChild(Label("align-items：交叉轴对齐（容器级）", { size = 16, color = COL.title }))
    local aiVariants = { P.ALIGN_ITEMS.STRETCH, P.ALIGN_ITEMS.FLEX_START, P.ALIGN_ITEMS.CENTER, P.ALIGN_ITEMS.FLEX_END }
    for rowIdx = 0, 1 do
        local gridRow = Box(P.FLEX_DIRECTION.ROW, { gap = 12, align = P.ALIGN_ITEMS.STRETCH, justify = P.ALIGN_ITEMS.CENTER })
        for colIdx = 1, 2 do
            local v = aiVariants[rowIdx * 2 + colIdx]
            local card = Box(P.FLEX_DIRECTION.COLUMN, { gap = 4, align = P.ALIGN_ITEMS.CENTER, padding = { 8, 10, 8, 10 },
                background = COL.item, wh = { 200, 130 } })
            card.align_self = P.ALIGN_ITEMS.FLEX_START
            local inner = Box(P.FLEX_DIRECTION.ROW, { align = v, gap = 6, wh = { 175, 85 }, background = COL.panel2 })
            inner.align_self = P.ALIGN_ITEMS.FLEX_START
            inner:addChild(TagSquare("A", COL.accent, 32, 28))
            inner:addChild(TagSquare("B", COL.accent2, 32, 56))
            inner:addChild(TagSquare("C", COL.accent3, 32, 42))
            card:addChild(inner)
            card:addChild(Label(v, { size = 15, color = COL.title }))
            gridRow:addChild(card)
        end
        p:addChild(gridRow)
    end

    -- § align-self
    p:addChild(Label("align-self：单项覆盖容器 align-items", { size = 16, color = COL.title }))
    p:addChild(Label("灰=stretch拉满 蓝=start 绿=center 橙=end", { size = 13, color = COL.muted }))
    local demo2 = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, gap = 10, background = COL.item })
    demo2:setWH(0, 52)
    local items_as = {
        { P.ALIGN_ITEMS.STRETCH, COL.muted,    P.ALIGN_ITEMS.STRETCH },
        { "start",  COL.accent,    P.ALIGN_ITEMS.FLEX_START },
        { P.ALIGN_ITEMS.CENTER, COL.accent3,   P.ALIGN_ITEMS.CENTER },
        { "end",    COL.accent2,   P.ALIGN_ITEMS.FLEX_END },
    }
    for _, it in ipairs(items_as) do
        local sq = TagSquare(it[1], it[2], 64, 40)
        sq.align_self = it[3]
        demo2:addChild(sq)
    end
    p:addChild(demo2)

    -- § align-content
    p:addChild(Label("align-content: space-between（多行分布）", { size = 16, color = COL.title }))
    local demo3 = Box(P.FLEX_DIRECTION.ROW, { wrap = P.FLEX_WRAP.WRAP, align_content = P.JUSTIFY_CONTENT.SPACE_BETWEEN, gap = 8, background = COL.item })
    demo3:setWH(0, 130)
    for i = 1, 10 do
        demo3:addChild(TagSquare(tostring(i), i % 2 == 0 and COL.accent2 or COL.accent, 56, 36))
    end
    p:addChild(demo3)

    return p
end

---标签④：flex-wrap / flex-grow / flex-basis
local function buildWrapGrow()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 18, padding = { 12, 16, 12, 16 } })
    p:addChild(Label("flex-wrap / flex-grow / flex-basis", { size = 20, color = COL.title }))

    -- § flex-wrap：3 种（横排排列，避免 column 嵌套重叠）
    p:addChild(Label("flex-wrap：换行行为（点 ± 改变元素数）", { size = 16, color = COL.title }))
    local wraps = { { P.FLEX_WRAP.NOWRAP, "不换行，溢出" }, { P.FLEX_WRAP.WRAP, "自动折行" }, { P.FLEX_WRAP.WRAP_REVERSE, "反向折行" } }

    for _, w in ipairs(wraps) do
        local wCount = 8
        local card = Box(P.FLEX_DIRECTION.COLUMN, { gap = 4, align = P.ALIGN_ITEMS.CENTER, padding = { 6, 8, 6, 8 },
            background = COL.item, wh = { 260, 150 } })
        card.align_self = P.ALIGN_ITEMS.FLEX_START
        local inner = Box(P.FLEX_DIRECTION.ROW, { wrap = w[1], gap = 5, wh = { 240, 105 }, background = COL.panel2 })
        inner.align_self = P.ALIGN_ITEMS.FLEX_START

        local function rebuildWrap()
            local toRm = {}
            for _, ch in ipairs(inner.children) do if ch ~= inner._bg then table.insert(toRm, ch) end end
            for _, ch in ipairs(toRm) do inner:removeChild(ch) end
            for i = 1, wCount do
                inner:addChild(TagSquare(tostring(i), i % 2 == 0 and COL.accent2 or COL.accent, 34, 34))
            end
            inner:setWH(240, 105)
            inner:setDirty()
        end
        rebuildWrap()

        card:addChild(inner)
        local ctrl = Box(P.FLEX_DIRECTION.ROW, { gap = 6, align = P.ALIGN_ITEMS.CENTER })
        local cntLbl = Label(("n=%d"):format(wCount), { size = 13, color = COL.muted })
        local btnMinus = Btn("－", function()
            if wCount > 1 then wCount = wCount - 1; rebuildWrap(); cntLbl:setText(("n=%d"):format(wCount)) end
        end, { size = 13, bg = COL.panel2 })
        local btnPlus = Btn("＋", function()
            if wCount < 16 then wCount = wCount + 1; rebuildWrap(); cntLbl:setText(("n=%d"):format(wCount)) end
        end, { size = 13, bg = COL.panel2 })
        ctrl:addChild(btnMinus); ctrl:addChild(cntLbl); ctrl:addChild(btnPlus)
        card:addChild(ctrl)
        card:addChild(Label(w[1], { size = 14, color = COL.title }))
        card:addChild(Label(w[2], { size = 12, color = COL.muted }))
        p:addChild(card)
    end

    -- § flex-grow
    p:addChild(Label("flex-grow：剩余宽度按比例分配（0 : 1 : 2）", { size = 16, color = COL.title }))
    local demo2 = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, gap = 8, background = COL.item })
    demo2:setWH(0, 52)
    local grows = { { 0, "grow:0" }, { 1, "grow:1" }, { 2, "grow:2" } }
    local gColors = { COL.accent, COL.accent2, COL.accent3 }
    for i, g in ipairs(grows) do
        local it = TagSquare(g[2], gColors[i], 60, 42)
        it.flex_grow = g[1]; it.flex_shrink = 1
        demo2:addChild(it)
    end
    p:addChild(demo2)

    -- § flex-basis
    p:addChild(Label("flex-basis：基础尺寸（支持 px 与百分比）", { size = 16, color = COL.title }))
    local demo3 = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, gap = 16, background = COL.item })
    demo3:setWH(0, 52)
    local b1 = TagSquare("basis 50%", COL.accent, 100, 42); b1.flex_basis = "50%"
    local b2 = TagSquare("basis 120px", COL.accent3, 100, 42); b2.flex_basis = 120
    demo3:addChild(b1); demo3:addChild(b2)
    p:addChild(demo3)

    return p
end

---标签⑤：order / gap / margin:auto
local function buildOrderGap()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 14, padding = { 12, 16, 12, 16 } })
    p:addChild(Label("order / gap / margin:auto", { size = 20, color = COL.title }))

    -- § order（带 ±）
    p:addChild(Label("order：视觉顺序（DOM 正序 + order 倒序）", { size = 16, color = COL.title }))
    local ordCount = 3
    local demo1 = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, gap = 8, background = COL.item })
    demo1:setWH(0, 50)

    local function rebuildOrder()
        local toRm = {}
        for _, ch in ipairs(demo1.children) do if ch ~= demo1._bg then table.insert(toRm, ch) end end
        for _, ch in ipairs(toRm) do demo1:removeChild(ch) end
        local letters = { "A", "B", "C", "D", "E", "F", "G", "H" }
        local oColors = { COL.accent, COL.accent2, COL.accent3, COL.title, COL.accent3, COL.accent2, COL.accent, COL.title }
        for i = 1, ordCount do
            local sq = TagSquare(letters[i] or tostring(i), oColors[i] or COL.accent, 40, 40)
            sq.order = (ordCount - i + 1)
            demo1:addChild(sq)
        end
        demo1:setDirty()
    end
    rebuildOrder()

    local ctrl1 = Box(P.FLEX_DIRECTION.ROW, { gap = 8, align = P.ALIGN_ITEMS.FLEX_START })
    local cnt1 = Label(("n=%d"):format(ordCount), { size = 13, color = COL.muted })
    ctrl1:addChild(Btn("－", function()
        if ordCount > 1 then ordCount = ordCount - 1; rebuildOrder(); cnt1:setText(("n=%d"):format(ordCount)) end
    end, { size = 14, bg = COL.panel2 }))
    ctrl1:addChild(cnt1)
    ctrl1:addChild(Btn("＋", function()
        if ordCount < 8 then ordCount = ordCount + 1; rebuildOrder(); cnt1:setText(("n=%d"):format(ordCount)) end
    end, { size = 14, bg = COL.panel2 }))
    p:addChild(ctrl1)
    p:addChild(demo1)
    p:addChild(Label("预期：显示顺序与添加顺序相反（最后添加的排最前）", { size = 13, color = COL.muted }))

    -- § gap
    p:addChild(Label("gap：row_gap=6 / column_gap=40（同行紧密、异行稀疏）", { size = 16, color = COL.title }))
    local gapCount = 10
    local demo2 = Box(P.FLEX_DIRECTION.ROW, { wrap = P.FLEX_WRAP.WRAP, gap = 6, background = COL.item })
    demo2:setWH(0, 130)
    demo2.row_gap = 6
    demo2.column_gap = 40

    local function rebuildGap()
        local toRm = {}
        for _, ch in ipairs(demo2.children) do if ch ~= demo2._bg then table.insert(toRm, ch) end end
        for _, ch in ipairs(toRm) do demo2:removeChild(ch) end
        for i = 1, gapCount do
            demo2:addChild(TagSquare(tostring(i), i % 2 == 0 and COL.accent2 or COL.accent, 44, 32))
        end
        demo2:setDirty()
    end
    rebuildGap()

    local ctrl2 = Box(P.FLEX_DIRECTION.ROW, { gap = 8, align = P.ALIGN_ITEMS.FLEX_START })
    local cnt2 = Label(("n=%d"):format(gapCount), { size = 13, color = COL.muted })
    ctrl2:addChild(Btn("－", function()
        if gapCount > 2 then gapCount = gapCount - 1; rebuildGap(); cnt2:setText(("n=%d"):format(gapCount)) end
    end, { size = 14, bg = COL.panel2 }))
    ctrl2:addChild(cnt2)
    ctrl2:addChild(Btn("＋", function()
        if gapCount < 20 then gapCount = gapCount + 1; rebuildGap(); cnt2:setText(("n=%d"):format(gapCount)) end
    end, { size = 14, bg = COL.panel2 }))
    p:addChild(ctrl2)
    p:addChild(demo2)

    -- § margin auto（3 例紧凑排列）
    p:addChild(Label("margin: auto 吸收剩余空间", { size = 16, color = COL.title }))
    local autoRow = Box(P.FLEX_DIRECTION.COLUMN, { gap = 14 })
    local autos = {
        { "margin-right:auto  → 靠左", { false, true } },
        { "margin:left:auto   → 靠右", { true,  false } },
        { "margin:both:auto   → 居中", { true,  true } },
    }
    for _, m in ipairs(autos) do
        local demo = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, background = COL.item })
        demo:setWH(0, 42)
        local box = TagSquare("box", COL.accent2, 72, 32)
        if m[2][1] then box.margin[4] = UI.Layout.Flex.AUTO end
        if m[2][2] then box.margin[2] = UI.Layout.Flex.AUTO end
        demo:addChild(box)
        p:addChild(Label(m[1], { size = 14, color = COL.text }))
        p:addChild(demo)
    end

    return p
end

---标签⑥：position / z-index / display
local function buildPosZ()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 14, padding = { 12, 16, 12, 16 } })
    p:addChild(Label("position / z-index / display", { size = 20, color = COL.title }))

    -- relative
    p:addChild(Label("position: relative — 保留占位 + inset 偏移", { size = 16, color = COL.title }))
    local demo1 = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, gap = 10, background = COL.item })
    demo1:setWH(0, 60)
    demo1:addChild(TagSquare("正常流元素", COL.accent, 60, 44))
    local rel = TagSquare("relative 偏移+24,+16", COL.accent2, 140, 44)
    rel.position = P.POSITION.RELATIVE; rel.inset_left = 24; rel.inset_top = 16
    demo1:addChild(rel)
    p:addChild(demo1)

    -- absolute + z-index
    p:addChild(Label("position: absolute + z-index — 脱离文档流浮层", { size = 16, color = COL.title }))
    local demo2 = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, background = COL.item })
    demo2:setWH(0, 70)
    demo2:addChild(TagSquare("底层元素 (宽144)", COL.accent, 140, 56))
    local badge = TagSquare("NEW\nz=10", COL.accent2, 76, 36)
    badge.position = P.POSITION.ABSOLUTE; badge.inset_top = 16; badge.inset_right = 180; badge:setZIndex(10)
    demo2:addChild(badge)
    p:addChild(demo2)
    p:addChild(Label("预期：红块(z=10)盖在蓝块之上", { size = 13, color = COL.muted }))

    -- display toggle
    p:addChild(Label("display: none/flex 切换 — 点击按钮显隐右侧元素", { size = 16, color = COL.title }))
    local demo3 = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, gap = 12, background = COL.item })
    demo3:setWH(0, 52)
    local toggle = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, padding = { 6, 14, 6, 14 },
        background = COL.accent, hover_color = C(120, 170, 240), hover_scale = 1.05 })
    toggle:addChild(Label("toggle 显隐", { size = 16, color = C(255, 255, 255) }))
    local target = TagSquare("被切换的元素", COL.accent3, 170, 42)
    demo3:addChild(toggle)
    demo3:addChild(target)
    toggle.on_click = function()
        target.display = (target.display == P.DISPLAY.NONE) and P.DISPLAY.FLEX or P.DISPLAY.NONE
        target:setDirty()
    end
    p:addChild(demo3)

    return p
end

---标签⑦：gradient + hover
local function buildGradientHover()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 14, padding = { 12, 16, 12, 16 } })
    p:addChild(Label("gradient 渐变 + hover 悬停动效", { size = 20, color = COL.title }))

    -- 渐变
    p:addChild(Label("setGradient：线性渐变（h=水平 v=垂直 d=对角）", { size = 16, color = COL.title }))
    local gradRow = Box(P.FLEX_DIRECTION.ROW, { gap = 16, align = P.ALIGN_ITEMS.CENTER })
    local grads = {
        { "h 水平", { C(120, 200, 160), C(70, 150, 200), "h" } },
        { "v 垂直", { C(220, 140, 90),  C(180, 70, 120),  "v" } },
        { "d 对角", { C(120, 200, 255), C(220, 120, 70),  "d" } },
    }
    for _, g in ipairs(grads) do
        local card = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, wh = { 220, 80 }, gradient = g[2] })
        card.align_self = P.ALIGN_ITEMS.FLEX_START
        card:addChild(Label(g[1], { size = 18, color = C(255, 255, 255) }))
        gradRow:addChild(card)
    end
    p:addChild(gradRow)

    -- 悬停
    p:addChild(Label(":hover — 光标移入放大+变亮，移出恢复", { size = 16, color = COL.title }))
    local demo2 = Box(P.FLEX_DIRECTION.ROW, { gap = 20, align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, background = COL.item })
    demo2:setWH(0, 80)
    local pill = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, padding = { 10, 22, 10, 22 }, wh = { 170, 50 },
        gradient = { C(120, 200, 160), C(70, 150, 200), "h" },
        hover_color = C(180, 245, 205), hover_scale = 1.08 })
    pill:addChild(Label("悬停我 ↑", { size = 20, color = C(255, 255, 255) }))
    demo2:addChild(pill)
    p:addChild(demo2)

    return p
end

---标签⑧：模拟网页作品集（类 www.bugoostudio.com/works）
local function buildWorksPage()
    local p = Box(P.FLEX_DIRECTION.COLUMN, { gap = 12, padding = { 12, 16, 12, 16 } })

    -- § 顶部网站导航条（模拟 bugostudio 顶栏）
    local nav = Box(P.FLEX_DIRECTION.ROW, { justify = P.JUSTIFY_CONTENT.SPACE_BETWEEN, align = P.ALIGN_ITEMS.CENTER, padding = { 0, 18, 0, 18 },
        gradient = { C(28, 32, 42), C(42, 50, 64), "h" } })
    nav:setWH(0, 46)
    local brand = Box(P.FLEX_DIRECTION.ROW, { gap = 8, align = P.ALIGN_ITEMS.CENTER })
    brand:addChild(Swatch(18, 18, COL.accent))
    brand:addChild(Label("布谷工作室 BUGOO", { size = 19, color = COL.title }))
    nav:addChild(brand)
    local menu = Box(P.FLEX_DIRECTION.ROW, { gap = 22, align = P.ALIGN_ITEMS.CENTER })
    for _, t in ipairs({ "首页", "作品库", "游戏", "关于", "联系" }) do
        menu:addChild(Label(t, { size = 15, color = (t == "作品库") and COL.accent or COL.text }))
    end
    nav:addChild(menu)
    p:addChild(nav)

    -- § Hero 标题区
    local hero = Box(P.FLEX_DIRECTION.COLUMN, { gap = 6, align = P.ALIGN_ITEMS.FLEX_START })
    hero:addChild(Label("作品库 · Works", { size = 30, color = COL.title }))
    hero:addChild(Label("布谷工作室 — 独立游戏开发与发行作品展示", { size = 15, color = COL.muted }))
    p:addChild(hero)

    -- § 筛选标签
    local filters = Box(P.FLEX_DIRECTION.ROW, { gap = 8, align = P.ALIGN_ITEMS.CENTER })
    local ftabs = { "全部", "正式上架", "开发阶段", "提供试玩", "小游戏" }
    for i, f in ipairs(ftabs) do
        local chip = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, padding = { 5, 14, 5, 14 },
            background = (i == 1) and COL.accent or COL.item, hover_color = COL.accent2, hover_scale = 1.05 })
        chip:addChild(Label(f, { size = 14, color = (i == 1) and C(255, 255, 255) or COL.text }))
        filters:addChild(chip)
    end
    p:addChild(filters)

    -- § 作品网格
    p:addChild(Label("精选作品（点击卡片选中）", { size = 18, color = COL.title }))
    local grid = Box(P.FLEX_DIRECTION.ROW, { wrap = P.FLEX_WRAP.WRAP, gap = 16, justify = P.ALIGN_ITEMS.FLEX_START, align = P.ALIGN_ITEMS.FLEX_START })
    grid:setWH(0, 416)
    local works = {
        { "Project Alpha",   "A clicker game about physics evolution",           "Simulation",     "2026", "Released", COL.accent },
        { "Project Beta",    "Visual novel meets card roguelike gameplay",        "Unity Roguelike","2026", "In Dev",   COL.accent3 },
        { "Project Gamma",   "Platformer with mouse-driven magic system",         "Platformer 2D",  "2026", "Demo",     COL.accent2 },
        { "Project Delta",   "High-speed one-hit-kill action shooter",            "Action Shooter", "2026", "Demo",     COL.accent2 },
        { "Project Epsilon", "Collect magic items and battle powerful enemies",   "GameMaker 2D",   "2025", "Released", COL.accent },
        { "Project Zeta",    "Puzzle game combining illusion and one-stroke draw", "Puzzle 2D",      "2024", "Award",    COL.accent },
    }
    local cardW, cardH = 320, 200
    for _, w in ipairs(works) do
        local card = Box(P.FLEX_DIRECTION.COLUMN, { gap = 0, align = P.ALIGN_ITEMS.STRETCH, padding = { 0, 0, 0, 0 },
            background = COL.item, hover_color = COL.panel2, hover_scale = 1.04 })
        card:setWH(cardW, cardH)

        -- 缩略图占位（渐变 + 首字母）
        local thumb = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, wh = { cardW, 90 }, gradient = { w[6], C(26, 30, 40), "v" } })
        thumb.align_self = P.ALIGN_ITEMS.FLEX_START
        thumb:addChild(Label(w[1]:sub(1, 1), { size = 42, color = C(255, 255, 255) }))
        card:addChild(thumb)

        -- 内容区
        local body = Box(P.FLEX_DIRECTION.COLUMN, { gap = 6, align = P.ALIGN_ITEMS.FLEX_START, padding = { 8, 10, 8, 10 }, wh = { cardW, cardH - 90 } })
        body.align_self = P.ALIGN_ITEMS.FLEX_START
        local topRow = Box(P.FLEX_DIRECTION.ROW, { justify = P.JUSTIFY_CONTENT.SPACE_BETWEEN, align = P.ALIGN_ITEMS.CENTER })
        local badge = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, padding = { 2, 8, 2, 8 }, background = COL.accent2 })
        badge:addChild(Label(w[5], { size = 12, color = C(255, 255, 255) }))
        topRow:addChild(badge)
        topRow:addChild(Label(w[4], { size = 13, color = COL.muted }))
        body:addChild(topRow)
        body:addChild(Label(w[1], { size = 17, color = COL.text }))
        body:addChild(Label(w[2], { size = 12, color = COL.muted }))
        local cat = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, padding = { 3, 10, 3, 10 }, background = COL.panel2 })
        cat:addChild(Label(w[3], { size = 12, color = COL.accent3 }))
        body:addChild(cat)
        card:addChild(body)

        -- 点击选中（高亮背景）
        local selected = false
        card.on_click = function()
            selected = not selected
            if card._bg then card._bg:setState(Render.BlendMode.Default, selected and COL.navActive or COL.item) end
        end

        grid:addChild(card)
    end
    p:addChild(grid)

    p:addChild(Label("↑ 模拟 www.bugoostudio.com/works — 纯 CSS Flex 布局实现", { size = 13, color = COL.muted }))
    return p
end

-- ════════════════════════════════════════════════════════════
-- § 递归脏标记（display 切换后必须递归到叶子节点）
-- ════════════════════════════════════════════════════════════

---@param node Core.UI.Child
local function deepSetDirty(node)
    node:setDirty()
    if node.children then
        for _, ch in ipairs(node.children) do
            if ch ~= node._bg then
                deepSetDirty(ch)
            end
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- § 主构建
-- ════════════════════════════════════════════════════════════

function M.Main(scene)
    local root = UI.Manager.CreateHUDRoot("Test.UITest", 1)
    local view = UI.Camera:getView()
    local ui = { root = root }

    -- 全屏应用容器
    local app = Box(P.FLEX_DIRECTION.COLUMN, { background = COL.bg })
    app:setPos(view.centerX, view.centerY)
    app:setWH(view.width, view.height)
    root:addChild(app)
    ui.app = app

    -- 标题栏
    local titlebar = Box(P.FLEX_DIRECTION.ROW, { justify = P.JUSTIFY_CONTENT.SPACE_BETWEEN, align = P.ALIGN_ITEMS.CENTER, padding = { 0, 16, 0, 16 },
        gradient = { C(42, 48, 60), C(26, 30, 40), "v" } })
    titlebar:setWH(view.width, 52)
    local title = Label("CSS Flex UI · 2D 布局测试场", { size = 24, color = COL.title })
    local right = Box(P.FLEX_DIRECTION.ROW, { gap = 12, align = P.ALIGN_ITEMS.CENTER })
    local fps = Label("FPS --", { size = 18, color = COL.accent3 })
    local helpBtn = Box(P.FLEX_DIRECTION.ROW, { align = P.ALIGN_ITEMS.CENTER, justify = P.ALIGN_ITEMS.CENTER, padding = { 5, 12, 5, 12 },
        gradient = { C(120, 170, 240), C(70, 120, 200), "h" },
        hover_color = C(150, 200, 255), hover_scale = 1.05 })
    helpBtn:addChild(Label("帮助", { size = 18 }))
    helpBtn.on_click = function(node, btn)
        ui.modal.display = P.DISPLAY.FLEX; ui.app:setDirty()
    end
    right:addChild(fps); right:addChild(helpBtn)
    titlebar:addChild(title); titlebar:addChild(right)
    app:addChild(titlebar)
    ui.fps = fps; ui.helpBtn = helpBtn; ui.title = title

    -- 主体：左右分栏
    local body = Box(P.FLEX_DIRECTION.ROW, { gap = 10, padding = { 10, 10, 10, 10 }, align = P.ALIGN_ITEMS.STRETCH })
    body.flex_grow = 1
    app:addChild(body)
    ui.body = body

    -- 侧边栏
    local sidebar = Box(P.FLEX_DIRECTION.COLUMN, { gap = 5, padding = { 8, 8, 8, 8 }, background = COL.panel })
    sidebar:setWH(190, 0)
    sidebar:addChild(Label("布局属性 ▾", { size = 17, color = COL.muted }))
    body:addChild(sidebar)
    ui.sidebar = sidebar

    -- 主内容区
    local main = Box(P.FLEX_DIRECTION.COLUMN, { gap = 0, align = P.ALIGN_ITEMS.STRETCH, padding = { 0, 0, 0, 0 } })
    main.flex_grow = 1
    body:addChild(main)
    ui.main = main

    -- 7 个标签面板
    local builders = { buildDirection, buildJustify, buildAlign, buildWrapGrow, buildOrderGap, buildPosZ, buildGradientHover, buildWorksPage }
    local tabNames = { "①方向", "②主轴", "③交叉", "④换行", "⑤顺序", "⑥定位", "⑦渐变", "⑧作品" }
    ui.panels = {}
    ui.navItems = {}
    for i, builder in ipairs(builders) do
        local panel = builder()
        panel.display = (i == 1) and P.DISPLAY.FLEX or P.DISPLAY.NONE
        main:addChild(panel)
        ui.panels[i] = panel

        local nav = Box(P.FLEX_DIRECTION.ROW, { gap = 5, align = P.ALIGN_ITEMS.CENTER, padding = { 5, 7, 5, 7 },
            background = (i == 1) and COL.navActive or COL.item, hover_color = C(58, 66, 84) })
        nav:addChild(Swatch(7, 7, COL.accent))
        nav:addChild(Label(tabNames[i], { size = 15 }))
        local idx = i
        nav.on_click = function() M.SetTab(ui, idx) end
        sidebar:addChild(nav)
        ui.navItems[i] = nav
    end

    ui._tabIdx = 1

    -- 状态栏
    local statusbar = Box(P.FLEX_DIRECTION.ROW, { justify = P.ALIGN_ITEMS.CENTER, align = P.ALIGN_ITEMS.CENTER, padding = { 0, 16, 0, 16 }, background = COL.panel })
    statusbar:setWH(view.width, 28)
    statusbar:addChild(Label("←/→ 切标签 · 点击导航 · M 模态框 · ± 增减 · 光标悬停看动效", { size = 13, color = COL.muted }))
    app:addChild(statusbar)

    -- 模态框
    local modal = Box(P.FLEX_DIRECTION.COLUMN, {
        position = P.POSITION.ABSOLUTE, inset = { 0, 0, 0, 0 },
        justify = P.ALIGN_ITEMS.CENTER, align = P.ALIGN_ITEMS.CENTER,
        display = P.DISPLAY.NONE, z = 100, background = C(0, 0, 0, 170),
    })
    local dialog = Box(P.FLEX_DIRECTION.COLUMN, { gap = 12, align = P.ALIGN_ITEMS.CENTER, padding = { 18, 22, 18, 22 }, background = COL.panel2, wh = { 400, 200 } })
    dialog:addChild(Label("模态框", { size = 26, color = COL.title }))
    dialog:addChild(Label("absolute + z-index:100 + display 切换", { size = 16, color = COL.muted }))
    dialog:addChild(Label("点击背景或按 M 关闭", { size = 18 }))
    dialog.on_click = function() end
    modal:addChild(dialog)
    app:addChild(modal)
    ui.modal = modal
    modal._bg.on_click = function(node, btn)
        ui.modal.display = P.DISPLAY.NONE; ui.app:setDirty()
    end

    scene.ui = ui
    return root
end

function M.SetTab(ui, idx)
    if not ui.panels then return end
    idx = ((idx - 1) % #ui.panels) + 1
    for j, panel in ipairs(ui.panels) do
        panel.display = (j == idx) and P.DISPLAY.FLEX or P.DISPLAY.NONE
    end
    for j, nav in ipairs(ui.navItems) do
        if nav._bg then nav._bg:setState(Render.BlendMode.Default, (j == idx) and COL.navActive or COL.item) end
    end
    ui.title:setText(("CSS Flex UI · 2D 布局测试场 — 标签%d/%d"):format(idx, #ui.panels))
    -- 关键修复：display 切换后必须整条链 + 递归子树 deepSetDirty
    -- 单层 setDirty 不递归到深层嵌套叶子（card→inner→TagSquare→Label）
    ui.main:setDirty()
    ui.body:setDirty()
    ui.app:setDirty()
    local activePanel = ui.panels[idx]
    if activePanel then deepSetDirty(activePanel) end
end

function M.Frame(scene)
    local ui = scene.ui
    if not ui then return end

    local view = UI.Camera:getView()
    ui.app:setPos(view.centerX, view.centerY)
    ui.app:setWH(view.width, view.height)
    ui.fps:setText(("FPS %.1f"):format(lstg.GetFPS()))

    -- 鼠标悬停
    local Mouse = Core.Input.Mouse
    local mx, my = Mouse.GetPosition(UI.Camera)
    Core.UI.Child.UpdateHover(ui.app, mx, my)

    -- 键盘
    local K = Core.Input.Keyboard.Key
    if Core.Input.IsDown(K.M) then
        if not ui._mHeld then
            ui._mHeld = true
            ui.modal.display = (ui.modal.display == P.DISPLAY.NONE) and P.DISPLAY.FLEX or P.DISPLAY.NONE
            ui.app:setDirty()
        end
    else ui._mHeld = false end

    local arrows = { [K.Left] = -1, [K.Right] = 1 }
    for key, delta in pairs(arrows) do
        if Core.Input.IsDown(key) then
            if not ui._arrowHeld then
                ui._arrowHeld = true
                local cur = 1
                for j, p in ipairs(ui.panels) do if p.display ~= P.DISPLAY.NONE then cur = j end end
                M.SetTab(ui, cur + delta)
            end
        end
    end
    if not (Core.Input.IsDown(K.Left) or Core.Input.IsDown(K.Right)) then ui._arrowHeld = false end

    -- 鼠标点击
    if Mouse.IsUp(Mouse.Key.Left) then
        local hit = ui.app:hitTestDeep(mx, my)
        if hit and hit.on_click then
            hit:on_click(hit, Mouse.Key.Left)
        end
    end
end
