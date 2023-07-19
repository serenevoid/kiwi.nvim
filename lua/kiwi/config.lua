local config = {
  path = "",
}

config.get = function (key)
  return config[key]
end

config.set = function (key, value)
  config[key] = value
end

return config
