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
    local src = debug.getinfo(2, "S").source
    if src:sub(1,1) == "@" then
        src = src:sub(2)
    end
    local i = src:match("^.*()[/\\]")
    return i and src:sub(1, i) or ""
end


---@param src string
---@param dst string
---@return boolean
function M.CopyFile(src, dst)
    local infile = io.open(src, "rb")
    if not infile then
        return false
    end

    local outfile = io.open(dst, "wb")
    if not outfile then
        infile:close()
        return false
    end

    while true do
        local block = infile:read(8192)
        if not block then
            break
        end
        outfile:write(block)
    end

    infile:close()
    outfile:close()

    return true
end
