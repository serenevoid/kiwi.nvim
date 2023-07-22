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

local change_state = function (line, bound, given_state)
  local state = ""
  if given_state ~= nil then
    state = given_state
  else
    state = swap_state(line:sub(bound + 1, bound + 1))
  end
  local newline = line:sub(0, bound) ..
  state .. line:sub(bound + 2, string.len(line))
  vim.api.nvim_set_current_line(newline)
  print(state)
  return state
end

function Toggle_children (line_number, bound, state)
  if bound == nil then
    vim.print("E: Not a todo task")
    return
  end
  local line = vim.fn.getline(line_number + 1)
  local new_bound = get_bound(line)
  if new_bound ~= nil and new_bound > bound then
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, {cursor[1] + 1, cursor[2]})
    change_state(line, new_bound, state)
    Toggle_children(line_number + 1, bound, state)
  end
end

todo.toggle = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local bound = get_bound(line)
  if bound == nil then
    vim.print("E: Not a todo task")
    return
  end
  local state = change_state(line, bound)
  Toggle_children(cursor[1], bound, state)
  vim.api.nvim_win_set_cursor(0, cursor)
end

return todo
