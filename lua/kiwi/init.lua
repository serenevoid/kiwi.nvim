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
  local opts = { noremap = true, silent = true, nowait = true }
  vim.api.nvim_buf_set_keymap(0, "v", "<CR>", ":'<,'>lua require(\"kiwi\").create_or_open_wiki_file()<CR>", opts)
  vim.api.nvim_buf_set_keymap(0, "n", "<CR>", ":lua require(\"kiwi\").open_link(true)<CR>", opts)

end

-- Open diary index file in the current tab
M.open_diary_index = function()
  if config.get("path") == "" then
    M.setup()
  end
  local diary_path = config.get("path") .. sep .. "diary"
  local buffer_number = vim.fn.bufnr(diary_path .. sep .. "index.md", true)
  vim.api.nvim_win_set_buf(0, buffer_number)
  local files = utils.list_directory(diary_path)
  local months = { "January", "February", "March", "April", "May", "June", "July",
    "August", "September", "October", "November", "December" }
  local data = { "# Diary" }
  local date = {}
  for _, filename in ipairs(files) do
    if (filename ~= "index.md") then
      if (filename:sub(1, 4) ~= date[0]) then
        table.insert(data, "")
        date[0] = filename:sub(1, 4)
        table.insert(data, "## " .. date[0])
      end
      if (filename:sub(5, 6) ~= date[1]) then
        table.insert(data, "")
        date[1] = filename:sub(5, 6)
        table.insert(data, "### " .. months[tonumber(date[1])])
      end
      date[1] = filename:sub(5, 6)
      table.insert(data, "[" .. filename:sub(1,8) .. "](./" .. filename .. ")")
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, data)
  end
  local opts = { noremap = true, silent = true, nowait = true }
  vim.api.nvim_buf_set_keymap(0, "n", "<CR>", ":lua require(\"kiwi\").open_link(false)<CR>", opts)
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
  local buffer_number = vim.fn.bufnr(config.get("path") .. sep .. filename, true)
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
      filename = config.get("path") .. subfolder .. filename:sub(2, -1)
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
  if config.get("path") == "" then
    M.setup()
  end
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
  local filepath = config.get("path") .. sep .. "diary" .. sep .. date .. ".md"
  local bufnr = vim.fn.bufnr(filepath, true)
  vim.api.nvim_win_set_buf(0, bufnr)
end

return M
