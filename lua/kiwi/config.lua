local M = {}

local config = {
  path = "",
}

M.get = function (key)
  return config[key]
end

M.set = function (key, value)
  config[key] = value
end

return M
