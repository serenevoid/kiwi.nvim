local Path = require("plenary.path")

local utils = {}

local home = ""

-- Setup wiki folder
utils.setup = function(opts, config)
  if opts ~= nil then
    config.folders = opts
  else
    config.path = utils.get_wiki_path()
  end
  utils.ensure_directories(config)
end

-- Get Home path
local get_home = function()
  if vim.loop.os_uname().sysname == "Windows_NT"
  then
    return require("os").getenv("USERPROFILE") or ""
  else
    return require("os").getenv("HOME") or ""
  end
end

local create_dirs = function (wiki_path)
  local path = Path:new(wiki_path)
  if not path:exists() then
    path:mkdir()
  end
end

-- Get the default Wiki folder path
utils.get_wiki_path = function()
  if home == "" then
    home = get_home()
  end
  local default_dir = home .. Path.path.sep .. "wiki"
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
  local filename_bounds = {}
  local found_opening = false
  for i = cursor[2], 0, -1 do
    if (line:sub(i, i) == ")") then
      return nil
    end
    if (line:sub(i, i) == "(") then
      filename_bounds[1] = i + 1
      break
    end
    if (line:sub(i, i) == "[") then
      found_opening = true
      break
    end
  end
  if not found_opening then
    return nil
  end
  for i = cursor[2] + 2, line:len(), 1 do
    if (line:sub(i, i) == "[") then
      return nil
    end
    if (line:sub(i, i) == "(") then
      filename_bounds[1] = i + 1
    end
    if (line:sub(i, i) == ")") then
      filename_bounds[2] = i - 1
      break
    end
  end
  if (filename_bounds[1] ~= nil and filename_bounds[2] ~= nil) then
    return line:sub(unpack(filename_bounds))
  end
end

utils.choose_wiki = function (folders, total)
  local prompt_text = 'Available Wiki:\n'
  for index, props in pairs(folders) do
    prompt_text = prompt_text .. index .. ". " .. props.name .. "\n"
  end
  prompt_text = prompt_text .. "Choose wiki (default: 1): "
  local path = ""
  vim.ui.input(
    { prompt = prompt_text },
    function(input)
      input = tonumber(input)
      if type(input) ~= "number" or total < (input) then
        print("\nInvalid index")
        input = 1
      end
      path = folders[input].path
    end
  )
  return path
end

-- Show prompt if multiple wiki path found or else choose default path
utils.prompt_folder = function (config)
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
    utils.setup(nil, config)
  end
end

return utils
