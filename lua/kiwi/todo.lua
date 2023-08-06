local todo = {}

local function get_bound (line)
  local bound = 0
  for i = 0, string.len(line) - 1, 1 do
    local char = line:sub(i, i)
    if char == "[" then
      bound = i
      break
    end
    if char ~= " " then
      break;
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

local function is_marked_done (line, bound)
    local state = line:sub(bound + 1, bound + 1)
    if state == "x" then
      return true
    elseif state == " " then
      return false
    else
      return nil
    end
end

local function mark_done (line, bound)
  local newline = line:sub(0, bound) ..
  "x" .. line:sub(bound + 2, string.len(line))
  vim.api.nvim_set_current_line(newline)
end

local function mark_undone (line, bound)
  local newline = line:sub(0, bound) ..
  " " .. line:sub(bound + 2, string.len(line))
  vim.api.nvim_set_current_line(newline)
end

local function toggle_children (line_number, bound, state)
  if bound == nil then
    vim.print("E: Not a todo task")
    return
  end
  local line = vim.fn.getline(line_number + 1)
  local new_bound = get_bound(line)
  if new_bound ~= nil and new_bound > bound then
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, {cursor[1] + 1, cursor[2]})
    if state == false then
      mark_undone(line, new_bound)
    else
      mark_done(line, new_bound)
    end
    toggle_children(line_number + 1, bound, state)
  end
end

local function find_parent (cursor, bound)
  local pseudo_cursor = cursor
  while true do
    pseudo_cursor = pseudo_cursor - 1
    local line = vim.fn.getline(pseudo_cursor)
    local new_bound = get_bound(line)
    if new_bound == nil then
      return nil
    end
    if new_bound < bound then
      return pseudo_cursor
    end
  end
end

local function is_children_complete (cursor, bound)
  local pseudo_cursor = cursor
  local state = true
  while true do
    local line = vim.fn.getline(pseudo_cursor + 1)
    local new_bound = get_bound(line)
    if new_bound == nil then
      return state
    else
      pseudo_cursor = pseudo_cursor + 1
    end
    if new_bound < bound then
      return state
    end
    if new_bound == bound then
      local response = is_marked_done(line, bound)
      if response ~= nil then
        state = state and response
      end
    end
  end
end

local function validate_parent_tasks (cursor, bound)
  local parent_pos = find_parent(cursor, bound)
  if parent_pos == nil then
    return
  end
  vim.api.nvim_win_set_cursor(0, {parent_pos, 0})
  local line = vim.fn.getline(parent_pos)
  local parent_bound = get_bound(line)
  if is_children_complete(parent_pos, bound) then
    mark_done(line, parent_bound)
  else
    mark_undone(line, parent_bound)
  end
  validate_parent_tasks(parent_pos, parent_bound)
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
    mark_undone(line, bound)
    toggle_children(cursor[1], bound, false)
  else
    mark_done(line, bound)
    toggle_children(cursor[1], bound, true)
  end
  vim.api.nvim_win_set_cursor(0, cursor)
  validate_parent_tasks(cursor[1], bound)
  vim.api.nvim_win_set_cursor(0, cursor)
end

return todo
