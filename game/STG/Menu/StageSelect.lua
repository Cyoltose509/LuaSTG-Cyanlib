---@class STG.Menu.StageSelect
local M = {}
STG.Menu.StageSelect = M

local Menu = Core.Menu
local Render = Core.Render

function M.Show(difficulty, character)
    local menu = Menu.Base()

    local stages = {}
    local max_stages = 6
    for i = 1, max_stages do
        table.insert(stages, {
            id = i,
            label = "Stage " .. i,
            unlocked = (i == 1), -- First stage always unlocked; others require clearing previous
        })
    end

    local selected = 1

    function menu:updateInput()
        local Input = Core.Input
        if Input.ButtonDown("Player.MoveLeft") then
            selected = max(1, selected - 1)
        elseif Input.ButtonDown("Player.MoveRight") then
            selected = min(#stages, selected + 1)
        elseif Input.ButtonDown("Player.Shoot") then
            local stage = stages[selected]
            if stage and stage.unlocked then
                Menu.Pop()
                local scene = STG.Run.GameScene.New({
                    difficulty = difficulty or "NORMAL",
                    stage = stage.id,
                    character = character,
                })
                Core.SceneManager.NewScene("gameplay", scene)
                Core.SceneManager.SetScene("gameplay")
            end
        elseif Input.ButtonDown("Player.Pause") or Input.ButtonDown("Player.Bomb") then
            Menu.Pop()
        end
    end

    function menu:render()
        Render.Utils.SimpleText("default", "Select Stage", 0, 150, 0.6, Render.Color.White)
        for i, stage in ipairs(stages) do
            local color
            if i == selected then
                color = Render.Color.White
            elseif stage.unlocked then
                color = Render.Color.ARGB(180, 200, 200, 200)
            else
                color = Render.Color.ARGB(80, 100, 100, 100)
            end
            local text = (i == selected) and ("[" .. stage.label .. "]") or stage.label
            if not stage.unlocked then
                text = text .. " (locked)"
            end
            Render.Utils.SimpleText("default", text, (i - 3.5) * 120, 0, 0.4, color)
        end
    end

    Menu.Push(menu)
end

return M
