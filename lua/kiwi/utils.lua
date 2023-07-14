local Path = require("plenary.path")

local M = {}

local home = ""

-- Get Home path
local get_home = function()
  if vim.loop.os_uname().sysname == "Windows_NT"
  then
    return require("os").getenv("USERPROFILE") or ""
  else
    return require("os").getenv("HOME") or ""
  end
end

-- Get the default Wiki folder path
M.get_wiki_path = function()
  if home == "" then
    home = get_home()
  end
  local default_dir = home .. Path.path.sep .. "wiki"
  return default_dir
end

-- Create wiki folder and the diary folder inside it
M.ensure_directories = function(wiki_path)
  local path = Path:new(wiki_path)
  if not path:exists() then
    path:mkdir()
  end
  path = Path:new(wiki_path .. Path.path.sep .. "diary")
  if not path:exists() then
    path:mkdir()
  end
end

return M
