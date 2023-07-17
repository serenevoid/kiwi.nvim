local Path = require("plenary.path")
local sep = Path.path.sep
local config = require("kiwi.config")
local utils = require("kiwi.utils")

local M = {}

-- Setup wiki folder
M.setup = function(opts)
  if opts ~= nil and opts.path ~= nil then
    config.set("path", opts.path)
  else
    config.set("path", utils.get_wiki_path())
  end
  utils.ensure_directories(config.get("path"))
end

-- Open wiki index file in the current tab
M.open_wiki_index = function()
  if config.get("path") == "" then
    M.setup()
  end
  local wiki_index_path = config.get("path") .. sep .. "index.md"
  local buffer_number = vim.fn.bufnr(wiki_index_path, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  utils.set_buf_keymaps(0)
end

-- Open diary index file in the current tab
M.open_diary_index = function()
  if config.get("path") == "" then
    M.setup()
  end
  local diary_index_path = config.get("path") .. sep .. "diary" .. sep .. "index.md"
  local buffer_number = vim.fn.bufnr(diary_index_path, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  utils.set_buf_keymaps(0)
end

-- Create a new Wiki entry in Journal folder on highlighting word and pressing <CR>
M.create_or_open_wiki_file = function()
  local selection_start = vim.fn.getpos("'<")
  local selection_end = vim.fn.getpos("'>")
  local line = vim.fn.getline(selection_start[2], selection_end[2])
  local name = line[1]:sub(selection_start[3], selection_end[3])
  local filename = name:gsub(" ", "_"):gsub("\\", "") .. ".md"
  local new_mkdn = "[" .. name .. "]"
  if string.find(vim.api.nvim_buf_get_name(0), "/diary/") then
    new_mkdn = new_mkdn .. "(../" .. filename .. ")"
  else
    new_mkdn = new_mkdn .. "(./" .. filename .. ")"
  end
  local newline = line[1]:sub(0, selection_start[3] - 1) ..
      new_mkdn .. line[1]:sub(selection_end[3] + 1, string.len(line[1]))
  vim.api.nvim_set_current_line(newline)
  local buffer_number = vim.fn.bufnr(config.get("path") .. sep .. filename, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  utils.set_buf_keymaps(buffer_number)
end

M.open_link = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local filename = utils.is_link(cursor, line)
  if (filename ~= nil and filename:len() > 1) then
    filename = filename:gsub(" ", "_")
    local bufnr = vim.fn.bufnr(config.get("path") .. sep .. filename .. ".md", true)
    if bufnr ~= -1 then
      vim.api.nvim_win_set_buf(0, bufnr)
      utils.set_buf_keymaps(bufnr)
    end
  end
end

return M
