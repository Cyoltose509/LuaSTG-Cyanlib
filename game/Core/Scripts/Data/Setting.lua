---@class Core.Data.Setting
local M = {}
Core.Data.Setting = M

local KEY = Core.Input.Keyboard.Key
local xKEY = Core.Input.Xinput.Key
local resx, resy = Core.Display.GetSize()
---@class Core.Data.Setting.Settings
local default_setting = {
    reso_value = math.floor(resy * 0.8),
    displayBG = true,
    ui_scaling = 100,
    window = {
        allow_title_bar_auto_hide = false,
    },
    graphics_system = {
        width = math.floor(resx * 0.8),
        height = math.floor(resy * 0.8),
        fullscreen = false,
        vsync = false,
    },
    render_quality = 3,

    sevolume = 80,
    bgmvolume = 80,
    language = 1,
    autosave = false,
    hitbox_top = false,
    show_keystate = true,
    xbox_slot = 0, --检测手柄
    keys = {
        up = KEY.UP,
        down = KEY.DOWN,
        left = KEY.LEFT,
        right = KEY.RIGHT,
        slow = KEY.SHIFT,
        shoot = KEY.Z,
        spell = KEY.X,
        special = KEY.C,
    },
    keysys = {
        menu = KEY.ESCAPE,
        repfast = KEY.LCTRL,
        repslow = KEY.SHIFT,
        retry = KEY.R,
    },
    xkeys = {
        up = xKEY.UP,
        down = xKEY.DOWN,
        left = xKEY.LEFT,
        right = xKEY.RIGHT,
        slow = xKEY.LSHOULDER,
        shoot = xKEY.RightTrigger,
        spell = xKEY.LeftTrigger,
        special = xKEY.RSHOULDER,
    },
    xkeysys = {
        confirm = xKEY.A,
        menu = xKEY.B,
        repfast = xKEY.A,
        repslow = xKEY.B,
        retry = xKEY.START,

    },
}

---@type Core.Data.Setting.Settings
local setting = {}

local settingfile_dir = Core.Data.GetPath()
local settingfile = settingfile_dir .. "/setting.json"

function M.GetDefault()
    return default_setting
end
function M.Get()
    return setting
end
function M.Save()
    Core.VFS.CreateDirectory(settingfile_dir)
    local f = assert(io.open(settingfile, 'w'))
    f:write(Core.Lib.Json.Serialize(setting))
    f:close()
end
function M.Load()
    local f, msg
    f, msg = io.open(settingfile, 'r')
    if f == nil then
        setting = Core.Lib.Table.DeepCopy(default_setting)
    else
        setting = Core.Lib.Json.Decode(f:read('*a'))
        f:close()
    end
    for k, v in pairs(default_setting) do
        if setting[k] == nil then
            setting[k] = v
        elseif type(v) == 'table' then
            for k2, v2 in pairs(v) do
                if setting[k][k2] == nil then
                    setting[k][k2] = v2
                end
            end
        end
    end-- 补全配置项
end

M.Load()