
---@class Test.DataVisual.PauseMenu
local M = {}
Test.DataVisual.PauseMenu = M

local Core = Core
local Input = Core.Input
local MainLoop = Core.MainLoop

local pauseMenu = {
    kill = true
}
function pauseMenu:init()
    MainLoop.DisableLabel(MainLoop.Label.Gameplay)
    self.alpha = 0
    self.ui_root = Test.DataVisual.UI.PauseMenu(self)
    self.is_exiting = false
    self.kill = false
    Core.Task.New(self, function()
        for _ = 1, 10 do
            self.alpha = self.alpha + 1 / 10
            Core.Task.Wait()
        end
    end)
end
function pauseMenu:frame()
    Core.Task.Do(self)
    if self.kill then
        return
    end
    if Input.IsDown(Input.Keyboard.Key.Escape) then
        self:exit()
    end
end
function pauseMenu:exit()

    MainLoop.EnableLabel(MainLoop.Label.Gameplay)
    Core.Task.New(self, function()
        self.kill = true
        for _ = 1, 10 do
            self.alpha = self.alpha - 1 / 10
            Core.Task.Wait()
        end

        self:del()
    end)
end
function pauseMenu:del()
    self.ui_root:release()
end
function M.Frame()
    pauseMenu:frame()
    if Input.IsDown(Input.Keyboard.Key.Escape) and pauseMenu.kill then
        pauseMenu:init()
    end

end

MainLoop.AddEvent("Frame","Before", {
    name = "Test.DataVisual.PauseMenu",
    func = M.Frame,
})

