---@class STG.Menu.Title
---Title menu scene: Title → Difficulty → Character → Start.
---Configure DIFFICULTIES, CHARACTERS, and OnStart before calling NewScene().
local M = {}
STG.Menu.Title = M

local Render = Core.Render
local Input = Core.Input

-- ============================================================
-- Configurable by game module (Main)
-- ============================================================

M.DIFFICULTIES = { "EASY", "NORMAL", "HARD", "LUNATIC" }
M.DIFFICULTY_LABELS = {
    EASY = "Easy", NORMAL = "Normal", HARD = "Hard", LUNATIC = "Lunatic",
}
M.CHARACTERS = {
    { name = "Reimu", profile = nil },
}
---Called when player selects character and starts.
---@type fun(difficulty:string, character_index:number)
M.OnStart = nil

-- ============================================================
-- Title items (can be overridden)
-- ============================================================

function M.BuildTitleItems()
    return {
        { label = "Start Game",  onSelect = function() return "difficulty" end },
        { label = "Replay",      disabled = true },
        { label = "Settings",    disabled = true },
        { label = "Quit",        onSelect = function() Core.MainLoop.ExitGame() end },
    }
end

-- ============================================================
-- Scene
-- ============================================================

function M.NewScene()
    local scene = Core.SceneManager.NewScene("STG.Menu.Title")
    local _selected_diff = 2
    local _selected_char = 1

    local current_page = { name = "title", items = M.BuildTitleItems(), selected = 1 }
    local confirm_timer = 0
    local title_nodes, item_nodes = {}, {}
    local page_title_node, desc_node = nil, nil

    local function clearNodes()
        if not scene.hud_root then return end
        for _, n in ipairs(title_nodes) do scene.hud_root:removeChild(n) end
        for _, n in ipairs(item_nodes) do scene.hud_root:removeChild(n) end
        if page_title_node then scene.hud_root:removeChild(page_title_node); page_title_node = nil end
        if desc_node then scene.hud_root:removeChild(desc_node); desc_node = nil end
        title_nodes, item_nodes = {}, {}
    end

    local function buildDifficultyItems()
        local items = {}
        for i, diff in ipairs(M.DIFFICULTIES) do
            local di = i
            items[i] = {
                label = M.DIFFICULTY_LABELS[diff] or diff,
                onSelect = function() _selected_diff = di; return "character" end,
            }
        end
        return items
    end

    local function buildCharacterItems()
        local items = {}
        for i, char in ipairs(M.CHARACTERS) do
            local ci = i
            items[i] = {
                label = char.name,
                onSelect = function()
                    _selected_char = ci
                    return "start"
                end,
            }
        end
        return items
    end

    local function buildTitlePageUI()
        clearNodes()
        local hud = Core.UI.Camera:getView()
        local cx, cy = hud.centerX, hud.centerY

        local function addStatic(text, size, x, y, color)
            local t = Core.UI.Text():setText(text):setFont("exo2"):setSize(size):setPos(x, y):setColor(color)
            scene.hud_root:addChild(t)
            title_nodes[#title_nodes + 1] = t
            return t
        end

        addStatic("LuaSTG Cyanlib", 72, cx, cy + 160, Render.Color.White)
        addStatic("STG Module Test", 26, cx, cy + 120, Render.Color.ARGB(180, 180, 200, 220))
        addStatic("v1.0.0  --  Cyanlib STG Module", 14, cx, cy - 250, Render.Color.ARGB(60, 120, 140, 160))

        for i, item in ipairs(current_page.items) do
            local is_sel = (i == current_page.selected)
            local item_y = cy - (i - 1) * 52
            local text = is_sel and (">  " .. item.label .. "  <") or ("   " .. item.label)
            local color = item.disabled and Render.Color.ARGB(60, 70, 80, 90)
                or (is_sel and Render.Color.White or Render.Color.ARGB(140, 160, 180, 200))
            local size = is_sel and 32 or 28
            local t = Core.UI.Text():setText(text):setFont("exo2"):setSize(size):setPos(cx, item_y):setColor(color)
            scene.hud_root:addChild(t)
            item_nodes[i] = t
        end
    end

    local function buildSelectPageUI()
        clearNodes()
        local hud = Core.UI.Camera:getView()
        local cx, cy = hud.centerX, hud.centerY

        page_title_node = Core.UI.Text():setText(current_page.title):setFont("exo2")
            :setSize(52):setPos(cx, cy + 160):setColor(Render.Color.White)
        scene.hud_root:addChild(page_title_node)

        for i, item in ipairs(current_page.items) do
            local is_sel = (i == current_page.selected)
            local item_y = cy + 50 - (i - 1) * 54
            local text = is_sel and (">  " .. item.label .. "  <") or ("   " .. item.label)
            local color = is_sel and Render.Color.White or Render.Color.ARGB(140, 160, 180, 200)
            local size = is_sel and 32 or 28
            local t = Core.UI.Text():setText(text):setFont("exo2"):setSize(size):setPos(cx, item_y):setColor(color)
            scene.hud_root:addChild(t)
            item_nodes[i] = t
        end

        if current_page.name == "difficulty" and current_page.selected then
            local diff_desc = {
                "For beginners -- relaxed patterns",
                "Standard challenge -- balanced patterns",
                "For experts -- dense, fast patterns",
                "You are not expected to survive",
            }
            desc_node = Core.UI.Text():setText(diff_desc[current_page.selected] or "")
                :setFont("exo2"):setSize(14):setPos(cx, cy - 180)
                :setColor(Render.Color.ARGB(80, 130, 150, 180))
            scene.hud_root:addChild(desc_node)
        end
    end

    local function refreshItemHighlights()
        for i, item in ipairs(current_page.items) do
            local node = item_nodes[i]
            if node then
                local is_sel = (i == current_page.selected)
                local text = is_sel and (">  " .. item.label .. "  <") or ("   " .. item.label)
                local color = item.disabled and Render.Color.ARGB(60, 70, 80, 90)
                    or (is_sel and Render.Color.White or Render.Color.ARGB(140, 160, 180, 200))
                local size = is_sel and 32 or 28
                node:setText(text):setColor(color):setSize(size)
            end
        end
        if desc_node and current_page.name == "difficulty" then
            local diff_desc = {
                "For beginners -- relaxed patterns",
                "Standard challenge -- balanced patterns",
                "For experts -- dense, fast patterns",
                "You are not expected to survive",
            }
            desc_node:setText(diff_desc[current_page.selected] or "")
        end
    end

    local function switchPage(name)
        if name == "title" then
            current_page = { name = "title", items = M.BuildTitleItems(), selected = 1 }
            buildTitlePageUI()
        elseif name == "difficulty" then
            current_page = { name = "difficulty", title = "Select Difficulty",
                items = buildDifficultyItems(), selected = _selected_diff }
            buildSelectPageUI()
        elseif name == "character" then
            current_page = { name = "character", title = "Select Character",
                items = buildCharacterItems(), selected = _selected_char }
            buildSelectPageUI()
        elseif name == "start" then
            if M.OnStart then
                M.OnStart(M.DIFFICULTIES[_selected_diff], _selected_char)
            end
        end
    end

    function scene:init()
        self.hud_root = Core.UI.Manager.CreateHUDRoot("STG.Menu.Title", 1)

        self._bg_immediate = Core.UI.Immediate("menu_bg", -1, function()
            local hud = Core.UI.Camera:getView()
            local cx, cy = hud.centerX, hud.centerY
            local hw, hh = hud.width / 2, hud.height / 2

            Render.Draw.SetState(Render.BlendMode.Default, Render.Color(22, 6, 8, 50))
            Render.Draw.Rect(cx - hw, cx + hw, cy - hh, cy + hh)

            local line_y = cy + 102
            Render.Draw.SetState(Render.BlendMode.Default, Render.Color(180, 100, 140, 180))
            Render.Draw.Rect(cx - 150, cx + 150, line_y, line_y + 2)

            local fy = cy - 210
            local fsize = 0.28
            if current_page.name == "title" then
                Render.Utils.SimpleTTF("exo2", "Z: Confirm    Arrow Keys: Navigate",
                    cx, fy, fsize, Render.Color.ARGB(80, 150, 150, 150), "center")
            elseif current_page.name == "character" then
                Render.Utils.SimpleTTF("exo2", "Z: Start Game    X: Back",
                    cx, fy, fsize, Render.Color.ARGB(80, 150, 150, 150), "center")
            else
                Render.Utils.SimpleTTF("exo2", "Z: Select    X: Back",
                    cx, fy, fsize, Render.Color.ARGB(80, 150, 150, 150), "center")
            end
        end)
        self.hud_root:addChild(self._bg_immediate)

        buildTitlePageUI()
    end

    function scene:frame()
        if confirm_timer > 0 then confirm_timer = confirm_timer - 1; return end
        local items = current_page.items
        local sel = current_page.selected

        if Input.IsDown(Input.Keyboard.Key.Up) then
            repeat sel = sel - 1; if sel < 1 then sel = #items end until not items[sel].disabled
            current_page.selected = sel
            refreshItemHighlights()
        elseif Input.IsDown(Input.Keyboard.Key.Down) then
            repeat sel = sel + 1; if sel > #items then sel = 1 end until not items[sel].disabled
            current_page.selected = sel
            refreshItemHighlights()
        elseif Input.IsDown(Input.Keyboard.Key.Z) then
            local item = items[sel]
            if item and not item.disabled and item.onSelect then
                confirm_timer = 15
                switchPage(item.onSelect())
            end
        elseif Input.IsDown(Input.Keyboard.Key.X) then
            if current_page.name == "difficulty" or current_page.name == "character" then
                confirm_timer = 10
                switchPage("title")
            end
        end
    end

    function scene:del()
        if self.hud_root then self.hud_root:release(); self.hud_root = nil end
    end

    return scene
end

return M
