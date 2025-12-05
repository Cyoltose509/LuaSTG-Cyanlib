---@class Core.VFS
local M = {}
Core.VFS = M

M.DoFile = lstg.DoFile
M.LoadTextFile = lstg.LoadTextFile
--M.LoadPack = lstg.LoadPack
--M.UnloadPack = lstg.UnloadPack
--M.ExtractRes = lstg.ExtractRes
local FileManager = lstg.FileManager
M.EnumFiles = FileManager.EnumFiles
M.FileExist = FileManager.FileExist
M.LoadArchive = FileManager.LoadArchive
M.UnloadArchive = FileManager.UnloadArchive
M.UnloadAllArchive = FileManager.UnloadAllArchive
M.ArchiveExist = FileManager.ArchiveExist
M.EnumArchives = FileManager.EnumArchives
M.GetArchive = FileManager.GetArchive

M.AddSearchPath = FileManager.AddSearchPath
M.RemoveSearchPath = FileManager.RemoveSearchPath
M.ClearSearchPath = FileManager.ClearSearchPath

M.CreateDirectory = FileManager.CreateDirectory
M.RemoveDirectory = FileManager.RemoveDirectory
M.DirectoryExist = FileManager.DirectoryExist

---@return string
function M.GetCurrentDirectory()
    local path = debug.getinfo(2).source:match("^(.+/).-$")
    return path or ""
end
