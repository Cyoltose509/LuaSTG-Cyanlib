---@class Test.STG.Loading : Core.SceneManager.Scene
local M = Core.SceneManager.NewScene("Test.STG.Loading")
Test.STG.Loading = M

local LazyLoader = Core.Resource.LazyLoader
local TIME_DELTA = 1 / 60

function M:init()
    self:setUI()
    self.index = 1
    self.maxindex = LazyLoader.GetLeft()
    self.time = os.clock()
    self.start_time = self.time
    self.black = 0
    Core.Task.New(self, function()
        while not self.jump do
            Core.Task.Wait()
        end
        --self.change_ui = true
        for i = 1, 60 do
            self.black = i / 60
            Core.Task.Wait()
        end
        Core.SceneManager.SetScene("Test.STG")
    end)


end

function M:del()
    self.ui_root:release()
end
function M:frame()
    self.timer = int((os.clock() - self.start_time) * 60)
    if self.index > self.maxindex then
        self.jump = true
    elseif not self.jump then
        local start_time, end_time = os.clock(), os.clock()
        while end_time - start_time <= TIME_DELTA do
            if self.index > self.maxindex then
                break
            end
            LazyLoader.Do()
            self.index = self.index + 1
            end_time = os.clock()
        end
    end
end
function M:setUI()
    local hud = Core.UI.Camera:getView()
    local black_mask = Core.UI.Image("white")
                           :setPos(hud.centerX, hud.centerY)
                           :setScale(hud.width / 16, hud.height / 16)
                           :setState(Core.Render.BlendMode.Default, Core.Render.Color.Transparent)
                           :setLayer(100)
    local progressBar = Core.UI.Immediate("progress", 0, function()
        local index = min(self.index, self.maxindex)
        local pgs = index / self.maxindex
        local len = pgs * hud.width
        Core.Render.Draw.SetState(Core.Render.BlendMode.MulAdd, Core.Render.Color(150, 255 - 155 * pgs, 100 + 155 * pgs, 100))
        Core.Render.Draw.Rect(hud.centerX - hud.width / 2, hud.centerX - hud.width / 2 + len, 0, 10)
        Core.Render.Text("exo2", ("%d / %d"):format(index, self.maxindex), hud.centerX,
                60, 1, Core.Render.Color.White, "center")
    end)
    local loading_text = Core.UI.Text()
                             :setText("Loading...")
                             :setFont("exo2")
                             :setSize(40)
                             :setPos(hud.centerX, hud.centerY - 160)
    local title = "LuaSTG"
    local layout = Core.UI.Layout.Grid()
                       :setPos(hud.centerX, hud.centerY)
                       :setGrid(6, 1)
                       :setLayer(2)
    for i = 1, 6 do
        local t = Core.UI.Text()
                      :setText(title:utf8_sub(i, i))
                      :setFont("exo2")
                      :setSize(80)
                      :setLayer(i)
                      :enableShadow(false)
                      :ignoreLayoutScale(true)

        if i >= 4 then
            t:setColor(Core.Render.Color.Black)
        end
        layout:addChild(t)
    end

    local target_w = 450
    local cur_w = 200
    local h = 100
    local whiteH = 2
    local blackH = h
    local title_back = Core.UI.Immediate("title_back", 1, function()
        Core.Render.Draw.SetState(Core.Render.BlendMode.Default, Core.Render.Color.Default)
        Core.Render.Draw.Rect(hud.centerX, hud.centerX + cur_w / 2, hud.centerY - h / 2, hud.centerY - h / 2 + blackH)
        Core.Render.Draw.Rect(hud.centerX - cur_w / 2, hud.centerX, hud.centerY - h / 2, hud.centerY - h / 2 + whiteH)
    end)

    self.ui_root = Core.UI.Manager.CreateHUDRoot("loading", 1)
                       :addChild(layout)
                       :addChild(loading_text)
                       :addChild(black_mask)
                       :addChild(progressBar)
                       :addChild(title_back)

    self.ui_root:addBeforeEvent("frame", 1, function()
        black_mask:setState(nil, Core.Render.Color(self.black * 255, 0, 0, 0))
        layout:setWH(cur_w, h)
        cur_w = lerp(cur_w, target_w, 0.05)

    end)
    Core.Task.New(self, function()
        while not self.change_ui do
            Core.Task.Wait()
        end
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