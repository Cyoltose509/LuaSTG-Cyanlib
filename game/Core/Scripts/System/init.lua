---@class Core.System
---@field Clipboard Core.System.Clipboard
---@field TextInput Core.System.TextInput
local M = {}
Core.System = M

require("Core.Scripts.System.Clipboard")
require("Core.Scripts.System.TextInput")

local Window = require("lstg.Window")
local ShellIntegration = require("lstg.ShellIntegration")
M.OpenFile = ShellIntegration.openFile
M.OpenDirectory = ShellIntegration.openDirectory
M.OpenURL = ShellIntegration.openUrl

M.GetLocalAppDataPath = lstg.Platform.GetLocalAppDataPath
M.GetRoamingAppDataPath = lstg.Platform.GetRoamingAppDataPath
M.RestartWithCommandLineArguments = lstg.Platform.RestartWithCommandLineArguments
M.MessageBox = lstg.Platform.MessageBox

---设置标题栏是否自动隐藏
---win11专属功能
---Set whether the title bar is automatically hidden
---win11 exclusive function
---@param allow boolean
function M.SetTitleBarAutoHide(allow)
    local main_window = Window.getMain()
    local window_win11_ext = main_window:queryInterface("lstg.Window.Windows11Extension")
    if window_win11_ext then
        window_win11_ext:setTitleBarAutoHidePreference(allow)
    end
end

