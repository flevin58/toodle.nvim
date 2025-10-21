local M = {}

-- --------------------------------------------------------------
-- Reads a file in a given base folder and maps all occurrences
-- of "todo"s storing the filename together with line and column
-- --------------------------------------------------------------
local function map_todos_in_file(folder, filename, entries)
	local full_path = folder .. "/" .. filename
	local lines = vim.fn.readfile(full_path)
	for row, value in ipairs(lines) do
		local pos = string.find(string.lower(value), "todo")
		if pos ~= nil then
			table.insert(entries, {
				file_path = full_path,
				file_name = filename,
				col = pos[0],
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
		-- Exclude hidden files/folders
		if vim.startswith(file, ".") then
			goto continue
		end
		local full_path = folder .. "/" .. file
		if vim.fn.isdirectory(full_path) == 0 then
			-- Here we found a file, so add the file and todo entries to the table
			table.insert(return_files, file)
			map_todos_in_file(folder, file, return_files)
		else
			-- Here we have a folder, so recursively add file entries with a todo
			for _, f in ipairs(get_files(full_path)) do
				table.insert(return_files, f)
			end
		end
		::continue::
	end
	return return_files
end

function M.setup()
	-- Create a ToodleDebug command that opens a new window and writes the files list into it
	vim.api.nvim_create_user_command("ToodleDebug", function()
		local folder = vim.fn.getcwd() .. "/lua/toodle"
		-- local entries = map_todos_in_file(folder, filename, entries)

		-- Create a temporary buffer that cannot be saved (false)
		local buf = vim.api.nvim_create_buf(false, true)

		-- Fill the buffer with debug info
		local lines = {}
		table.insert(lines, folder)
		vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

		-- Show the buffer in a split window at the right
		local win = vim.api.nvim_open_win(buf, true, {
			split = "right",
		})

		-- Add bindings so that 'q' closes the toodle window
		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, false)
		end)
	end, {})

	-- Create a Toodle command that opens a new window and writes the files list into it
	vim.api.nvim_create_user_command("Toodle", function()
		local files = get_files(vim.fn.getcwd())
		-- fix first entry is null. TODO: Find out why and fix it!
		table.remove(files, 1)

		-- Create a temporary buffer that cannot be saved (false)
		local current_buf = vim.api.nvim_get_current_buf()
		local buf = vim.api.nvim_create_buf(false, true)

		-- Insert the formatted line entries into the buffer
		local lines = {}
		for _, entry in ipairs(files) do
			local entry_line = string.format("%s (%s:%s)", entry.file_name, entry.row, entry.col)
			table.insert(lines, entry_line)
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
		-- Show the buffer in a split window at the right
		local win = vim.api.nvim_open_win(buf, true, {
			split = "right",
		})

		-- Add bindings so that 'gg' opens the file at the TODO location
		vim.keymap.set("n", "gg", function()
			local row, _ = vim.api.nvim_win_get_cursor(0)
			local selected = files[row]
			vim.api.nvim_win_close(win, false)
			vim.api.nvim.nvim_get_current_buf(current_buf)
			vim.api.nvim_command("edit " .. selected.file_path)
			vim.api.nvim_win_set_cursor(0, { selected.row, selected.col })
		end, { buffer = buf })

		-- Add bindings so that 'q' closes the toodle window
		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, false)
		end)
	end, {})
end

return M
