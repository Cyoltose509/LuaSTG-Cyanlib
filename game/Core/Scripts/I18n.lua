---@class Core.I18n
local M = {}
Core.I18n = M

M.currentLanguage = nil

M.languageMap = {}
M.languageSet = {}

M.languageDirectory = {}

---@type string[]
M.text = {}
---@type string[]
M.jargon = {}
---@type fun[]
M.command = {}

local function SkimDirectory(dir)
    for _, files in ipairs(Core.VFS.EnumFiles(dir, nil, true)) do
        if files[2] then
            SkimDirectory(files[1])
        elseif files[1]:lower():find("%.lua$") then
            local data = Core.VFS.DoFile(files[1])
            if data.isJargon then
                data.isJargon = nil
                M.RegisterJargon(data)
            else
                M.RegisterKeys(data)
            end
        elseif files[1]:lower():find("%.json$") then
            local data = Core.Lib.Json.Decode(Core.VFS.LoadTextFile(files[1]))
            if data.isJargon then
                data.isJargon = nil
                M.RegisterJargon(data)
            else
                M.RegisterKeys(data)
            end
        end
    end
end

function M.Reload()
    local lang = M.currentLanguage
    if not lang then
        return
    end
    M.text = {}
    M.jargon = {}

    for _, dir in pairs(M.languageDirectory) do
        SkimDirectory(dir .. lang .. "/")
    end
end

function M.SetLanguage(lang)
    if not M.languageSet[lang] then
        error(("Language %s is not registered!"):format(lang))
    end
    M.currentLanguage = lang
    M.Reload()
end

---注册能够自动扫描多语言文件的目录
---Register a directory that can automatically scan for language files
function M.RegisterDirectory(name, dir)
    M.languageDirectory[name] = dir
end

function M.UnregisterDirectory(name)
    M.languageDirectory[name] = nil
end

function M.RegisterLanguage(lang)
    if M.languageSet[lang] then
        return
    end
    table.insert(M.languageMap, lang)
    M.languageSet[lang] = true
end

function M.RegisterKey(key, value)
    M.text[key] = value
end

function M.RegisterKeys(tbl)
    Core.Lib.Table.Merge(M.text, tbl)
end

---@overload fun(tbl: table)
---@param key string
---@param value string
function M.RegisterJargon(key, value)
    if type(key) == "table" then
        Core.Lib.Table.Merge(M.jargon, key)
    else
        M.jargon[key] = value
    end
end

---@param pattern string
---@param repl function
---注册命令
---命令是不会被重置的
---@see string.gsub
function M.RegisterCommand(pattern, repl)
    M.command[pattern] = repl
end

function M.GetAvailableLanguages()
    return Core.Lib.Table.Copy(M.languageMap)
end

---@param key string
---@return string
---获取纯净的多语言文本，不带术语与命令
function M.GetRaw(key)
    return M.text[key] or key
end

function M.Exists(key)
    return M.text[key] ~= nil
end

---获取带有术语的多语言文本
---@return string
function M.Get(key)
    if key == "" then
        return key
    end
    local text = M.text[key] or key
    if not text:find("/") then
        return text
    end
    for kw, func in pairs(M.command) do
        text = text:gsub("/" .. kw, func)
    end
    for i, l in pairs(M.jargon) do
        text = text:gsub("/" .. i, l)
    end
    return text
end


