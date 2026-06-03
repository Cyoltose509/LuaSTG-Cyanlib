---@class STG.Loading
---Reusable loading screen with animated title and progress bar.
---Usage:
---   STG.Loading.SetTarget("Some.Scene")
---   Core.SceneManager.SetScene("STG.Loading")
local M = Core.SceneManager.NewScene("STG.Loading")
STG.Loading = M

local LazyLoader = Core.Resource.LazyLoader
local Render = Core.Render
local TIME_DELTA = 1 / 60

M._target = "STG.Menu.Title"

function M.SetTarget(target)
    M._target = target
end

function M:init()
    self:setUI()
    self.index = 1
    self.maxindex = LazyLoader.GetLeft()
    self.time = os.clock()
    self.start_time = self.time
    self.black = 0
    self.timer = 0
    Core.Task.New(self, function()
        while not self.jump do Core.Task.Wait() end
        for i = 1, 60 do
            self.black = i / 60
            Core.Task.Wait()
        end
        Core.SceneManager.SetScene(M._target)
    end)
end

function M:del()
    if self.ui_root then self.ui_root:release() end
end

function M:frame()
    Core.Task.Do(self)
    self.timer = int((os.clock() - self.start_time) * 60)
    -- Update maxindex dynamically: Import() may add LazyLoader entries late
    self.maxindex = LazyLoader.GetLeft()
    if self.maxindex <= 0 then
        self.jump = true
    elseif not self.jump then
        local start_time = os.clock()
        while os.clock() - start_time <= TIME_DELTA do
            if LazyLoader.GetLeft() <= 0 then break end
            LazyLoader.Do()
            self.index = self.index + 1
        end
        self.maxindex = LazyLoader.GetLeft()
    end
end

function M:setUI()
    local hud = Core.UI.Camera:getView()
    local cx, cy = hud.centerX, hud.centerY

    local black_mask = Core.UI.Image("white")
        :setPos(cx, cy)
        :setScale(hud.width / 16, hud.height / 16)
        :setState(Render.BlendMode.Default, Render.Color.Transparent)
        :setLayer(100)

    local progressBar = Core.UI.Immediate("progress", 0, function()
        local index = math.min(self.index, self.maxindex)
        local total = math.max(self.maxindex, 1)
        local pgs = index / total
        local len = pgs * hud.width
        Render.Draw.SetState(Render.BlendMode.MulAdd,
            Render.Color(150, 255 - 155 * pgs, 100 + 155 * pgs, 100))
        Render.Draw.Rect(cx - hud.width / 2, cx - hud.width / 2 + len, 0, 10)
        Render.Utils.SimpleTTF("exo2", ("%d / %d"):format(index, total),
            cx, 60, 1, Render.Color.White, "center")
    end)

    local loading_text = Core.UI.Text()
        :setText("Loading..."):setFont("exo2"):setSize(40):setPos(cx, cy - 160)

    local title = "LuaSTG"
    local layout = Core.UI.Layout.Grid()
        :setPos(cx, cy):setGrid(6, 1):setLayer(2)
    for i = 1, 6 do
        local t = Core.UI.Text()
            :setText(title:utf8_sub(i, i)):setFont("exo2"):setSize(80)
            :setLayer(i):enableShadow(false):ignoreLayoutScale(true)
        if i >= 4 then t:setColor(Render.Color.Black) end
        layout:addChild(t)
    end

    local target_w = 450
    local cur_w = 200
    local h = 100
    local whiteH = 2
    local blackH = h
    local title_back = Core.UI.Immediate("title_back", 1, function()
        Render.Draw.SetState(Render.BlendMode.Default, Render.Color.Default)
        Render.Draw.Rect(cx, cx + cur_w / 2, cy - h / 2, cy - h / 2 + blackH)
        Render.Draw.Rect(cx - cur_w / 2, cx, cy - h / 2, cy - h / 2 + whiteH)
    end)

    self.ui_root = Core.UI.Manager.CreateHUDRoot("loading", 1)
        :addChild(layout):addChild(loading_text):addChild(black_mask)
        :addChild(progressBar):addChild(title_back)

    self.ui_root:addBeforeEvent("frame", 1, function()
        black_mask:setState(nil, Render.Color(self.black * 255, 0, 0, 0))
        layout:setWH(cur_w, h)
        cur_w = lerp(cur_w, target_w, 0.05)
    end)

    Core.Task.New(self, function()
        while not self.change_ui do Core.Task.Wait() end
        for i = 1, 15 do
            i = Core.Lib.Easing.QuartOut(i / 15)
            whiteH = 2 + (h - 2) * i
            blackH = h - (h - 2) * i
            Core.Task.Wait()
        end
        layout.children = {}
        local w = cur_w
        for i = 1, 30 do
            i = Core.Lib.Easing.QuadIn(i / 30)
            target_w = w * (1 - i)
            cur_w = target_w
            Core.Task.Wait()
        end
    end)
end
