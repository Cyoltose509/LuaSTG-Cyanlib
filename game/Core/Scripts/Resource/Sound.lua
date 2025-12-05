---@class Core.Resource.Sound
local M = {}
Core.Resource.Sound = M
M.__index = M
M.__type = "Sound"

---@type Core.Resource.Sound[]
M.res = {}

function M.New(name, path, defaultVolume, defaultPan)
    if M.res[name] then
        M.Remove(name)
    end
    ---@type Core.Resource.Sound
    local self = setmetatable({}, M)
    self.name = name
    self.path = path
    self.defaultVolume = defaultVolume
    self.defaultPan = defaultPan
    lstg.LoadSound(self.name, self.path)
    self.res_pool = Core.Resource.GetResourcePool()
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end
function M.Remove(name)
    if M.res[name] then
        lstg.RemoveResource(M.res[name].res_pool, Core.Resource.ResType.Sound, name)
        M.res[name] = nil
    end
end

function M.Clear()
    for k in pairs(M.res) do
        M.Remove(k)
    end
end
function M:unload()
    M.Remove(self.name)
end
function M:copy(newName)
    return M.New(newName, self.path, self.defaultVolume, self.defaultPan)
end

function M:play(volume, pan)
    lstg.PlaySound(self.name, volume or self.defaultVolume, pan or self.defaultPan)
end

function M:stop()
    lstg.StopSound(self.name)
end

function M:pause()
    lstg.PauseSound(self.name)
end

function M:resume()
    lstg.ResumeSound(self.name)
end

function M:getState()
    return lstg.GetSoundState(self.name)
end