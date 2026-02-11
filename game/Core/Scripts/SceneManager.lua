---@class Core.SceneManager
local M = {}
Core.SceneManager = M
M.__index = M

---@type table<string, Core.SceneManager.Scene>
M.Scenes = {}
---@type Core.SceneManager.Scene[]
M.Stack = {}
---@type Core.SceneManager.Scene
M.NextScene = nil
---@type Core.SceneManager.Scene[]
M.PushQueue = {}
M.PopQueue = 0

---创建新场景
---注意，渲染行为将不再由Scene管理，请在Camera中添加渲染事件
---Scene的del方法将极为重要，记得在del中清理资源
function M.NewScene(name)
    ---@class Core.SceneManager.Scene
    local self = {  }
    function self:init()
    end
    function self:frame()
    end
    function self:del()

    end
    self.name = name
    M.Scenes[name] = self
    return self
end

---请求替换整个堆栈
function M.SetScene(name)
    M.NextScene = assert(M.Scenes[name], "Scene not found: " .. name)
end

---请求压入堆栈
function M.PushScene(name, frameBelow, renderBelow)
    local scene = assert(M.Scenes[name], "Scene not found: " .. name)
    scene.frameBelow = frameBelow ~= false
    scene.renderBelow = renderBelow ~= false
    table.insert(M.PushQueue, scene)
end

---请求弹出堆栈
function M.PopScene()
    M.PopQueue = M.PopQueue + 1
end

---获取当前顶层场景
function M.Current()
    return M.Stack[#M.Stack]
end

---每帧更新
function M.Update()
    if M.NextScene then
        Core.MainLoop.OnSceneChangeBefore()
        for _, scene in ipairs(M.Stack) do
            scene:del()
            Core.Task.Clear(scene)
        end
        M.Stack = { M.NextScene }
        M.NextScene:init()
        M.NextScene.timer = 0
        M.NextScene = nil
        Core.MainLoop.OnSceneChangeAfter()
    end
    for _, scene in ipairs(M.PushQueue) do
        table.insert(M.Stack, scene)
        scene:init()
    end
    M.PushQueue = {}

    for _ = 1, M.PopQueue do
        M.Stack[#M.Stack]:del()
        table.remove(M.Stack)
    end
    M.PopQueue = 0

    for i, scene in ipairs(M.Stack) do
        local doFrame = true
        if i < #M.Stack then
            doFrame = M.Stack[i + 1].frameBelow
        end
        if doFrame then
            scene:frame()
        end
    end
end

function M.Restart()
   M.NextScene=M.Stack[1]
    for i, scene in ipairs(M.Stack) do
        if i > 1 then
            M.PushScene(scene.name, scene.frameBelow, scene.renderBelow)
        end
    end
end
