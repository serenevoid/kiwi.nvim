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

local create_dirs = function (wiki_path)
  local path = vim.fs.joinpath(vim.loop.os_homedir(), wiki_path)
  vim.uv.fs_mkdir(path, 448)
end

-- Get the default Wiki folder path
utils.get_wiki_path = function()
  local default_dir = vim.fs.joinpath(vim.loop.os_homedir, "wiki")
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
  for i = cursor[2] + 1, 0, -1 do
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

utils.choose_wiki = function (folders)
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
          path = vim.fs.joinpath(vim.loop.os_homedir(), props.path)
        end
      end
  end)
  return path
end

-- Show prompt if multiple wiki path found or else choose default path
utils.prompt_folder = function (config)
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

return utils
