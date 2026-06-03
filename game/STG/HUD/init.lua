---@class STG.HUD
---Side-panel HUD for STG gameplay. Renders score, lives, bombs, power, graze
---in the right-side panel of the game window.
---
---Coordinate system: Core.UI.Camera space (origin = bottom-left, range = sw x sh).
---Panel coordinates come from Layout.GetPanelRect which maps physical pixels
---to logical screen coordinates via px_to_lx/px_to_ly.
local M = {}
STG.HUD = M

local Render = Core.Render
local Run = STG.Run
local Player = STG.Player

-- ============================================================
-- Helpers
-- ============================================================

local function getResource()
    local p = Player.Get()
    if not p or not p.sys then return nil end
    return p.sys.component_sys:getComponent("Resource")
end

local function getRun()
    local run = Run.Get()
    if not run then return nil end
    return run:getViewData()
end

local function fmt(n)
    if not n or n == 0 then return "0" end
    local neg = n < 0
    n = math.floor(math.abs(n))
    local s = tostring(n)
    -- Insert commas every 3 digits from right
    local result = ""
    local count = 0
    for i = #s, 1, -1 do
        result = s:sub(i, i) .. result
        count = count + 1
        if count % 3 == 0 and i > 1 then
            result = "," .. result
        end
    end
    return neg and ("-" .. result) or result
end

-- ============================================================
-- Side-panel HUD
-- ============================================================

---Create a side-panel HUD on a UI root.
---@param root Core.UI.Root
---@param panel table { left, right, bottom, top, centerX, centerY }
function M.CreateSidePanel(root, panel)
    local cx = panel.centerX
    local left = panel.left + 10
    local right = panel.right - 10
    local top = panel.top - 10
    local bottom = panel.bottom + 10
    local mid_y = (top + bottom) / 2

    -- Title bar
    root:addChild(Core.UI.Immediate("hud_bg_title", 0, function()
        Render.Draw.SetState(Render.BlendMode.Default, Render.Color(40, 80, 100, 120))
        Render.Draw.Rect(panel.left, panel.right, top, top + 30)
    end))

    root:addChild(Core.UI.Immediate("hud_title", 0, function()
        Render.Utils.SimpleTTF("exo2", "STATUS", cx, top + 14, 0.28,
            Render.Color.ARGB(200, 200, 220, 240), "center")
    end))

    -- Separator after title
    root:addChild(Core.UI.Immediate("hud_sep_title", 0, function()
        Render.Draw.SetState(Render.BlendMode.Default, Render.Color(60, 120, 150, 160))
        Render.Draw.Rect(left, right, top - 2, top)
    end))

    -- Score section
    local y = top - 25

    root:addChild(Core.UI.Immediate("hud_score_label", 0, function()
        Render.Utils.SimpleTTF("exo2", "Score", cx, y, 0.22,
            Render.Color.ARGB(140, 180, 190, 210), "center")
    end))

    root:addChild(Core.UI.Immediate("hud_score_val", 0, function()
        local vd = getRun()
        local score = vd and vd.score or 0
        Render.Utils.SimpleTTF("exo2", fmt(score), cx, y - 22, 0.38,
            Render.Color.White, "center")
    end))

    y = y - 52
    root:addChild(Core.UI.Immediate("hud_hiscore_label", 0, function()
        Render.Utils.SimpleTTF("exo2", "HiScore", cx, y, 0.22,
            Render.Color.ARGB(120, 200, 180, 120), "center")
    end))

    root:addChild(Core.UI.Immediate("hud_hiscore_val", 0, function()
        local vd = getRun()
        local hiscore = vd and vd.score or 0  -- Use current score as hiscore for now
        Render.Utils.SimpleTTF("exo2", fmt(hiscore), cx, y - 22, 0.35,
            Render.Color.ARGB(160, 255, 215, 0), "center")
    end))

    -- Separator
    y = y - 48
    root:addChild(Core.UI.Immediate("hud_sep1", 0, function()
        Render.Draw.SetState(Render.BlendMode.Default, Render.Color(40, 100, 120, 140))
        Render.Draw.Rect(left, right, y, y + 1)
    end))

    -- Power section
    y = y - 25
    root:addChild(Core.UI.Immediate("hud_power_label", 0, function()
        Render.Utils.SimpleTTF("exo2", "Power", cx, y, 0.22,
            Render.Color.ARGB(140, 220, 160, 220), "center")
    end))

    root:addChild(Core.UI.Immediate("hud_power_val", 0, function()
        local r = getResource()
        local power = r and r:getPower() or 0
        Render.Utils.SimpleTTF("exo2", string.format("%.2f", power), cx, y - 22, 0.42,
            Render.Color.ARGB(220, 255, 130, 255), "center")
    end))

    -- Lives section
    y = y - 52
    root:addChild(Core.UI.Immediate("hud_lives_label", 0, function()
        Render.Utils.SimpleTTF("exo2", "Lives", cx, y, 0.22,
            Render.Color.ARGB(140, 220, 160, 160), "center")
    end))

    root:addChild(Core.UI.Immediate("hud_lives_val", 0, function()
        local r = getResource()
        local lives = r and r:getLives() or 0
        Render.Utils.SimpleTTF("exo2", tostring(lives), cx, y - 22, 0.45,
            Render.Color.ARGB(220, 255, 110, 110), "center")
    end))

    -- Bombs section
    y = y - 52
    root:addChild(Core.UI.Immediate("hud_bombs_label", 0, function()
        Render.Utils.SimpleTTF("exo2", "Bombs", cx, y, 0.22,
            Render.Color.ARGB(140, 160, 220, 160), "center")
    end))

    root:addChild(Core.UI.Immediate("hud_bombs_val", 0, function()
        local r = getResource()
        local bombs = r and r:getBombs() or 0
        Render.Utils.SimpleTTF("exo2", tostring(bombs), cx, y - 22, 0.45,
            Render.Color.ARGB(220, 110, 255, 110), "center")
    end))

    -- Separator
    y = y - 48
    root:addChild(Core.UI.Immediate("hud_sep2", 0, function()
        Render.Draw.SetState(Render.BlendMode.Default, Render.Color(40, 100, 120, 140))
        Render.Draw.Rect(left, right, y, y + 1)
    end))

    -- Graze section
    y = y - 25
    root:addChild(Core.UI.Immediate("hud_graze_label", 0, function()
        Render.Utils.SimpleTTF("exo2", "Graze", cx, y, 0.22,
            Render.Color.ARGB(140, 180, 180, 200), "center")
    end))

    root:addChild(Core.UI.Immediate("hud_graze_val", 0, function()
        local r = getResource()
        local graze = r and r:getGraze() or 0
        Render.Utils.SimpleTTF("exo2", tostring(graze), cx, y - 22, 0.38,
            Render.Color.White, "center")
    end))

    -- FPS at bottom
    root:addChild(Core.UI.Immediate("hud_fps", 0, function()
        Render.Utils.SimpleTTF("exo2", string.format("%.0f fps", lstg.GetFPS()),
            cx, bottom + 10, 0.2,
            Render.Color.ARGB(80, 140, 150, 160), "center")
    end))
end

return M
