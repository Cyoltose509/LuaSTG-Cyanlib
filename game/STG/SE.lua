---@class STG.SE
---Sound effect playback. Short names map to stg:se.* resources.
---Usage: STG.SE.Play("damage00") or STG.SE.Play("damage00", 0.5, pan)
local M = {}
STG.SE = M

local Sound = Core.Resource.Sound

---Play a sound effect by short name.
---@param name string Short name (e.g. "damage00", "graze", "item00")
---@param volume number|nil 0-1, default 1
---@param pan number|nil -1 to 1, default 0
function M.Play(name, volume, pan)
    local s = Sound.Get("stg:se." .. name)
    if s then
        s:play(volume or 1, pan or 0)
    end
end

---Stop a sound effect.
---@param name string
function M.Stop(name)
    local s = Sound.Get("stg:se." .. name)
    if s then s:stop() end
end

---Play a music track by short name.
---@param name string Short name (e.g. "menu", "spellcard")
---@param volume number|nil
function M.PlayMusic(name, volume)
    local m = Core.Resource.Music.Get("stg:bgm." .. name)
    if m then m:play(volume or 1) end
end

---Stop a music track.
---@param name string
function M.StopMusic(name)
    local m = Core.Resource.Music.Get("stg:bgm." .. name)
    if m then m:stop() end
end

return M
