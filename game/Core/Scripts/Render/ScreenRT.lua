---@class Core.Render.ScreenRT
local M = {
    col00000000 = lstg.Color(0, 0, 0, 0),
    colFFFFFFF = lstg.Color(255, 255, 255, 255),
    flag = false, ---开启
    ---@type Core.Render.ScreenFX.Event[]
    Event = {},
    ---@type table<string, number>
    rtcount = {},
}
Core.Render.ScreenRT = M

---自定义全屏效果
---@param func fun(name:string, x:number, y:number, scale:number)@处理函数
---@param level number@优先级，数字越大优先级越高
---@param RenderOrigin boolean@是否渲染原有画面
---@param texname string@纹理名称
---@param noCapture boolean@不捕捉画面覆盖纹理
function M.Do(level, func, RenderOrigin, texname, noCapture)
    M.flag = true
    local name = texname or ("ScreenFX:level%d"):format(level)
    for _, e in ipairs(M.Event) do
        if e.level == level then
            e.func = func
            e.RenderOrigin = RenderOrigin
            e.Capture = not noCapture
            e.name = name
            return name
        end
    end--如果有同样的level，则更新func
    ---@class Core.Render.ScreenFX.Event
    local event = {
        func = func,
        level = level,
        RenderOrigin = RenderOrigin,
        Capture = not noCapture,
        name = name,
    }
    table.insert(M.Event, event)
    table.sort(M.Event, function(a, b)
        return a.level > b.level
    end)
    return name
end
function M.ResetUV()
    local uv1, uv2, uv3, uv4 = { [3] = 0.5 }, { [3] = 0.5 }, { [3] = 0.5 }, { [3] = 0.5 }
    local w, h = Core.Display.Screen.GetSize()
    local ww, wh = Core.Display.Window.GetSize()
    uv1[6], uv2[6], uv3[6], uv4[6] = M.colFFFFFFF, M.colFFFFFFF, M.colFFFFFFF, M.colFFFFFFF
    uv1[4], uv1[5] = 0, 0
    uv2[4], uv2[5] = ww, 0
    uv3[4], uv3[5] = ww, wh
    uv4[4], uv4[5] = 0, wh
    uv1[1], uv1[2] = 0, h
    uv2[1], uv2[2] = w, h
    uv3[1], uv3[2] = w, 0
    uv4[1], uv4[2] = 0, 0
    M.uv1, M.uv2, M.uv3, M.uv4 = uv1, uv2, uv3, uv4

end
function M.GetScreenUV(copy)
    if not (M.uv1 and M.uv2 and M.uv3 and M.uv4) then
        M.ResetUV()
    end
    if copy then
        local tb = Core.Lib.Table
        return tb.Copy(M.uv1), tb.Copy(M.uv2), tb.Copy(M.uv3), tb.Copy(M.uv4)
    else
        return M.uv1, M.uv2, M.uv3, M.uv4
    end
end
function M.CreateRenderTarget(name)
    if not M.rtcount[name] then
        M.rtcount[name] = 1--初始时多计一次
        Core.Resource.RenderTarget.New(name)
        --lstg.CreateRenderTarget(name)
    end
    M.rtcount[name] = M.rtcount[name] + 1

end
---下一帧再移除纹理，避免冗余处理
function M.RemoveRenderTarget(name)
    if M.rtcount[name] then
        M.rtcount[name] = M.rtcount[name] - 1
        if M.rtcount[name] <= 0 then
            Core.Resource.RenderTarget.Remove(name)
            M.rtcount[name] = nil
        end
    end
end
function M.BeforeRender()
    if M.flag then
        local e
        for i = #M.Event, 1, -1 do
            e = M.Event[i]
            if e.Capture then
                M.CreateRenderTarget(e.name)
                lstg.PushRenderTarget(e.name)
                lstg.RenderClear(M.col00000000)
            end
        end
    end
end
function M.AfterRender()
    if M.flag then
        --TODO：借用UI的摄像机
        Core.UI.Camera:apply()
        for _, e in ipairs(M.Event) do
            if e.Capture then
                lstg.PopRenderTarget()
            end
            if e.RenderOrigin then
                lstg.RenderTexture(e.name, "", M.GetScreenUV())
            end
            e.func(e.name, 0, 0, Core.Display.Screen.GetScale())
        end
    end
    for n in pairs(M.rtcount) do
        M.RemoveRenderTarget(n)
    end
end
function M.Stop()
    M.flag = false
    for k in ipairs(M.Event) do
        M.Event[k] = nil
    end
end

Core.Display.Screen.RegisterCallback("ScreenFXRefresh", M.ResetUV)