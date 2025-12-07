---@class Core.Render.Color : lstg.Color
local M = {}
Core.Render.Color = M

setmetatable(M, {
    __call = function(_, ...)
        return lstg.Color(...)
    end
})

M.Default = lstg.Color(0xFFFFFFFF)
M.Transparent = lstg.Color(0x00FFFFFF)
M.White = lstg.Color(0xFFFFFFFF)
M.Black = lstg.Color(0xFF000000)
M.Red = lstg.Color(0xFFFF0000)
M.Green = lstg.Color(0xFF00FF00)
M.Blue = lstg.Color(0xFF0000FF)
M.Yellow = lstg.Color(0xFFFFFF00)
M.Magenta = lstg.Color(0xFFFF00FF)
M.Cyan = lstg.Color(0xFF00FFFF)

function M.Parse(str)
    local a, r, g, b = str:match('lstg%.Color%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%)')
    if a and r and g and b then
        return M.ARGB(tonumber(a), tonumber(r), tonumber(g), tonumber(b))
    end
end

---@overload fun(argb: number): lstg.Color
---@return lstg.Color
function M.ARGB(a, r, g, b)
    return lstg.Color(a, r, g, b)
end

function M.AHSV(a, h, s, v)
    return lstg.Color(a, M.HSVtoRGB(h, s, v))
end

function M.HSVtoRGB(H, S, V)
    H = H % 360

    S = clamp(S, 0, 1)
    V = clamp(V, 0, 1)
    if S == 0 then
        V = V * 255
        return V, V, V
    end
    local F, P, Q, T
    local R, G, B
    H = H / 60
    local i = int(H)
    if i == 6 then
        i = 0
    end
    F = H - i
    P = V * (1 - S)
    Q = V * (1 - S * F)
    T = V * (1 - S * (1 - F))
    if i == 0 then
        R, G, B = V, T, P
    elseif i == 1 then
        R, G, B = Q, V, P
    elseif i == 2 then
        R, G, B = P, V, T
    elseif i == 3 then
        R, G, B = P, Q, V
    elseif i == 4 then
        R, G, B = T, P, V
    elseif i == 5 then
        R, G, B = V, P, Q
    end
    R, G, B = R * 255, G * 255, B * 255
    return R, G, B
end

function M.RGBtoHSV(R, G, B)
    R = R / 255
    G = G / 255
    B = B / 255

    local max_v = max(R, G, B)
    local min_v = min(R, G, B)
    local delta = max_v - min_v

    local H, S, V
    V = max_v

    if delta == 0 then
        H = 0
        S = 0
    else
        S = delta / max_v

        if max_v == R then
            H = (G - B) / delta
        elseif max_v == G then
            H = 2 + (B - R) / delta
        else
            -- max == B
            H = 4 + (R - G) / delta
        end

        H = H * 60
        if H < 0 then
            H = H + 360
        end
    end

    return H, S, V
end

