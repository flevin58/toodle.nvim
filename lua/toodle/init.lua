local M = {}

local function get_files(dir)
	local return_files = {}
	for _, file in ipairs(vim.fn.readdir(dir)) do
		if vim.startswith(file, ".") then
			goto continue
		end
		local full_path = dir .. "/" .. file
		if vim.fn.isdirectory(full_path) == 0 then
			table.insert(return_files, file)
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
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, true, files)
		local win = vim.api.nvim_open_win(buf, true, {
			split = "right",
		})
		-- Add bindings so that 'q' closes the toodle window
		vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(win, false)
		end)
	end, {})
end

return M
