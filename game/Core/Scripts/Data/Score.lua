---@class Core.Data.Score
local M = {}
Core.Data.Score = M

---冒出来的null太可恶了
local function CheckData(_data)
    for k, v in pairs(_data) do
        if type(v) == "table" then
            CheckData(v)
        elseif type(v) == "userdata" then
            _data[k] = false
        end
    end
end

local password = { 3, 6, 11, 5, 4, 1, 2, 5, 8, 11, 9, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 100 }
---@param file file
---@param str string
local function writeEncodeData(file, str)
    for i = 1, #str do
        file:write(string.char((str:byte(i) + password[i % #password + 1] - 1) % 127 + 1))
    end
end
---@param file file
local function readDecodeData(file)
    local str = file:read("*a")
    local strs = {}
    for i = 1, #str do
        strs[i] = string.char((str:byte(i) - password[i % #password + 1] - 1) % 127 + 1)
    end
    return table.concat(strs)
end

local current_slot = 1--TODO

local main_path = Core.Data.GetPath()
local function getPath(slot)
    return ("%s/slot_%d"):format(main_path, slot)
end
local function getSlotFile(slot)
    return ("%s/slot_%d/score.dat"):format(main_path, slot)
end

local function NewOrReadFile(slot)
    Core.VFS.CreateDirectory(getPath(slot))
    local file = getSlotFile(slot)
    --读取文件
    local data
    if not Core.VFS.FileExist(file) then
        data = {}
    else
        local scoredata_file = io.open(file, "rb")
        local text = readDecodeData(scoredata_file)
        local ok, result = pcall(Core.Lib.Json.Decode, text)
        if ok and type(result) == "table" then
            data = result
            if type(data) ~= "table" then
                data = {}
            end
        else
            --[[
            lstg.ExtractRes(file, ("%s/%s_error.dat"):format(path, name))
            --lstg.MsgBoxError(("读取 %s.dat 失败\n已为您保留出现错误的存档\n请及时联系作者反馈此问题"):format(name), "Warning!!", false)--]]--TODO
            data = {}
        end
        scoredata_file:close()
        scoredata_file = nil
    end
    return data
end
local function SaveFile(data, slot)
    Core.VFS.CreateDirectory(getPath(slot))

    local file = getSlotFile(slot)
    local fake_file = file .. ".tmp"
    local score_data_file = assert(io.open(fake_file, "wb"))
    writeEncodeData(score_data_file, Core.Lib.Json.Encode(data))
    score_data_file:close()
    os.remove(file)
    os.rename(fake_file, file)
end

---@class Core.Data.Score.ScoreData
local _scoredata = { }

--通常数据
local _initscoredata = function()
    local data = NewOrReadFile(current_slot)
    data.Duration = data.Duration or { 0, 0, 0, 0, 0 }
    data.ContinuousLogin = data.ContinuousLogin or 1
    local d = os.date("*t")
    data.LastLoginDate = data.LastLoginDate or os.time({ day = d.day, month = d.month, year = d.year })
    data.first_language = data.first_language or false

    data.user_name = data.user_name or {}

    CheckData(data)
    _scoredata = data
end

function M.Init()
    _initscoredata()
end

function M.Save()
    SaveFile(_scoredata, current_slot)
    --[[
    if luaSteam.UpdateSteamServer then
        luaSteam.UpdateSteamServer()
    end--]]
end

function M.Get()
    return _scoredata
end

function M.SetUserName(name)
    _scoredata.user_name = string.utf8_byte(name)
end
function M.GetUserName()
    return string.utf8_char(_scoredata.user_name) or ""
end

function M.SetDefaultValue(key, value)
    _scoredata[key] = _scoredata[key] or value
end



