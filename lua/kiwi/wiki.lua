local config = require("kiwi.config")
local utils = require("kiwi.utils")

local M = {}

-- Open wiki index file in the current tab
M.open_wiki_index = function(name)
  if name == nil then
    utils.prompt_folder(config)
  else
    if config.folders ~= nil then
      for _, v in pairs(config.folders) do
        if v.name == name then
          config.path = v.path
        end
      end
    else
      require("kiwi").setup()
    end
  end
  local wiki_index_path = vim.fs.joinpath(config.path, "index.md")
  local buffer_number = vim.fn.bufnr(wiki_index_path, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  local opts = { noremap = true, silent = true, nowait = true }
  vim.api.nvim_buf_set_keymap(buffer_number, "v", "<CR>", ":'<,'>lua require(\"kiwi\").create_or_open_wiki_file()<CR>", opts)
  vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", ":lua require(\"kiwi\").open_link()<CR>", opts)
  vim.api.nvim_buf_set_keymap(buffer_number, "n", "<Tab>", ":let @/=\"\\\\[.\\\\{-}\\\\]\"<CR>nl", opts)
end

-- Create a new Wiki entry in Journal folder on highlighting word and pressing <CR>
M.create_or_open_wiki_file = function()
  local selection_start = vim.fn.getpos("'<")
  local selection_end = vim.fn.getpos("'>")
  local line = vim.fn.getline(selection_start[2], selection_end[2])
  local name = line[1]:sub(selection_start[3], selection_end[3])
  local filename = name:gsub(" ", "_"):gsub("\\", "") .. ".md"
  local new_mkdn = "[" .. name .. "]"
  new_mkdn = new_mkdn .. "(./" .. filename .. ")"
  local newline = line[1]:sub(0, selection_start[3] - 1) .. new_mkdn .. line[1]:sub(selection_end[3] + 1, string.len(line[1]))
  vim.api.nvim_set_current_line(newline)
  local buffer_number = vim.fn.bufnr(vim.fs.joinpath(config.path, filename), true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  local opts = { noremap = true, silent = true, nowait = true }
  vim.api.nvim_buf_set_keymap(buffer_number, "v", "<CR>", ":'<,'>lua require(\"kiwi\").create_or_open_wiki_file()<CR>", opts)
  vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", ":lua require(\"kiwi\").open_link()<CR>", opts)
  vim.api.nvim_buf_set_keymap(buffer_number, "n", "<Tab>", ":let @/=\"\\\\[.\\\\{-}\\\\]\"<CR>nl", opts)
end

-- Open a link under the cursor
M.open_link = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local filename = utils.is_link(cursor, line)
  if (filename ~= nil and filename:len() > 1) then
    if (filename:sub(1, 2) == "./") then
      filename = config.path .. utils.get_relative_path(config) .. filename:sub(2, -1)
    end
    local buffer_number = vim.fn.bufnr(filename, true)
    if buffer_number ~= -1 then
      vim.api.nvim_win_set_buf(0, buffer_number)
      local opts = { noremap = true, silent = true, nowait = true }
      vim.api.nvim_buf_set_keymap(buffer_number, "v", "<CR>", ":'<,'>lua require(\"kiwi\").create_or_open_wiki_file()<CR>", opts)
      vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", ":lua require(\"kiwi\").open_link()<CR>", opts)
      vim.api.nvim_buf_set_keymap(buffer_number, "n", "<Tab>", ":let @/=\"\\\\[.\\\\{-}\\\\]\"<CR>nl", opts)
    end
  else
    vim.print("E: Cannot find file")
  end
end

return M
