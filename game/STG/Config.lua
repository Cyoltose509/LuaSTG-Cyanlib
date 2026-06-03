---@class STG.Config
local M = {}
STG.Config = M

local Input = Core.Input
local Setting = Core.Data.Setting

local STG_PREFIX = "stg."

---@class STG.Config.Defaults
local DEFAULTS = {
    difficulty = "NORMAL",
    starting_lives = 3,
    starting_bombs = 3,
    game_speed = 1,
    import_legacy_assets = true,  -- disable to skip legacy asset loading
    key_bindings = {
        up    = { Input.Keyboard.Key.Up },
        down  = { Input.Keyboard.Key.Down },
        left  = { Input.Keyboard.Key.Left },
        right = { Input.Keyboard.Key.Right },
        slow  = { Input.Keyboard.Key.Shift },
        shoot = { Input.Keyboard.Key.Z },
        bomb  = { Input.Keyboard.Key.X },
        special = { Input.Keyboard.Key.C },
        pause = { Input.Keyboard.Key.Escape },
        skip  = { Input.Keyboard.Key.LeftControl },
    },
}

---@type STG.Config.Defaults
local config = {}

for k, v in pairs(DEFAULTS) do
    if type(v) == "table" and not v[1] then
        config[k] = Core.Lib.Table.DeepCopy(v)
    else
        config[k] = v
    end
end

---@param key string
---@return any
function M.Get(key)
    if not key then
        return config
    end
    local fields = key:split(".")
    local obj = config
    for i = 1, #fields do
        obj = obj[fields[i]]
        if obj == nil then
            return nil
        end
    end
    return obj
end

---@param key string
---@param value any
function M.Set(key, value)
    local fields = key:split(".")
    local obj = config
    for i = 1, #fields - 1 do
        if obj[fields[i]] == nil then
            obj[fields[i]] = {}
        end
        obj = obj[fields[i]]
    end
    obj[fields[#fields]] = value
end

function M.Reset()
    for k, v in pairs(DEFAULTS) do
        if type(v) == "table" and not v[1] then
            config[k] = Core.Lib.Table.DeepCopy(v)
        else
            config[k] = v
        end
    end
end

function M.GetDefaults()
    return DEFAULTS
end

---Register input buttons from current config.
---Call this during STG init.
function M.RegisterInput()
    local kb = M.Get("key_bindings")
    if not kb then
        kb = DEFAULTS.key_bindings
    end

    local buttons = {
        { "Player.MoveUp",    kb.up },
        { "Player.MoveDown",  kb.down },
        { "Player.MoveLeft",  kb.left },
        { "Player.MoveRight", kb.right },
        { "Player.Slow",      kb.slow },
        { "Player.Shoot",     kb.shoot },
        { "Player.Bomb",      kb.bomb },
        { "Player.Special",   kb.special },
        { "Player.Pause",     kb.pause },
        { "Player.Skip",      kb.skip },
    }

    for _, btn in ipairs(buttons) do
        Input.RegisterButton(btn[1], btn[2])
    end

    Input.RegisterAxis("Player.MoveHorizontal", function()
        return Input.ButtonPressed("Player.MoveLeft")
    end, function()
        return Input.ButtonPressed("Player.MoveRight")
    end)

    Input.RegisterAxis("Player.MoveVertical", function()
        return Input.ButtonPressed("Player.MoveDown")
    end, function()
        return Input.ButtonPressed("Player.MoveUp")
    end)
end

---Persist STG config to Core.Data.Setting.
function M.Save()
    local setting = Setting.Get()
    if not setting.stg then
        setting.stg = {}
    end
    setting.stg.config = config
    Setting.Save()
end

---Load STG config from Core.Data.Setting.
function M.Load()
    local setting = Setting.Get()
    if setting.stg and setting.stg.config then
        Core.Lib.Table.DeepMerge(config, setting.stg.config)
    end
end

return M
