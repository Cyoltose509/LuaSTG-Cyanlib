---@class STG.Menu.Result
local M = {}
STG.Menu.Result = M

local Menu = Core.Menu
local Render = Core.Render

function M.Show(run)
    local vd = run and run:getViewData() or {}

    local menu = Menu.Base()
    local selected = 1
    local options = {}

    if vd.clear_status == "clear" then
        table.insert(options, { text = "Next Stage", action = function()
            Menu.Pop()
            run:onStageClear()
        end })
        table.insert(options, { text = "Save Replay", action = function()
            if run and run.recorder then
                run.recorder:save()
            end
        end })
    else
        table.insert(options, { text = "Continue", action = function()
            Menu.Pop()
            run:onContinue()
        end })
    end
    table.insert(options, { text = "Restart", action = function()
        Menu.Pop()
        run:onRestart()
    end })
    table.insert(options, { text = "Return to Title", action = function()
        Menu.Pop()
        run:onReturnToTitle()
    end })

    function menu:updateInput()
        local Input = Core.Input
        if Input.ButtonDown("Player.MoveUp") then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif Input.ButtonDown("Player.MoveDown") then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif Input.ButtonDown("Player.Shoot") then
            local opt = options[selected]
            if opt and opt.action then
                opt.action()
            end
        end
    end

    function menu:render()
        -- Title: Clear or Game Over
        local title = (vd.clear_status == "clear") and "STAGE CLEAR!" or "GAME OVER"
        local title_color = (vd.clear_status == "clear") and Render.Color.ARGB(255, 255, 215, 0) or Render.Color.Red
        Render.Utils.SimpleText("default", title, 0, 180, 0.8, title_color)

        -- Score
        Render.Utils.SimpleText("default", string.format("Score: %d", vd.score or 0), 0, 140, 0.5, Render.Color.White)
        Render.Utils.SimpleText("default", string.format("Graze: %d", vd.graze or 0), 0, 120, 0.4, Render.Color.White)
        if vd.continues and vd.continues > 0 then
            Render.Utils.SimpleText("default", string.format("Continues: %d", vd.continues), 0, 100, 0.4, Render.Color.ARGB(200, 255, 100, 100))
        end

        -- Options
        for i, opt in ipairs(options) do
            local color = (i == selected) and Render.Color.White or Render.Color.ARGB(128, 200, 200, 200)
            local text = (i == selected) and ("> " .. opt.text .. " <") or opt.text
            Render.Utils.SimpleText("default", text, 0, -20 - i * 25, 0.4, color)
        end
    end

    Menu.Push(menu)
end

return M
