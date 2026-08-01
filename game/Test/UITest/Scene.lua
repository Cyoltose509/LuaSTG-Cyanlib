---@class Test.UITest.Scene : Core.SceneManager.Scene
local Core = Core
local UI = Core.UI

local M = Core.SceneManager.NewScene("Test.UITest")
Test.UITest.Scene = M

function M:init()
    -- M.Main 内部通过 scene.ui = ui 赋值（含 app/root/panels 等全部字段）
    -- 返回值是 root（HUDRoot），不要用它覆盖 scene.ui
    Test.UITest.UI.Main(self)
end

function M:frame()
    Test.UITest.UI.Frame(self)
end

function M:del()
    UI.Manager.DestroyHUDRoot("uitest_root")
end
