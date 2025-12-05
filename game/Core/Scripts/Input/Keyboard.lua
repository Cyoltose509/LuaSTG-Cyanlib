---@class Core.Input.Keyboard
local M = {}
Core.Input.Keyboard = M

local keyState = {}
local keyStatePre = {}

function M.IsDown(key)
    return keyState[key] and not keyStatePre[key]
end
function M.IsPressed(key)
    return keyState[key]
end
function M.IsUp(key)
    return not keyState[key] and keyStatePre[key]
end

---@class Core.Input.Keyboard.Key
---range: 0x000-0x0FF
M.Key = {
    Null = 0x00,


    Escape = 0x1B,
    Backspace = 0x08,
    Tab = 0x09,
    Enter = 0x0D,
    Space = 0x20,

    --SHIFT = 0x10,
    --CTRL = 0x11,
    --ALT = 0x12,

    --很奇怪的东西？只能自己加了
    LCtrl = 0xA2,
    RCtrl = 0xA3,
    LAlt = 0xA4,
    RAlt = 0xA5,
    Shift = 0xA0,
    NumEnter = 0xE8,
    --RSHIFT = 0xA1,

    LWin = 0x5B,
    RWin = 0x5C,
    Apps = 0x5D,

    Pause = 0x13,
    CapsLock = 0x14,
    NumLock = 0x90,
    ScrollLock = 0x91,

    PageUp = 0x21,
    PageDown = 0x22,
    Home = 0x24,
    End = 0x23,
    Insert = 0x2D,
    Delete = 0x2E,

    Left = 0x25,
    Up = 0x26,
    Right = 0x27,
    Down = 0x28,

    ["0"] = 0x30,
    ["1"] = 0x31,
    ["2"] = 0x32,
    ["3"] = 0x33,
    ["4"] = 0x34,
    ["5"] = 0x35,
    ["6"] = 0x36,
    ["7"] = 0x37,
    ["8"] = 0x38,
    ["9"] = 0x39,

    A = 0x41,
    B = 0x42,
    C = 0x43,
    D = 0x44,
    E = 0x45,
    F = 0x46,
    G = 0x47,
    H = 0x48,
    I = 0x49,
    J = 0x4A,
    K = 0x4B,
    L = 0x4C,
    M = 0x4D,
    N = 0x4E,
    O = 0x4F,
    P = 0x50,
    Q = 0x51,
    R = 0x52,
    S = 0x53,
    T = 0x54,
    U = 0x55,
    V = 0x56,
    W = 0x57,
    X = 0x58,
    Y = 0x59,
    Z = 0x5A,

    Grave = 0xC0,
    Minus = 0xBD,
    Equals = 0xBB,
    Backslash = 0xDC,
    LBracket = 0xDB,
    RBracket = 0xDD,
    Semicolon = 0xBA,
    Apostrophe = 0xDE,
    Comma = 0xBC,
    Period = 0xBE,
    Slash = 0xBF,

    Numpad0 = 0x60,
    Numpad1 = 0x61,
    Numpad2 = 0x62,
    Numpad3 = 0x63,
    Numpad4 = 0x64,
    Numpad5 = 0x65,
    Numpad6 = 0x66,
    Numpad7 = 0x67,
    Numpad8 = 0x68,
    Numpad9 = 0x69,

    Multiply = 0x6A,
    Divide = 0x6F,
    Add = 0x6B,
    Subtract = 0x6D,
    Decimal = 0x6E,

    F1 = 0x70,
    F2 = 0x71,
    F3 = 0x72,
    F4 = 0x73,
    F5 = 0x74,
    F6 = 0x75,
    F7 = 0x76,
    F8 = 0x77,
    F9 = 0x78,
    F10 = 0x79,
    F11 = 0x7A,
    F12 = 0x7B,
}

M.KeyTriggering = {}
for _, v in pairs(M.Key) do
    M.KeyTriggering[v] = Core.Input.NewTriggerRecord(v)
end

function M.Update()
    keyState, keyStatePre = {}, keyState
    for _,k in pairs(M.Key) do
        keyState[k] = lstg.GetKeyState(k)
    end
    Core.Input.KeyTriggerUpdate(M.KeyTriggering, keyState)
end

local keyName = {}
for k, v in pairs(M.Key) do
    keyName[v] = k
end
function M.GetKeyName(code)
    return keyName[code]
end

function M.GetLast()
    return Core.Input.GetLastTrigger(M.KeyTriggering)
end