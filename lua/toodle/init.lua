local M = {}

-- --------------------------------------------------------------
-- Reads a file in a given base folder and maps all occurrences
-- of "todo"s storing the filename together with line and column
-- --------------------------------------------------------------
local function map_todos_in_file(folder, file_name, entries)
	local full_path = folder .. "/" .. file_name
	local lines = vim.fn.readfile(full_path)
	for row, value in ipairs(lines) do
		local col = string.find(value, "TODO:", 1, true)
		if col ~= nil then
			table.insert(entries, {
				file_path = full_path,
				file_name = file_name,
				row = row,
				col = col,
			})
		end
	end
end

-- --------------------------------------------------------------
-- Reads recursively the given folder and for each file having a
-- "todo" string it adds its name, row and column to a table
-- which is then returned to the calling function
-- --------------------------------------------------------------
local function get_files(folder, entries)
	for _, file in ipairs(vim.fn.readdir(folder)) do
		-- Exclude hidden files/folders
		if not vim.startswith(file, ".") then
			local full_path = folder .. "/" .. file
			if vim.fn.isdirectory(full_path) == 0 then
				-- Here we found a file, so add the file and todo entries to the table
				table.insert(entries, file)
				map_todos_in_file(folder, file, entries)
			else
				-- Here we have a folder, so recursively add file entries with a todo
				get_files(full_path, entries)
			end
		end
	end
end

function M.setup()
	-- Create a ToodleDebug command that opens a new window and writes the files list into it
	vim.api.nvim_create_user_command("ToodleDebug", function()
		-- local files = {}
		-- get_files(vim.fn.getcwd(), files)
		local folder = vim.fn.join({ vim.fn.getcwd(), "lua", "toodle" }, "/")
		local entries = {}
		map_todos_in_file(folder, "init.lua", entries)

		-- Create a temporary buffer that cannot be saved (false)
		local buf = vim.api.nvim_create_buf(false, true)

		-- Fill the buffer with debug info
		local lines = {}
		for _, entry in pairs(entries) do
			local entry_line = string.format("%s (%s:%s)", entry.file_name, entry.row, entry.col)
			table.insert(lines, entry_line)
		end
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
		local files = {}
		get_files(vim.fn.getcwd(), files)

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
