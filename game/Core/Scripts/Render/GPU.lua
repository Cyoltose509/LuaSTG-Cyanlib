---@class Core.Render.GPU
local M = {}
Core.Render.GPU = M

M.ClearZBuffer = lstg.ClearZBuffer
M.PopRenderTarget = lstg.PopRenderTarget
M.RenderClear = lstg.RenderClear

---当务之急是停止使用这个函数
---转而使用更高级的参数设置方式
---What's urgent is to stop using this function
---Instead, use more advanced parameter settings
---@deprecated
M.PostEffect = lstg.PostEffect

function M.SetZBuffer(enable)
    lstg.SetZBufferEnable(enable and 1 or 0)
end
---@param tex Core.Resource.RenderTarget|string
function M.PushRenderTarget(tex)
    if type(tex) == 'table' then
        tex = tex.name
    end
    assert(type(tex) == 'string', 'invalid argument')
    lstg.PushRenderTarget(tex)
end

M.Enums = lstg.EnumGPUs
M.Change = lstg.ChangeGPU




