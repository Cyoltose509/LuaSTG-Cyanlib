---@class STG.Menu.MainMenu
local M = {}
STG.Menu.MainMenu = M

---Create and push the main menu.
---Expected to be called from the title scene.
function M.Show()
    local menu = Core.Menu.Base()

    local options = {
        { text = "Start Game",    action = M.onStart },
        { text = "Continue",      action = M.onContinue },
        { text = "Replay",        action = M.onReplay },
        { text = "Settings",      action = M.onSettings },
        { text = "Quit",          action = M.onQuit },
    }

    local selected = 1

    function menu:updateInput()
        local Input = Core.Input
        if Input.ButtonDown("Player.MoveUp") then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif Input.ButtonDown("Player.MoveDown") then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif Input.ButtonDown("Player.Shoot") or Input.ButtonDown("Player.Bomb") then
            local opt = options[selected]
            if opt and opt.action then
                opt.action()
            end
        end
        if Input.ButtonDown("Player.Pause") then
            M.onQuit()
        end
    end

    function menu:render()
        local Render = Core.Render
        for i, opt in ipairs(options) do
            local color = (i == selected) and Render.Color.White or Render.Color.ARGB(128, 200, 200, 200)
            local text = (i == selected) and ("> " .. opt.text .. " <") or opt.text
            Render.Utils.SimpleTTF("exo2", text, 0, 60 - i * 30, 0.5, color)
        end
    end

    Core.Menu.Push(menu)
end

function M.onStart()
    Core.Menu.Pop()
    -- Start difficulty select or directly start game
    local scene = STG.Run.GameScene.New({
        difficulty = STG.Config.Get("difficulty"),
        stage = 1,
    })
    Core.SceneManager.NewScene("gameplay", scene)
    Core.SceneManager.SetScene("gameplay")
end

function M.onContinue()
    Core.Menu.Pop()
    -- Load save data for continue
    local scene = STG.Run.GameScene.New({
        difficulty = STG.Config.Get("difficulty"),
        stage = 1,
    })
    Core.SceneManager.NewScene("gameplay", scene)
    Core.SceneManager.SetScene("gameplay")
end

function M.onReplay()
    -- Navigate to replay select menu
end

function M.onSettings()
    STG.Menu.Settings.Show()
end

function M.onQuit()
    Core.MainLoop.ExitGame()
end

return M
