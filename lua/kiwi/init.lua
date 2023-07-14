local Path = require("plenary.path")
local config = require("kiwi.config")
local utils = require("kiwi.utils")

local M = {}

-- Setup wiki folder
M.setup = function (opts)
  if opts ~= nil and opts.path ~= nil then
    config.set("path", opts.path)
  else
    config.set("path", utils.get_wiki_path())
  end
  utils.ensure_directories(config.get("path"))
end

-- Open wiki index file in the current tab
M.open_wiki_index = function ()
  if config.get("path") == "" then
    M.setup()
  end
  local wiki_index_path = config.get("path") .. Path.path.sep .. "index.md"
  local buffer_number = vim.fn.bufnr(wiki_index_path, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
end

M.open_diary_index = function ()
  if config.get("path") == "" then
    M.setup()
  end
  local diary_index_path = config.get("path") .. Path.path.sep .. "diary" .. Path.path.sep .. "index.md"
  local buffer_number = vim.fn.bufnr(diary_index_path, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
end

return M
