---@class Core.System.Clipboard
local M = {}
Core.System.Clipboard = M

local clipboard = require("lstg.Clipboard")

M.HasText = clipboard.hasText
M.GetText = clipboard.getText
M.SetText = clipboard.setText