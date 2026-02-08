---@class Core.Data.Score
local M = {}
Core.Data.Score = M

M.current_slot = 1
M.event_listener = Core.Lib.EventListener()
M.event_listener:create("Score.beforeSave")
M.event_listener:create("Score.afterSave")

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
local function readDecodeData(file)
    local str = file:read("*a")
    local strs = {}
    for i = 1, #str do
        strs[i] = string.char((str:byte(i) - password[i % #password + 1] - 1) % 127 + 1)
    end
    return table.concat(strs)
end

local function getPath(slot)
    return ("%s/slot_%d"):format(Core.Data.GetPath(), slot)
end
local function getSlotFile(slot)
    return ("%s/slot_%d/score.dat"):format(Core.Data.GetPath(), slot)
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
            data = {}
        end
        scoredata_file:close()
        scoredata_file = nil
    end
    return data
end

---@class Core.Data.Score.ScoreData
local _scoredata = { }

--通常数据
local _initscoredata = function()
    local data = NewOrReadFile(M.current_slot)
    CheckData(data)
    _scoredata = data
end

function M.Init()
    _initscoredata()
end

function M.Save()
    M.event_listener:dispatch("Score.beforeSave")
    Core.VFS.CreateDirectory(getPath(M.current_slot))
    local file = getSlotFile(M.current_slot)
    local fake_file = file .. ".tmp"
    local score_data_file = assert(io.open(fake_file, "wb"))
    local str = Core.Lib.Json.Encode(_scoredata)
    for i = 1, #str do
        score_data_file:write(string.char((str:byte(i) + password[i % #password + 1] - 1) % 127 + 1))
    end
    score_data_file:close()
    os.remove(file)
    os.rename(fake_file, file)
    M.event_listener:dispatch("Score.afterSave")
end

function M.GetSaveIterator()
    Core.VFS.CreateDirectory(getPath(M.current_slot))
    local file = getSlotFile(M.current_slot)
    local fake_file = file .. ".tmp"
    local score_data_file = assert(io.open(fake_file, "wb"))
    local str = Core.Lib.Json.Encode(_scoredata)
    local strlen = #str
    local i = 1
    return function(stop)
        score_data_file:write(string.char((str:byte(i) + password[i % #password + 1] - 1) % 127 + 1))
        i = i + 1
        if i > strlen or stop then
            score_data_file:close()
            os.remove(file)
            os.rename(fake_file, file)
            return false
        else
            return true
        end
    end
end

function M.Get()
    return _scoredata
end

function M.SetDefaultValue(key, value)
    _scoredata[key] = _scoredata[key] or value
end

function M.SetSlot(slot)
    M.current_slot = slot
    M.Init()
end
function M.GetCurrentSlot()
    return M.current_slot
end

function M.AddSaveBeforeEvent(name, level, func)
    return M.event_listener:addEvent("Score.beforeSave", name, level, func)
end
function M.AddSaveAfterEvent(name, level, func)
    return M.event_listener:addEvent("Score.afterSave", name, level, func)
end



