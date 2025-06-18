local M = {}

local function expand_path(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	return path
end

local function center_win(outer, inner)
	return (outer - inner) / 2
end

local function win_config()
	local width = math.min(math.floor(vim.o.columns * 0.8), 64)
	local height = math.floor(vim.o.lines * 0.8)
	return {
		relative = "editor",
		width = width,
		height = height,
		col = center_win(vim.o.columns, width),
		row = center_win(vim.o.lines, height),
		border = "single",
	}
end

-- Get the project name from the current working directory
local function get_project_name()
	local cwd = vim.fn.getcwd()
	return cwd:match("([^/]+)$")
end

-- Ensure the file exists, creating it if necessary
local function ensure_file_exists(path)
	local expanded = expand_path(path)
	local dir = expanded:match("(.*/)")

	-- Tạo thư mục nếu chưa có
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end

	-- Tạo file rỗng nếu chưa có
	if vim.fn.filereadable(expanded) == 0 then
		local f = io.open(expanded, "w")
		if f then
			f:write("# Notes for " .. get_project_name() .. "\n\n")
			f:close()
		end
	end
end

-- Open project note in a floating window
local function open_project_note()
	local project = get_project_name()
	local note_path = "~/notes/note_" .. project .. ".md"

	ensure_file_exists(note_path)

	local expanded_path = expand_path(note_path)
	local buf = vim.fn.bufnr(expanded_path, true)

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, expanded_path)
	end

	-- Load the file into the buffer
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("edit " .. vim.fn.fnameescape(expanded_path))
	end)

	vim.bo[buf].swapfile = false
	local window = vim.api.nvim_open_win(buf, true, win_config())

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = buf }) then
				vim.notify("Buffer has unsaved changes. Please save before closing.", vim.log.levels.WARN)
			else
				-- Close the window if it is valid
				if vim.api.nvim_win_is_valid(window) then
					vim.api.nvim_win_close(window, true)
				end
				-- Quickly delete the buffer
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = false })
				end
			end
		end,
	})

	vim.notify("Opened note for project: " .. project, vim.log.levels.INFO)
end

local function open_floating_file(target_file)
	local expanded_path = expand_path(target_file)
	if vim.fn.filereadable(expanded_path) == 0 then
		vim.notify("Todo file does not exist at directory: " .. expanded_path, vim.log.levels.ERROR)
		return
	end

	local buf = vim.fn.bufnr(expanded_path, true)

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, expanded_path)
	end

	vim.bo[buf].swapfile = false

	local window = vim.api.nvim_open_win(buf, true, win_config())

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = buf }) then
				vim.notify("Buffer has unsaved changes. Please save before closing.", vim.log.levels.WARN)
			else
				-- Close the window if it is valid
				if vim.api.nvim_win_is_valid(window) then
					vim.api.nvim_win_close(window, true)
				end
				-- Quickly delete the buffer
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = false })
				end
			end
		end,
	})
end

local function setup_user_commands(opts)
	local target_file = opts.target_file or "todo.md"
	vim.api.nvim_create_user_command("Td", function()
		open_floating_file(target_file)
	end, {})
	vim.api.nvim_create_user_command("Pn", open_project_note, {
		desc = "Open project note (short alias)",
	})
end

M.setup = function(opts)
	setup_user_commands(opts)
end

return M
