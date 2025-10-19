local M = {}

-- --------------------------------------------------------------
-- Reads a file in a given base folder and maps all occurrences
-- of "todo"s storing the filename together with line and column
-- --------------------------------------------------------------
local function map_todos_in_file(folder, filename, list)
	local full_path = folder .. "/" .. filename
	local lines = vim.fn.readfile(full_path)
	for row, value in ipairs(lines) do
		local col = string.find(string.lower(value), "todo")
		if col then
			table.insert(list, {
				file_path = full_path,
				file_name = filename,
				col = col,
				row = row,
			})
		end
	end
end

-- --------------------------------------------------------------
-- Reads recursively the given folder and for each file having a
-- "todo" string it adds its name, row and column to a table
-- which is then returned to the calling function
-- --------------------------------------------------------------
local function get_files(folder)
	local return_files = {}
	for _, file in ipairs(vim.fn.readdir(folder)) do
		if vim.startswith(file, ".") then
			goto continue
		end
		local full_path = folder .. "/" .. file
		if vim.fn.isdirectory(full_path) == 0 then
			-- table.insert(return_files, file)
			map_todos_in_file(folder, file, return_files)
		else
			for _, f in ipairs(get_files(full_path)) do
				table.insert(return_files, f)
			end
		end
		::continue::
	end
	return return_files
end

function M.setup()
	-- Create a Toodle command that opens a new window and writes the files list into it
	vim.api.nvim_create_user_command("Toodle", function()
		local files = get_files(vim.fn.getcwd())

		-- Create a temporary buffer that cannot be saved (false)
		local current_buf = vim.api.nvim_get_current_buf()
		local buf = vim.api.nvim_create_buf(false, true)
		-- TODO

		local lines = {}
		for _, value in ipairs(files) do
			table.insert(lines, value.file_name .. " " .. value.col_idx .. " " .. value.row)
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
		local win = vim.api.nvim_open_win(buf, true, {
			split = "right",
		})

		-- Add bindings so that 'gg' opens the file at the TODO location
		vim.keymap.set("n", "gg", function()
			local pos = vim.api.nvim_win_get_cursor(0)
			local selected = files[pos[1]]
			vim.api.nvim_win_close(win, false)
			vim.api.nvim.nvim_get_current_buf(current_buf)
			vim.api.nvim_command("edit " .. selected.path)
			vim.api.nvim_win_set_cursor(0, { selected.row, selected.col_idx })
		end, { buffer = buf })

		-- Add bindings so that 'q' closes the toodle window
		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, false)
		end)
	end, {})
end

return M
