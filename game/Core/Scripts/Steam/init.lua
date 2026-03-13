---@class Core.Steam
local M = {}
Core.Steam = M

local _, steam = pcall(require, "steam")

---@alias uint32 number
---@alias uint64 string
---@alias AppId_t uint32
---@alias DepotId_t uint32
---@alias PublishedFileId_t uint64
---@alias UGCQueryHandle_t uint64
---@alias UGCUpdateHandle_t uint64
---@alias UGCHandle_t uint64
---@alias SteamAPICall_t uint64
---@alias SteamLeaderboard_t uint64
---@alias SteamLeaderboardEntries_t uint64


---@class ELeaderboardUploadScoreMethod
M.ELeaderboardUploadScoreMethod = {
    k_ELeaderboardUploadScoreMethodNone = 0,
    k_ELeaderboardUploadScoreMethodKeepBest = 1,
    k_ELeaderboardUploadScoreMethodForceUpdate = 2,
}

---@class ELeaderboardDataRequest
M.ELeaderboardDataRequest = {
    k_ELeaderboardDataRequestGlobal = 0,
    k_ELeaderboardDataRequestGlobalAroundUser = 1,
    k_ELeaderboardDataRequestFriends = 2,
    k_ELeaderboardDataRequestUsers = 3,
}

---@class ELeaderboardSortMethod
M.ELeaderboardSortMethod = {
    k_ELeaderboardSortMethodNone = 0,
    k_ELeaderboardSortMethodAscending = 1,
    k_ELeaderboardSortMethodDescending = 2,
}

---@class ELeaderboardDisplayType
M.ELeaderboardDisplayType = {
    k_ELeaderboardDisplayTypeNone = 0,
    k_ELeaderboardDisplayTypeNumeric = 1,
    k_ELeaderboardDisplayTypeTimeSeconds = 2,
    k_ELeaderboardDisplayTypeTimeMilliSeconds = 3,
}

---调用steam api获取服务器时间
---如果steam api不可用，则返回系统时间
function M.GetTime()
    if steam and steam.SteamUtils then
        return steam.SteamUtils.GetServerRealTime()
    else
        return os.time()
    end
end

---@param id string
function M.SetStat(id, type, value)
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.SetStat(id, type, value)
        steam.SteamUserStats.StoreStats()
    end
end

---设置steam成就
---@param id string
function M.SetAchievement(id)
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.SetAchievement(id)
        steam.SteamUserStats.StoreStats()
    end
end

---@param id string
function M.ClearAchievement(id)
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.ClearAchievements(id)
        steam.SteamUserStats.StoreStats()
    end
end

function M.GameOverlayActivated()
    if steam and steam.SteamFriends then
        return steam.SteamFriends.GameOverlayActivated()
    end
    return false
end

function M.ResetAllStats()
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.ResetAllStats(true)
    end
end

---处理回调
---将自动载入mainloop中
function M.Update()
    if steam and steam.SteamAPI then
        steam.SteamAPI.RunCallbacks()
    end
end

---保存并上传数据
---将自动在存档时调用
function M.StoreStats()
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.StoreStats()
    end
end

---@param url string
function M.OpenWebPage(url)
    if steam and steam.SteamFriends then
        steam.SteamFriends.ActivateGameOverlayToWebPage(url)
    else
        Core.System.OpenURL(url)
    end
end

function M.GetPersonaName()
    if steam and steam.SteamFriends then
        return steam.SteamFriends.GetPersonaName()
    else
        return "unknown"
    end
end

function M.GetSteamUILanguage()
    if steam and steam.SteamUtils then
        return steam.SteamUtils.GetSteamUILanguage()
    else
        return "english"
    end
end

---@class LeaderboardEntry_t
---@field m_steamIDUser number
---@field m_nGlobalRank number
---@field m_nScore number
---@field m_cDetails number
---@field m_hUGC UGCHandle_t
---@field m_pDetails number[]
---@class LeaderboardFindResult_t
---@field m_hSteamLeaderboard SteamLeaderboard_t
---@field m_bLeaderboardFound boolean


---获取排行榜
---@param callback fun(result:LeaderboardFindResult_t)
function M.FindLeaderboard(name, callback)
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.FindLeaderboard(name, callback)
    end
end

---获取或创建一个排行榜
---@param eLeaderboardSortMethod ELeaderboardSortMethod
---@param eLeaderboardDisplayType ELeaderboardDisplayType
---@param callback fun(result:LeaderboardFindResult_t)
function M.FindOrCreateLeaderboard(name, eLeaderboardSortMethod, eLeaderboardDisplayType, callback)
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.FindOrCreateLeaderboard(name, eLeaderboardSortMethod, eLeaderboardDisplayType, callback)
    end
end

---@class LeaderboardScoreUploaded_t
---@field m_bSuccess boolean
---@field m_hSteamLeaderboard SteamLeaderboard_t
---@field m_nScore number
---@field m_bScoreChanged boolean
---@field m_nGlobalRankNew number
---@field m_nGlobalRankPrevious number

---@param callback fun(result:LeaderboardScoreUploaded_t)
---@param hSteamLeaderboard SteamLeaderboard_t
---@param eLeaderboardUploadScoreMethod ELeaderboardUploadScoreMethod
---@param details number[]
---@param score number
---该API不稳定，暂时不推荐使用！
function M.UploadLeaderboardScore(hSteamLeaderboard, eLeaderboardUploadScoreMethod, score, details, callback)
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.UploadLeaderboardScore(hSteamLeaderboard, eLeaderboardUploadScoreMethod, score, details, callback)
    end
end

---@class LeaderboardScoresDownloaded_t
---@field m_hSteamLeaderboard SteamLeaderboard_t
---@field m_hSteamLeaderboardEntries SteamLeaderboardEntries_t
---@field m_cEntryCount number
---@param callback fun(result:LeaderboardScoresDownloaded_t)
---@param hSteamLeaderboard SteamLeaderboard_t
---@param eLeaderboardDataRequest ELeaderboardDataRequest
function M.DownloadLeaderboardEntries(hSteamLeaderboard, eLeaderboardDataRequest, rangeStart, rangeEnd, callback)
    if steam and steam.SteamUserStats then
        steam.SteamUserStats.DownloadLeaderboardEntries(hSteamLeaderboard, eLeaderboardDataRequest, rangeStart, rangeEnd, callback)
    end
end

---@return LeaderboardEntry_t[]
---@param hSteamLeaderboardEntries SteamLeaderboardEntries_t
---@param count number
---@param cDetailsMax number
function M.GetDownloadedLeaderboardEntry(hSteamLeaderboardEntries, count, cDetailsMax)
    if steam and steam.SteamUserStats then
        cDetailsMax = cDetailsMax or 64
        return steam.SteamUserStats.GetDownloadedLeaderboardEntry(hSteamLeaderboardEntries, count, cDetailsMax)
    else
        return {}
    end
end

Core.Data.Score.AddSaveAfterEvent("Steam.Update", 1000, M.StoreStats)
Core.MainLoop.AddEvent("Frame", "Before", {
    name = "Core.Update.Steam",
    func = M.Update,
})

