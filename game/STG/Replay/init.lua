---@class STG.Replay
---@field UI STG.Replay.UI
local M = {}
STG.Replay = M

local Constants = STG.Constants
local Event = STG.Event
local Json = Core.Lib.Json
local RNG = Core.RNG

-- ========================================
-- Replay Data (serializable header + frames)
-- ========================================

---@class STG.Replay.Data
---@field version number
---@field game_id string
---@field difficulty string
---@field stage number
---@field character string
---@field seed number RNG seed
---@field date string ISO date string
---@field frames STG.Replay.FrameData[]
---@field checksums STG.Replay.ChecksumData[]

---@class STG.Replay.FrameData
---@field up boolean
---@field down boolean
---@field left boolean
---@field right boolean
---@field shoot boolean
---@field bomb boolean
---@field special boolean
---@field slow boolean
---@field pause boolean
---@field skip boolean

---@class STG.Replay.ChecksumData
---@field frame number
---@field x number Player X position
---@field y number Player Y position
---@field timer number Game timer
---@field rng_state string Serialized RNG state

---Create a new empty replay data structure.
---@param opt table|nil
---@return STG.Replay.Data
function M.NewData(opt)
    opt = opt or {}
    return {
        version = Constants.REPLAY.VERSION,
        game_id = opt.game_id or "default",
        difficulty = opt.difficulty or "NORMAL",
        stage = opt.stage or 1,
        character = opt.character or "default",
        seed = opt.seed or 0,
        date = os.date("%Y-%m-%dT%H:%M:%S"),
        frames = {},
        checksums = {},
    }
end

---Create an empty frame data snapshot.
---@return STG.Replay.FrameData
function M.NewFrameData()
    return {
        up = false,
        down = false,
        left = false,
        right = false,
        shoot = false,
        bomb = false,
        special = false,
        slow = false,
        pause = false,
        skip = false,
    }
end

-- ========================================
-- Recorder
-- ========================================

---@class STG.Replay.Recorder
---@field data STG.Replay.Data
---@field recording boolean
---@field frame_count number
local Recorder = Core.Class()
M.Recorder = Recorder

function Recorder:init(data)
    self.data = data or M.NewData()
    self.recording = false
    self.frame_count = 0

    -- Register for Frame.Before at highest priority to capture input before game logic
    self._event_name = "STG.Replay.Recorder"
    Core.MainLoop.AddEvent("Frame", "Before", {
        name = self._event_name,
        func = function()
            if not self.recording then
                return
            end
            self:recordFrame()
        end,
        level = -10000,
    })
end

function Recorder:start(seed)
    self.recording = true
    self.frame_count = 0
    self.data.frames = {}
    self.data.checksums = {}
    self.data.seed = seed or 0
    self.data.date = os.date("%Y-%m-%dT%H:%M:%S")
    Event.Fire(Event.Group.REPLAY_START)
end

function Recorder:stop()
    self.recording = false
    Event.Fire(Event.Group.REPLAY_STOP)
end

---Record a single frame of input and state.
function Recorder:recordFrame()
    self.frame_count = self.frame_count + 1
    local Input = Core.Input

    local frame = M.NewFrameData()
    frame.up = Input.ButtonPressed("Player.MoveUp")
    frame.down = Input.ButtonPressed("Player.MoveDown")
    frame.left = Input.ButtonPressed("Player.MoveLeft")
    frame.right = Input.ButtonPressed("Player.MoveRight")
    frame.shoot = Input.ButtonPressed("Player.Shoot")
    frame.bomb = Input.ButtonPressed("Player.Bomb")
    frame.special = Input.ButtonPressed("Player.Special")
    frame.slow = Input.ButtonPressed("Player.Slow")
    frame.pause = Input.ButtonPressed("Player.Pause")
    frame.skip = Input.ButtonPressed("Player.Skip")

    table.insert(self.data.frames, frame)

    -- Periodic checksum
    if self.frame_count % Constants.REPLAY.DESYNC_CHECK_INTERVAL == 0 then
        self:recordChecksum()
    end
end

function Recorder:recordChecksum()
    local player = STG.Player.Get()
    if not player then
        return
    end
    local checksum = {
        frame = self.frame_count,
        x = player.x,
        y = player.y,
    }
    table.insert(self.data.checksums, checksum)
end

---Save replay to file.
---@param filepath string
function Recorder:save(filepath)
    if not self.data or #self.data.frames == 0 then
        return false
    end
    local dir = Core.Data.GetPath() .. "/replays/"
    Core.VFS.CreateDirectory(dir)
    local fullpath = filepath or (dir .. self.data.date:gsub(":", "-") .. ".json")
    local f = assert(io.open(fullpath, "w"))
    f:write(Json.Serialize(self.data))
    f:close()
    return true
end

---Load replay data from file.
---@param filepath string
---@return STG.Replay.Data|nil
function Recorder.load(filepath)
    local f, msg = io.open(filepath, "r")
    if not f then
        return nil
    end
    local data = Json.Decode(f:read("*a"))
    f:close()
    return data
end

function Recorder:isRecording()
    return self.recording
end

function Recorder:getFrameCount()
    return self.frame_count
end

function Recorder:destroy()
    Core.MainLoop.RemoveEvent("Frame", "Before", self._event_name)
    self.recording = false
end

-- ========================================
-- Player (replay playback)
-- ========================================

---@class STG.Replay.Player
---@field data STG.Replay.Data
---@field playing boolean
---@field current_frame number
---@field speed number Playback speed multiplier
---@field paused boolean
---@field desynced boolean
local ReplayPlayer = Core.Class()
M.Player = ReplayPlayer

function ReplayPlayer:init(data)
    self.data = data
    self.playing = false
    self.current_frame = 0
    self.speed = 1
    self.paused = false
    self.desynced = false
    self._event_name = "STG.Replay.Player"
    self._frame_accumulator = 0

    -- Override input at highest priority
    Core.MainLoop.AddEvent("Frame", "Gameplay", {
        name = self._event_name,
        func = function()
            if not self.playing or self.paused then
                return
            end
            self._frame_accumulator = self._frame_accumulator + self.speed
            while self._frame_accumulator >= 1 do
                self:advanceFrame()
                self._frame_accumulator = self._frame_accumulator - 1
            end
        end,
        level = -10000,
    })
end

function ReplayPlayer:start()
    self.playing = true
    self.current_frame = 0
    self.paused = false
    self.desynced = false
    self._frame_accumulator = 0
    Event.Fire(Event.Group.REPLAY_START)
end

function ReplayPlayer:stop()
    self.playing = false
    Event.Fire(Event.Group.REPLAY_STOP)
end

function ReplayPlayer:pause()
    self.paused = true
end

function ReplayPlayer:resume()
    self.paused = false
end

function ReplayPlayer:togglePause()
    self.paused = not self.paused
end

function ReplayPlayer:setSpeed(s)
    self.speed = max(0.25, min(8, s or 1))
end

function ReplayPlayer:advanceFrame()
    self.current_frame = self.current_frame + 1
    if self.current_frame > #self.data.frames then
        self:stop()
        return
    end

    -- Check for desync at intervals
    if self.current_frame % Constants.REPLAY.DESYNC_CHECK_INTERVAL == 0 then
        self:checkSync()
    end
end

---Get the recorded input for the current frame.
---@return STG.Replay.FrameData|nil
function ReplayPlayer:getCurrentInput()
    if not self.playing or self.current_frame < 1 then
        return nil
    end
    return self.data.frames[self.current_frame]
end

---Check sync by comparing player position with recorded checksum.
function ReplayPlayer:checkSync()
    local player = STG.Player.Get()
    if not player then
        return
    end
    for _, cs in ipairs(self.data.checksums or {}) do
        if cs.frame == self.current_frame then
            local dx = math.abs((cs.x or 0) - (player.x or 0))
            local dy = math.abs((cs.y or 0) - (player.y or 0))
            if dx > 0.5 or dy > 0.5 then
                self.desynced = true
                Event.Fire(Event.Group.REPLAY_DESYNC, self.current_frame, dx, dy)
            end
            Event.Fire(Event.Group.REPLAY_SYNC, self.current_frame, dx, dy)
            return
        end
    end
end

---Get replay progress as 0-1.
---@return number
function ReplayPlayer:getProgress()
    if not self.data or #self.data.frames == 0 then
        return 0
    end
    return self.current_frame / #self.data.frames
end

function ReplayPlayer:getStatus()
    return {
        playing = self.playing,
        paused = self.paused,
        current_frame = self.current_frame,
        total_frames = #self.data.frames,
        progress = self:getProgress(),
        speed = self.speed,
        desynced = self.desynced,
    }
end

function ReplayPlayer:destroy()
    Core.MainLoop.RemoveEvent("Frame", "Gameplay", self._event_name)
    self.playing = false
end

-- ========================================
-- Input Override (for playback)
-- ========================================

---Check if input should come from replay rather than real hardware.
---@return STG.Replay.FrameData|nil
function M.GetPlaybackInput()
    -- This is called by the Player input component during replay playback.
    -- The component checks STG.Replay for an active playback session.
    return nil
end

---Check if recording is active.
---@return boolean
function M.IsRecording()
    return false
end

---Check if replay playback is active.
---@return boolean
function M.IsReplaying()
    return false
end

require("STG.Replay.UI")

return M
