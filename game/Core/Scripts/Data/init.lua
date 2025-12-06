---@class Core.Data
---@field Score Core.Data.Score
---@field Setting Core.Data.Setting
local M = {}
Core.Data = M
M._Path = lstg.Platform.GetRoamingAppDataPath() .. "/Cyoltose Games/TouhouRoguelike2"

function M.GetPath()
    return M._Path
end
function M.SetPath(path)
    if Core.MainLoop and Core.MainLoop.HasInitialized then
        error("Setting data path after game has started is not allowed.")
    else
        assert(type(path) == "string", "Path must be a string.")
        Core.VFS.CreateDirectory(path)
        M._Path = path
    end
end

require("Core.Scripts.Data.Score")
require("Core.Scripts.Data.Setting")