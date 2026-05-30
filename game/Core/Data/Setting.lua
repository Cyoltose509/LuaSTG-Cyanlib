---@class Core.Data.Setting
local M = {}
Core.Data.Setting = M

local resx, resy = Core.Display.GetSize()

---@class Core.Data.Setting.Settings
local default_setting = {
    window = {
        allow_title_bar_auto_hide = false,
    },
    graphics_system = {
        width = math.floor(resx * 0.8),
        height = math.floor(resy * 0.8),
        fullscreen = false,
        vsync = false,
        allow_software_device = false,
        allow_exclusive_fullscreen = false,
        allow_direct_composition = true,
        allow_modern_swap_chain = true,
    },
    audio_system = {
        sound_effect_volume = 1,
        music_volume = 1,
    },
    language = "ZH-CN",
}

---@type Core.Data.Setting.Settings
local setting = {}

function M.GetDefault()
    return default_setting
end
function M.Get()
    return setting
end

function M.Save()
    local settingfile_dir = Core.Data.GetPath()
    local settingfile = settingfile_dir .. "/setting.json"
    Core.VFS.CreateDirectory(settingfile_dir)
    local f = assert(io.open(settingfile, 'w'))
    f:write(Core.Lib.Json.Serialize(setting))
    f:close()
end

function M.Load()
    local f, msg
    local settingfile_dir = Core.Data.GetPath()
    local settingfile = settingfile_dir .. "/setting.json"
    f, msg = io.open(settingfile, 'r')
    if f == nil then
        Core.Lib.Table.DeepMerge(setting, default_setting)
    else
        Core.Lib.Table.DeepMerge(setting, Core.Lib.Json.Decode(f:read('*a')))
        f:close()
    end
    Core.Lib.Table.DeepMergeIf(setting, default_setting)
end

---设置默认值
---建议在GameInit前设置好
---@param key string 支持解析"."
function M.SetDefaultValue(key, value)
    local obj = default_setting
    local fields = key:split(".")
    for i = 1, #fields - 1 do
        local field = fields[i]
        obj[field] = obj[field] or {}
        obj = obj[field]
    end
    local field = fields[#fields]
    obj[field] = value
end


--M.Load()