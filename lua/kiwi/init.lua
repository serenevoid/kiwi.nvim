local config = require("kiwi.config")
local utils = require("kiwi.utils")
local todo = require("kiwi.todo")
local wiki = require("kiwi.wiki")
local diary = require("kiwi.diary")

local M = {}

M.todo = todo
M.utils = utils
M.VERSION = "0.2.0"

M.setup = function(opts)
	utils.setup(opts, config)
end

M.open_wiki_index = wiki.open_wiki_index
M.open_diary_index = diary.open_diary_index
M.create_or_open_wiki_file = wiki.create_or_open_wiki_file
M.open_link = wiki.open_link
M.open_diary_new = diary.open_diary_new

return M
