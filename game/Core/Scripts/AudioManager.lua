---@class Core.AudioManager
local M = {}
Core.AudioManager = M

---@type table<Core.Resource.Music, boolean>
M.CurrentBGM = {}
setmetatable(M.CurrentBGM, { __mode = "k" })

M.BGMVolume = 1
M.SoundVolume = 1

---@class lstg.AudioStatus
M.Status = {
    Stopped = "stopped",
    Playing = "playing",
    Paused = "paused",
}
M.GetMusic = Core.Resource.Music.Get
M.GetSound = Core.Resource.Sound.Get

function M.Update()
    local dt = Core.Time.GetDelta()
    for music in pairs(M.CurrentBGM) do
        Core.Task.Do(music, dt)
        if music:isPlaying() then
            music:addTimer(dt)
        elseif music:isStopped() then
            M.CurrentBGM[music] = nil
        end
    end
end

---设置全局BGM音量
function M.SetBGMVolume(volume)
    M.BGMVolume = volume
    lstg.SetBGMVolume(volume)
end

function M.SetSoundVolume(volume)
    M.SoundVolume = volume
    lstg.SetSEVolume(volume)
end

---@return string[]
function M.ListDevices()
    return lstg.ListAudioDevice()
end
---@param device_name string
function M.SetDevice(device_name)
    return lsg.ChangeAudioDevice(device_name)
end

function M.PlaySound(name, volume, pan)
    Core.Resource.Sound.Get(name):play(volume, pan)
end
function M.PlayBGM(name, volume, start_time)
    Core.Resource.Music.Get(name):play(volume, start_time)
end

function M.Init()
    local setting = Core.Data.Setting.Get()
    M.SetBGMVolume(setting.bgmvolume / 100)
    M.SetSoundVolume(setting.sevolume / 100)
end