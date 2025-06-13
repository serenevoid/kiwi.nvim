local todo = {}

-- Cache the buffer line count for the duration of a single toggle operation to avoid redundant API calls.
local line_count_cache = 0

---
-- Retrieves the indentation level of a task on a given line.
-- @param line (string): The line content to inspect.
-- @return (number|nil): The indentation level, or nil if not a recognized task.
local function get_bound(line)
	if not line then
		return nil
	end

	-- Check for unordered list tasks, e.g., "* [ ] task" or "- [ ] task"
	local indent_str = line:match("^(%s*)[%*%-+]%s*%[.%]%s")
	if indent_str then
		return #indent_str
	end

	-- Check for ordered list tasks, e.g., "1. [ ] task" or "10) [ ] task"
	indent_str = line:match("^(%s*)%d+[.%)%)]%s*%[.%]%s")
	if indent_str then
		return #indent_str
	end

	return nil
end

---
-- If a line is a markdown list item, finds the column where the text content begins.
-- Handles ordered (e.g., "1. ", "10) ") and unordered (e.g., "* ", "- ") lists.
-- @param line (string): The line content to inspect.
-- @return (number|nil): The 1-based column number for insertion, or nil if not a list item.
local function get_list_marker_info(line)
	if not line then
		return nil
	end

	-- Regex for unordered lists: optional indent, then *, -, or +, then one or more spaces.
	local _, match_end = line:find("^%s*[%*%-+]%s+")
	if match_end then
		return match_end + 1 -- The text starts right after the marker.
	end

	-- Regex for ordered lists: optional indent, then digits, then . or ), then one or more spaces.
	_, match_end = line:find("^%s*%d+[.%)%)]%s+")
	if match_end then
		return match_end + 1 -- The text starts right after the marker.
	end

	return nil -- Not a recognized list format.
end

---
-- Checks if a task is marked as done.
-- @param line (string): The line content.
-- @return (boolean|nil): True if done, false if not, nil if indeterminate.
local function is_marked_done(line)
	-- Find the state ('x' or ' ') within the first checkbox on the line.
	local state = line:match("%[(.)%]")

	if state == "x" then
		return true
	elseif state == " " then
		return false
	else
		return nil
	end
end

---
-- Marks a task as done by replacing '[ ]' with '[x]'.
-- @param line_nr (number): The line number to modify.
local function mark_done(line_nr)
	local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1]
	if not line or get_bound(line) == nil then
		return
	end

	if not is_marked_done(line) then
		local new_line = line:gsub("%[ %]", "[x]")
		vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, { new_line })
	end
end

---
-- Marks a task as undone by replacing '[x]' with '[ ]'.
-- @param line_nr (number): The line number to modify.
local function mark_undone(line_nr)
	local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1]
	if not line or get_bound(line) == nil then
		return
	end

	if is_marked_done(line) then
		local new_line = line:gsub("%[x%]", "[ ]")
		vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, { new_line })
	end
end

---
-- Toggles the state of all descendant tasks.
-- @param line_number (number): The line number of the parent task.
-- @param bound (number): The indentation level of the parent task.
-- @param state (boolean): The new state to apply (true for done, false for undone).
local function toggle_children(line_number, bound, state)
	for ln = line_number + 1, line_count_cache do
		local line = vim.fn.getline(ln)
		local new_bound = get_bound(line)

		if new_bound then
			if new_bound > bound then
				if state then
					mark_done(ln)
				else
					mark_undone(ln)
				end
			else
				break
			end
		end
	end
end

---
-- Finds the line number of the parent task.
-- @param cursor (number): The line number of the child task.
-- @param bound (number): The indentation level of the child task.
-- @return (number|nil): The line number of the parent task or nil.
local function find_parent(cursor, bound)
	for ln = cursor - 1, 1, -1 do
		local line = vim.fn.getline(ln)
		local new_bound = get_bound(line)
		if new_bound and new_bound < bound then
			return ln
		end
	end
	return nil
end

---
-- Checks if all immediate children of a task are complete.
-- @param cursor (number): The line number of the parent task.
-- @param bound (number): The indentation level of the parent task.
-- @return (boolean): True if all children are complete, otherwise false.
local function is_children_complete(cursor, bound)
	local child_bound = nil
	local found_a_child = false
	local all_done = true

	for ln = cursor + 1, line_count_cache do
		local line = vim.fn.getline(ln)
		local new_bound = get_bound(line)

		if new_bound then
			if new_bound <= bound then
				break
			end

			if not child_bound then
				child_bound = new_bound
			end

			if new_bound == child_bound then
				found_a_child = true
				if not is_marked_done(line) then
					all_done = false
				end
			end
		end
	end
	return not found_a_child or all_done
end

---
-- Updates the status of all ancestor tasks based on their children.
-- @param cursor (number): The line number of the task that was changed.
-- @param bound (number): The indentation level of the task that was changed.
local function validate_parent_tasks(cursor, bound)
	local current_ln = cursor
	local current_bound = bound

	while true do
		local parent_ln = find_parent(current_ln, current_bound)
		if not parent_ln then
			break
		end

		local parent_line = vim.fn.getline(parent_ln)
		local parent_bound = get_bound(parent_line)

		if is_children_complete(parent_ln, parent_bound) then
			mark_done(parent_ln)
		else
			mark_undone(parent_ln)
		end

		current_ln = parent_ln
		current_bound = parent_bound
	end
end

---
-- Main function to toggle a task's state or create a new task from a list item.
todo.toggle = function()
	line_count_cache = vim.api.nvim_buf_line_count(0)
	local original_cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_ln = original_cursor[1]
	local line = vim.fn.getline(cursor_ln)
	local bound = get_bound(line)

	if bound == nil then
		-- NOT A TASK: Check if it's a list item we can convert.
		local text_start_col = get_list_marker_info(line)
		if text_start_col then
			-- It is a list item. Insert a checkbox to convert it.
			local prefix = line:sub(1, text_start_col - 1)
			local suffix = line:sub(text_start_col)
			local new_line = prefix .. "[ ] " .. suffix

			vim.api.nvim_buf_set_lines(0, cursor_ln - 1, cursor_ln, false, { new_line })

			-- Since we created a new (undone) task, validate parents.
			local new_bound = get_bound(new_line)
			if new_bound then
				validate_parent_tasks(cursor_ln, new_bound)
			end
			return
		end
		-- Not a task and not a convertible list item. Notify the user.
		vim.notify("Not a valid todo task or list item.", vim.log.levels.WARN)
		return
	end

	-- IS A TASK: Proceed with the toggle logic.
	local currently_done = is_marked_done(line)
	if currently_done == nil then
		vim.notify("Could not determine task state.", vim.log.levels.WARN)
		return
	end
	local new_state_is_done = not currently_done

	if new_state_is_done then
		mark_done(cursor_ln)
	else
		mark_undone(cursor_ln)
	end

	toggle_children(cursor_ln, bound, new_state_is_done)
	validate_parent_tasks(cursor_ln, bound)
	vim.api.nvim_win_set_cursor(0, original_cursor)
end

return todo
