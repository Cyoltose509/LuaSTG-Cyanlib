---@class Core.Resource.Music
local M = {}
Core.Resource.Music = M
M.__index = M
M.__type = "Music"

---@type Core.Resource.Music[]
M.res = {}

function M.New(name, path, loopEnd, loopLength)

    loopEnd = loopEnd or 0
    loopLength = loopLength or 0
    assert(loopEnd >= loopLength, "loopEnd must be greater than or equal to loopLength")
    ---@type Core.Resource.Music
    local self = setmetatable({}, M)
    ---@private
    self._available = false

    self.name = name
    self.path = path
    ---会受循环节影响的timer，单位为帧
    self.timer = 0
    ---@private
    ---不受循环节影响的timer，单位为帧
    self._timer = 0
    self.volume = 1
    self.speed = 1
    self.loopData = {
        start_in_seconds = loopEnd - loopLength,
        end_in_seconds = loopEnd
    }
    self.isLoop = true
    self._MusicFFT = {}
    M.res[name] = self
    return self
end

function M.Get(name)
    return M.res[name]
end

---@param loopEnd number
---@param loopLength number
function M:setLoopRange(loopEnd, loopLength)
    assert(loopEnd >= loopLength, "loopEnd must be greater than or equal to loopLength")
    self.loopData.end_in_seconds = loopEnd
    self.loopData.start_in_seconds = loopEnd - loopLength
    if self._available then
        lstg.SetMusicLoopRange(self.name, self.loopData)
    end
    return self
end
---@param loop boolean
function M:setLoop(loop)
    self.isLoop = loop
    if self._available then
        if loop then
            lstg.SetMusicLoopRange(self.name, self.loopData)
        else
            lstg.SetMusicLoopRange(self.name)
        end

    end
    return self
end

function M:load()
    if not self._available then
        local loopEnd = self.loopData.end_in_seconds
        local loopLength = loopEnd - self.loopData.start_in_seconds
        lstg.LoadMusic(self.name, self.path, loopEnd, loopLength)
        if not self.isLoop then
            lstg.SetMusicLoopRange(self.name)
        end
        self.res_pool = Core.Resource.GetResourcePool()
        self._available = true
    end
    return self
end

function M:unload()
    if self._available then
        lstg.RemoveResource(self.res_pool, Core.Resource.ResType.Music, self.name)
        self._available = false
    end
    --M.res[name] = nil
end

function M:play(volume, time)
    time = time or (self._timer / 60)
    self:load()
    self:setTimer(time)
    self.volume = volume
    lstg.PlayMusic(self.name, volume, time)
    if Core.AudioManager then
        Core.AudioManager.CurrentBGM[self] = true
    end
    return self
end

function M:pause()
    if self._available then
        lstg.PauseMusic(self.name)
    end
    return self
end

function M:resume()
    if self._available then
        lstg.ResumeMusic(self.name)
    end
    return self
end

function M:stop()
    if self._available then
        self.timer = 0
        self._timer = 0
        lstg.StopMusic(self.name)
        self:unload()
        if Core.AudioManager then
            Core.AudioManager.CurrentBGM[self] = nil
        end
    end
end

function M:setTimer(time)
    self._timer = math.floor(time * 60)
    self.timer = Core.Math.Wrap(self._timer, self.loopData.start_in_seconds, self.loopData.end_in_seconds)
    return self
end

function M:addTimer(add)
    add = add or 1
    self._timer = self._timer + add
    self.timer = Core.Math.Wrap(self._timer, self.loopData.start_in_seconds, self.loopData.end_in_seconds)
    return self
end

function M:getFFT()
    if self._available then
        lstg.GetMusicFFT(self.name, self._MusicFFT)
    end
    return self._MusicFFT
end

---@return lstg.AudioStatus
function M:getState()
    if self._available then
        return lstg.GetMusicState(self.name)
    else
        return Core.AudioManager.Status.Stopped
    end
end

function M:isPlaying()
    return self:getState() == Core.AudioManager.Status.Playing
end
function M:isPaused()
    return self:getState() == Core.AudioManager.Status.Paused
end
function M:isStopped()
    return self:getState() == Core.AudioManager.Status.Stopped
end

function M:setVolume(volume)
    self.volume = volume
    if self._available then
        lstg.SetBGMVolume(self.name, volume)
    end
    return self
end
function M:getVolume()
    return self.volume
end

function M:setSpeed(speed)
    self.speed = speed
    if self._available then
        lstg.SetBGMSpeed(self.name, speed)
    end
    return self
end
function M:getSpeed()
    return self.speed
end

---@param loop boolean
function M:setLoop(loop)
    self.isLoop = loop
    return self
end

function M:fadePlay(time, volume, start_time)
    volume = volume or 1
    self:play(0, start_time)
    Core.Task.Clear(self)
    Core.Task.New(self, function()
        for i = 1, time do
            self:setVolume(i / time * volume)
            Core.Task.Wait()
        end
    end)
    return self
end

function M:fadeStop(time)
    Core.Task.Clear(self)
    Core.Task.New(self, function()
        for i = self.volume, 0, -1 / time do
            self:setVolume(i)
            Core.Task.Wait()
        end
        self:stop()
    end)
end
