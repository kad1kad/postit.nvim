-- Navigate to file under cursor-- postit.nvim - Simple post-it note plugin
-- File: lua/postit/init.lua

local M = {}

-- Plugin state
local state = {
	window = nil, -- Single window handle
	buffer = nil, -- Single buffer handle
	is_fullscreen = false,
	storage_dir = vim.fn.expand("~/.local/share/nvim/postit/"),
}

-- Default configuration
local config = {
	width = 60,
	height = 20,
	border = "rounded",
}

-- Ensure storage directory exists
local function ensure_storage_dir()
	if vim.fn.isdirectory(state.storage_dir) == 0 then
		vim.fn.mkdir(state.storage_dir, "p")
	end
end

-- Get file path for the note
local function get_note_path()
	return state.storage_dir .. "note.txt"
end

-- Get timestamp in DD/MM/YY HH:MM format
local function get_timestamp()
	return os.date("%d/%m/%y %H:%M")
end

-- Load note content from file
local function load_note_content()
	local file_path = get_note_path()
	local file = io.open(file_path, "r")
	if file then
		local content = file:read("*all")
		file:close()
		return vim.split(content, "\n")
	end
	return { "Post-it Note - " .. get_timestamp(), "" }
end

-- Save note content to file
local function save_note_content()
	local buf = state.buffer
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local content = table.concat(lines, "\n")

	ensure_storage_dir()
	local file_path = get_note_path()
	local file = io.open(file_path, "w")
	if file then
		file:write(content)
		file:close()
	end
end

-- Insert current file path into note
local function insert_current_file_path()
	-- Get current buffer file path before opening post-it
	local current_file = vim.fn.expand("%:.") -- Relative path from cwd

	if current_file == "" then
		print("No file in current buffer")
		return
	end

	-- If post-it is not open, open it first
	if not state.window or not vim.api.nvim_win_is_valid(state.window) then
		toggle_note()
	end

	-- Insert the file path at cursor position
	local buf = state.buffer
	local win = state.window

	if buf and vim.api.nvim_buf_is_valid(buf) and win and vim.api.nvim_win_is_valid(win) then
		local cursor = vim.api.nvim_win_get_cursor(win)
		local line_num = cursor[1] - 1
		local col_num = cursor[2]

		-- Get current line
		local line = vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1] or ""

		-- Insert file path at cursor position
		local new_line = line:sub(1, col_num) .. current_file .. line:sub(col_num + 1)
		vim.api.nvim_buf_set_lines(buf, line_num, line_num + 1, false, { new_line })

		-- Move cursor to end of inserted text
		vim.api.nvim_win_set_cursor(win, { line_num + 1, col_num + #current_file })

		print("Inserted: " .. current_file)
	end
end
local function navigate_to_file()
	local buf = state.buffer
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local win = state.window
	if not win or not vim.api.nvim_win_is_valid(win) then
		return
	end

	-- Get current line
	local cursor = vim.api.nvim_win_get_cursor(win)
	local line_num = cursor[1] - 1
	local line = vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1]

	if not line then
		return
	end

	-- Extract file path - look for common patterns
	local file_path = nil

	-- Pattern 1: ./path/to/file.ext or /absolute/path/file.ext
	file_path = line:match("[%.%/][%w%/%._%-]+%.[%w]+")

	-- Pattern 2: path/to/file.ext (relative without ./)
	if not file_path then
		file_path = line:match("[%w%/%._%-]+%.[%w]+")
	end

	-- Pattern 3: just filename.ext
	if not file_path then
		file_path = line:match("[%w%._%-]+%.[%w]+")
	end

	if file_path then
		-- Expand relative paths
		if file_path:sub(1, 1) ~= "/" then
			file_path = vim.fn.expand(file_path)
		end

		-- Check if file exists
		if vim.fn.filereadable(file_path) == 1 then
			-- Close post-it and open the file
			M.toggle_note()
			vim.cmd("edit " .. vim.fn.fnameescape(file_path))
			print("Opened: " .. file_path)
		else
			print("File not found: " .. file_path)
		end
	else
		print("No file path found on current line")
	end
end

-- Create or get buffer for note
local function get_or_create_buffer()
	if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
		return state.buffer
	end

	local buf = vim.api.nvim_create_buf(false, true)
	state.buffer = buf

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nowrite")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf, "modified", false)
	vim.api.nvim_buf_set_name(buf, "Post-it Note")

	-- Load content
	local content = load_note_content()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

	-- Set up auto-save
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = function()
			save_note_content()
			vim.api.nvim_buf_set_option(buf, "modified", false)
		end,
	})

	return buf
end

-- Get window dimensions
local function get_window_config(is_fullscreen)
	local ui = vim.api.nvim_list_uis()[1]

	if is_fullscreen then
		return {
			relative = "editor",
			width = ui.width - 2,
			height = ui.height - 4,
			row = 1,
			col = 1,
			style = "minimal",
			border = config.border,
			title = " Post-it Note (Fullscreen) ",
			title_pos = "center",
		}
	else
		return {
			relative = "editor",
			width = config.width,
			height = config.height,
			row = math.floor((ui.height - config.height) / 2),
			col = math.floor((ui.width - config.width) / 2),
			style = "minimal",
			border = config.border,
			title = " Post-it Note ",
			title_pos = "center",
		}
	end
end

-- Toggle note visibility
local function toggle_note()
	-- If window exists and is valid, close it
	if state.window and vim.api.nvim_win_is_valid(state.window) then
		vim.api.nvim_win_close(state.window, false)
		state.window = nil
		return
	end

	-- Create or get buffer
	local buf = get_or_create_buffer()

	-- Create window
	local win_config = get_window_config(state.is_fullscreen)
	local win = vim.api.nvim_open_win(buf, true, win_config)
	state.window = win

	-- Set window-local keymaps
	local opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "<leader>nf", function()
		M.toggle_fullscreen()
	end, opts)
	vim.keymap.set("n", "<leader>nd", function()
		M.clear_note()
	end, opts)
	vim.keymap.set("n", "gf", function()
		M.navigate_to_file()
	end, opts)
	vim.keymap.set("n", "<CR>", function()
		M.navigate_to_file()
	end, opts)
	vim.keymap.set("n", "<Esc>", function()
		M.toggle_note()
	end, opts)
end

-- Toggle fullscreen mode
local function toggle_fullscreen()
	if not state.window or not vim.api.nvim_win_is_valid(state.window) then
		return
	end

	state.is_fullscreen = not state.is_fullscreen
	local win_config = get_window_config(state.is_fullscreen)
	vim.api.nvim_win_set_config(state.window, win_config)
end

-- Clear note content
local function clear_note()
	local buf = state.buffer
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local new_content = { "Post-it Note - " .. get_timestamp(), "" }
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_content)
	save_note_content()

	-- Move cursor to line 2
	if state.window and vim.api.nvim_win_is_valid(state.window) then
		vim.api.nvim_win_set_cursor(state.window, { 2, 0 })
	end
end

-- Public API
M.toggle_note = toggle_note
M.toggle_fullscreen = toggle_fullscreen
M.clear_note = clear_note
M.navigate_to_file = navigate_to_file
M.insert_current_file_path = insert_current_file_path

-- Setup function
function M.setup(user_config)
	user_config = user_config or {}

	-- Only setup once
	if M._setup_done then
		-- If called again, just update config
		config = vim.tbl_deep_extend("force", config, user_config)
		return
	end

	config = vim.tbl_deep_extend("force", config, user_config)

	-- Create main keymap
	vim.keymap.set("n", "<leader>nt", function()
		toggle_note()
	end, { silent = true, desc = "Toggle post-it note" })

	-- Global keymap to insert current file path
	vim.keymap.set("n", "<leader>np", function()
		insert_current_file_path()
	end, { silent = true, desc = "Insert current file path into post-it note" })

	M._setup_done = true
end

return M
