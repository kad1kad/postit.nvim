local M = {}

local state = {
	windows = {},
	buffers = {},
	current_note = 1,
	is_fullscreen = {},
	storage_dir = vim.fn.expand("~/.local/share/nvim/postit/"),
}

local config = {
	width = 60,
	height = 20,
	border = "rounded",
}

local function ensure_storage_dir()
	if vim.fn.isdirectory(state.storage_dir) == 0 then
		vim.fn.mkdir(state.storage_dir, "p")
	end
end

local function get_note_path(note_num)
	return state.storage_dir .. "note_" .. note_num .. ".txt"
end

local function get_timestamp()
	return os.date("%d/%m/%y %H:%M")
end

local function load_note_content(note_num)
	local file_path = get_note_path(note_num)
	local file = io.open(file_path, "r")
	if file then
		local content = file:read("*all")
		file:close()
		return vim.split(content, "\n")
	end
	return { "Post-it Note #" .. note_num .. " - " .. get_timestamp(), "" }
end

local function save_note_content(note_num)
	local buf = state.buffers[note_num]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local content = table.concat(lines, "\n")

	ensure_storage_dir()
	local file_path = get_note_path(note_num)
	local file = io.open(file_path, "w")
	if file then
		file:write(content)
		file:close()
	end
end

local function get_or_create_buffer(note_num)
	if state.buffers[note_num] and vim.api.nvim_buf_is_valid(state.buffers[note_num]) then
		return state.buffers[note_num]
	end

	local buf = vim.api.nvim_create_buf(false, true)
	state.buffers[note_num] = buf

	vim.api.nvim_buf_set_option(buf, "buftype", "nowrite")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf, "modified", false)
	vim.api.nvim_buf_set_name(buf, "Post-it #" .. note_num)

	local content = load_note_content(note_num)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = function()
			save_note_content(note_num)
			vim.api.nvim_buf_set_option(buf, "modified", false)
		end,
	})

	return buf
end

local function get_window_config(note_num, is_fullscreen)
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
			title = " Post-it #" .. note_num .. " (Fullscreen) ",
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
			title = " Post-it #" .. note_num .. " ",
			title_pos = "center",
		}
	end
end

local function toggle_note(note_num)
	if state.windows[note_num] and vim.api.nvim_win_is_valid(state.windows[note_num]) then
		vim.api.nvim_win_close(state.windows[note_num], false)
		state.windows[note_num] = nil
		return
	end

	local buf = get_or_create_buffer(note_num)
	local win_config = get_window_config(note_num, state.is_fullscreen[note_num])
	local win = vim.api.nvim_open_win(buf, true, win_config)

	state.windows[note_num] = win
	state.current_note = note_num

	local opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "<leader>nf", function()
		M.toggle_fullscreen(note_num)
	end, opts)
	vim.keymap.set("n", "<leader>nd", function()
		M.clear_note(note_num)
	end, opts)
	vim.keymap.set("n", "nx", function()
		M.toggle_checkbox(note_num)
	end, opts)
	vim.keymap.set("n", "<Esc>", function()
		M.toggle_note(note_num)
	end, opts)
end

local function toggle_fullscreen(note_num)
	if not state.windows[note_num] or not vim.api.nvim_win_is_valid(state.windows[note_num]) then
		return
	end

	state.is_fullscreen[note_num] = not state.is_fullscreen[note_num]
	local win_config = get_window_config(note_num, state.is_fullscreen[note_num])
	vim.api.nvim_win_set_config(state.windows[note_num], win_config)
end

local function toggle_checkbox(note_num)
	local buf = state.buffers[note_num]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local win = state.windows[note_num]
	if not win or not vim.api.nvim_win_is_valid(win) then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(win)
	local line_num = cursor[1] - 1
	local line = vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1]
	if not line then
		return
	end

	local new_line
	if line:match("^%s*◻") then
		new_line = line:gsub("^(%s*)◻", "%1✔")
	elseif line:match("^%s*✔") then
		new_line = line:gsub("^(%s*)✔", "%1◻")
	else
		return -- do not add checkboxes
	end

	vim.api.nvim_buf_set_lines(buf, line_num, line_num + 1, false, { new_line })
	save_note_content(note_num)
end

local function clear_note(note_num)
	local buf = state.buffers[note_num]
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local new_content = { "Post-it Note #" .. note_num .. " - " .. get_timestamp(), "" }
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_content)
	save_note_content(note_num)

	if state.windows[note_num] and vim.api.nvim_win_is_valid(state.windows[note_num]) then
		vim.api.nvim_win_set_cursor(state.windows[note_num], { 2, 0 })
	end
end

-- Public API
M.toggle_note = toggle_note
M.toggle_fullscreen = toggle_fullscreen
M.clear_note = clear_note
M.toggle_checkbox = toggle_checkbox

function M.setup(user_config)
	user_config = user_config or {}

	if M._setup_done then
		config = vim.tbl_deep_extend("force", config, user_config)
		return
	end

	config = vim.tbl_deep_extend("force", config, user_config)

	for i = 1, 9 do
		vim.keymap.set("n", "<leader>nt" .. tostring(i), function()
			toggle_note(i)
		end, { silent = true, desc = "Toggle post-it note " .. tostring(i) })
	end

	vim.keymap.set("n", "<leader>nt", function()
		toggle_note(1)
	end, { silent = true, desc = "Toggle post-it note 1" })

	M._setup_done = true
end

return M
