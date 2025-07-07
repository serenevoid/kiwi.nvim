local utils = {}

-- Setup wiki folder
utils.setup = function(opts, config)
  if opts ~= nil then
    config.folders = opts
  else
    config.path = utils.get_wiki_path()
  end
  utils.ensure_directories(config)
end

local create_dirs = function(wiki_path)
  local path = vim.fs.joinpath(vim.loop.os_homedir(), wiki_path)
  vim.uv.fs_mkdir(path, 448)
end

-- Get the default Wiki folder path
utils.get_wiki_path = function()
  local default_dir = vim.fs.joinpath(vim.loop.os_homedir(), "wiki")
  return default_dir
end

-- Create wiki folder
utils.ensure_directories = function(config)
  if (config.folders ~= nil) then
    for _, props in ipairs(config.folders) do
      create_dirs(props.path)
    end
  else
    create_dirs(config.path)
  end
end

-- Check if the cursor is on a link on the line
utils.is_link = function(cursor, line)
  cursor[2] = cursor[2] + 1 -- because vim counts from 0 but lua from 1

  -- Pattern for [title](file)
  local pattern1 = "%[(.-)%]%(<?([^)>]+)>?%)"
  local start_pos = 1
  while true do
    local match_start, match_end, _, file = line:find(pattern1, start_pos)
    if not match_start then break end
    start_pos = match_end + 1 -- Move past the current match
    file = utils._is_cursor_on_file(cursor, file, match_start, match_end)
    if file then return file end
  end

  -- Pattern for [[file]]
  local pattern2 = "%[%[(.-)%]%]"
  start_pos = 1
  while true do
    local match_start, match_end, file = line:find(pattern2, start_pos)
    if not match_start then break end
    start_pos = match_end + 1 -- Move past the current match
    file = utils._is_cursor_on_file(cursor, file, match_start, match_end)
    if file then return "./" .. file end
  end

  return nil
end

-- Private function to determine if cursor is placed on a valid file
utils._is_cursor_on_file = function(cursor, file, match_start, match_end)
  if cursor[2] >= match_start and cursor[2] <= match_end then
    if not file:match("%.md$") then
      file = file .. ".md"
    end
    return file
  end
end

utils.choose_wiki = function(folders)
  local path = ""
  local list = {}
  for i, props in pairs(folders) do
    list[i] = props.name
  end
  vim.ui.select(list, {
    prompt = 'Select wiki:',
    format_item = function(item)
      return item
    end,
  }, function(choice)
    for _, props in pairs(folders) do
      if props.name == choice then
        if vim.uv.fs_realpath(props.path) then
          path = props.path
        else
          path = vim.fs.joinpath(vim.loop.os_homedir(), props.path)
        end
      end
    end
  end)
  return path
end

-- Show prompt if multiple wiki path found or else choose default path
utils.prompt_folder = function(config)
  if config.folders ~= nil then
    local count = 0
    for _ in ipairs(config.folders) do count = count + 1 end
    if count > 1 then
      config.path = utils.choose_wiki(config.folders)
    else
      config.path = config.folders[1].path
    end
  end
end

-- Resolves a path string from the config into a full, absolute path.
-- @param path_str (string): The path from the configuration
-- @return (string): The resolved absolute path.
utils.resolve_path = function(filename, config)
  if not filename or filename == "" then
    return nil
  end

  local expanded_path = vim.fn.expand(filename)
  if vim.fn.isdirectory(expanded_path) == 1 then
    return expanded_path
  end

  return substitute_path(filename, config)
end

function substitute_path(filename, config)
  local base_path = vim.fn.expand('%:p:h')

  if filename:sub(1, 2) == "./" then
    filename = vim.fs.joinpath(base_path, filename:sub(3, -1))
  elseif filename:sub(1, 3) == "../" then
    while filename:sub(1, 3) == "../" do
      base_path = vim.fn.fnamemodify(base_path, ":h")
      filename = filename:sub(4, -1)
    end
    if #base_path < #config.path then -- Check not to go out of this wiki
      base_path = config.path
    end
    filename = vim.fs.joinpath(base_path, filename)
  elseif filename:sub(1, 1) == "/" then
    filename = vim.fs.joinpath(config.path, filename:sub(2, -1))
    return filename -- Absolute path, no need to modify
  else
    filename = vim.fs.joinpath(base_path, filename)
  end

  return filename
end

return utils
