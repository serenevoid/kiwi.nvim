local config = require("kiwi.config")
local utils = require("kiwi.utils")
local sep = require("plenary.path").path.sep

local M = {}

-- Open diary index file in the current tab
M.open_diary_index = function()
	utils.prompt_folder(config)
	local diary_path = config.path .. sep .. "diary"
	local buffer_number = vim.fn.bufnr(diary_path .. sep .. "index.md", true)
	vim.api.nvim_win_set_buf(0, buffer_number)
	local data = utils.generate_diary_index(diary_path)
	vim.api.nvim_buf_set_lines(buffer_number, 0, -1, false, data)
	local opts = { noremap = true, silent = true, nowait = true }
	vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", ":lua require(\"kiwi\").open_link()<CR>", opts)
end

M.open_diary_new = function()
	utils.prompt_folder(config)
	local date = os.date("%Y%m%d")
	local filepath = config.path .. sep .. "diary" .. sep .. date .. ".md"
	local buffer_number = vim.fn.bufnr(filepath, true)
	vim.api.nvim_win_set_buf(0, buffer_number)
end

return M
