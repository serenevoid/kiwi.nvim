local Path = require("plenary.path")
local sep = Path.path.sep
local config = require("kiwi.config")
local utils = require("kiwi.utils")

local M = {}

-- Setup wiki folder
M.setup = function(opts)
  if opts ~= nil then
    config.folders = opts
  else
    config.path = utils.get_wiki_path()
  end
  utils.ensure_directories(config)
end

local load_wiki = function ()
  if config.folders ~= nil then
    local count = 0
    for _ in ipairs(config.folders) do count = count + 1 end
    if count > 1 then
      config.path = utils.choose_wiki(config.folders, count)
    else
      config.path = config.folders[1].path
    end
  end
  if config.path == "" then
    M.setup()
  end
end

-- Open wiki index file in the current tab
M.open_wiki_index = function()
  load_wiki()
  local wiki_index_path = config.path .. sep .. "index.md"
  local buffer_number = vim.fn.bufnr(wiki_index_path, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  local opts = { noremap = true, silent = true, nowait = true }
  vim.api.nvim_buf_set_keymap(buffer_number, "v", "<CR>", ":'<,'>lua require(\"kiwi\").create_or_open_wiki_file()<CR>", opts)
  vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", ":lua require(\"kiwi\").open_link(true)<CR>", opts)
end

-- Open diary index file in the current tab
M.open_diary_index = function()
  load_wiki()
  local diary_path = config.path .. sep .. "diary"
  local buffer_number = vim.fn.bufnr(diary_path .. sep .. "index.md", true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  local data = utils.generate_diary_index(diary_path)
  vim.api.nvim_buf_set_lines(buffer_number, 0, -1, false, data)
  local opts = { noremap = true, silent = true, nowait = true }
  vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", ":lua require(\"kiwi\").open_link(false)<CR>", opts)
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
  local newline = line[1]:sub(0, selection_start[3] - 1) ..
      new_mkdn .. line[1]:sub(selection_end[3] + 1, string.len(line[1]))
  vim.api.nvim_set_current_line(newline)
  local buffer_number = vim.fn.bufnr(config.path .. sep .. filename, true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  local opts = { noremap = true, silent = true, nowait = true }
  vim.api.nvim_buf_set_keymap(buffer_number, "v", "<CR>", ":'<,'>lua require(\"kiwi\").create_or_open_wiki_file()<CR>", opts)
  vim.api.nvim_buf_set_keymap(buffer_number, "n", "<CR>", ":lua require(\"kiwi\").open_link(true)<CR>", opts)
end

-- Open a link under the cursor
M.open_link = function(isWiki)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local filename = utils.is_link(cursor, line)
  if (filename ~= nil and filename:len() > 1) then
    local subfolder = "/diary"
    if isWiki then
      subfolder = ""
    end
    if (filename:sub(1, 2) == "./") then
      filename = config.path .. subfolder .. filename:sub(2, -1)
    end
    local bufnr = vim.fn.bufnr(filename, true)
    if bufnr ~= -1 then
      vim.api.nvim_win_set_buf(0, bufnr)
      local opts = { noremap = true, silent = true, nowait = true }
      vim.api.nvim_buf_set_keymap(bufnr, "v", "<CR>", ":'<,'>lua require(\"kiwi\").create_or_open_wiki_file()<CR>", opts)
      vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", ":lua require(\"kiwi\").open_link(" .. tostring(isWiki) .. ")<CR>", opts)
    end
  else
    vim.print("E: Cannot find file")
  end
end

M.open_diary_new = function()
  load_wiki()
  local offset
  vim.ui.input(
  { prompt = 'Date Offset:\n* Positive values for future diary\n* Negative values for past diaries\nOffset Value: ' },
    function(input)
      offset = tonumber(input)
    end)
  local date = os.date("%Y%m%d")
  if offset ~= nil then
    local date_value = tonumber(date)
    date = tostring(date_value + offset)
  end
  local filepath = config.path .. sep .. "diary" .. sep .. date .. ".md"
  local bufnr = vim.fn.bufnr(filepath, true)
  vim.api.nvim_win_set_buf(0, bufnr)
end

return M
