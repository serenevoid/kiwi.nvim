local todo = {}

local get_bound = function (line)
  local bound = 0
  for i = 0, string.len(line) - 1, 1 do
      local char = line:sub(i, i)
      if char == "[" then
          bound = i
          break
      end
      if i == 100 then
          error("Limit exceeded", 1)
          break
      end
  end
  if line:sub(bound + 2, bound + 3) ~= "] " then
    return nil
  end
  return bound
end

local swap_state = function (state)
    if state == " " then
      return "x"
    end
    if state == "x" then
      return " "
    end
end

todo.toggle = function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.fn.getline(cursor[1])
    local bound = get_bound(line)
    if bound == nil then
      vim.print("E: Not a togo task")
      return
    end
    local state = line:sub(bound + 1, bound + 1)
    state = swap_state(state)
    local newline = line:sub(0, bound) ..
        state .. line:sub(bound + 2, string.len(line))
    vim.api.nvim_set_current_line(newline)
end

return todo
