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

local is_marked_done = function (line, bound)
    local state = line:sub(bound + 1, bound + 1)
    if state == " " then
      return true
    elseif state == "x" then
      return false
    else
      return nil
    end
end

local mark_done = function (line, bound)
  local newline = line:sub(0, bound) ..
  "x" .. line:sub(bound + 2, string.len(line))
  vim.api.nvim_set_current_line(newline)
end

local mark_undone = function (line, bound)
  local newline = line:sub(0, bound) ..
  " " .. line:sub(bound + 2, string.len(line))
  vim.api.nvim_set_current_line(newline)
end

local function set_children (line_number, bound, done)
  if bound == nil then
    vim.print("E: Not a todo task")
    return
  end
  local line = vim.fn.getline(line_number + 1)
  local new_bound = get_bound(line)
  if new_bound ~= nil and new_bound > bound then
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, {cursor[1] + 1, cursor[2]})
    if done then
      mark_done(line, new_bound)
      set_children(cursor[1] + 1, bound, true)
    else
      mark_undone(line, new_bound)
      set_children(cursor[1] + 1, bound, false)
    end
  end
end

local reach_bottom = function (bound)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local new_bound = get_bound(line)
  if new_bound < bound then
    print("reached end")
  end
end

function Toggle_parent (line_number, bound, done)
end

todo.toggle = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.fn.getline(cursor[1])
  local bound = get_bound(line)
  if bound == nil then
    vim.print("E: Not a todo task")
    return
  end
  if is_marked_done(line, bound) then
    mark_done(line, bound)
    set_children(cursor[1], bound, true)
  else
    mark_undone(line, bound)
    set_children(cursor[1], bound, false)
  end
  -- Toggle_parent(cursor[1], bound)
  -- reach_bottom(bound)
  vim.api.nvim_win_set_cursor(0, cursor)
end

return todo
