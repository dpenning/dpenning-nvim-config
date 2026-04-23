local M = {}

local uv = vim.uv or vim.loop
local log = vim.log
local fn = vim.fn
local trim = vim.trim or function(text)
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local home = uv.os_homedir()
local base_dir = home .. "/.vimgolf"
local put_dir = base_dir .. "/put"
local scripts_dir = base_dir .. "/scripts"
local work_dir = base_dir .. "/work"

local sessions_by_id = {}
local diff_ns = vim.api.nvim_create_namespace("vimgolf_diff")
local cursor_ns = vim.api.nvim_create_namespace("vimgolf_cursor")

pcall(vim.api.nvim_set_hl, 0, "VimgolfCursor", { link = "Cursor", default = true })

local function write_file(path, data)
	local file, err = io.open(path, "wb")
	if not file then
		return nil, err
	end
	file:write(data)
	file:close()
	return true
end

local function read_file(path)
	local file, err = io.open(path, "rb")
	if not file then
		return nil, err
	end
	local content = file:read("*a")
	file:close()
	return content
end

local json_decode = (vim.json and vim.json.decode) or vim.fn.json_decode
local json_encode = (vim.json and vim.json.encode) or vim.fn.json_encode

local function challenge_meta_path(id)
	return string.format("%s/%s.meta.json", put_dir, id)
end

local function html_entity_decode(text)
	local entities = {
		amp = "&",
		lt = "<",
		gt = ">",
		quot = '"',
		apos = "'",
		nbsp = " ",
		rsquo = "'",
		lsquo = "'",
		rdquo = '"',
		ldquo = '"',
		mdash = "-",
		ndash = "-",
		hellip = "...",
	}
	local function numeric_decode(entity)
		local base = 10
		local value = entity
		if entity:sub(1, 1) == "x" or entity:sub(1, 1) == "X" then
			base = 16
			value = entity:sub(2)
		end
		local ok, decoded = pcall(tonumber, value, base)
		if not ok or not decoded then
			return nil
		end
		if decoded < 0 or decoded > 255 then
			return nil
		end
		return string.char(decoded)
	end
	return (text:gsub("&(#?)(.-);", function(prefix, body)
		if prefix == "#" then
			return numeric_decode(body) or ""
		end
		return entities[body:lower()] or ""
	end))
end

local function sanitize_html_text(text)
	if type(text) ~= "string" then
		return ""
	end
	text = text:gsub("<br%s*/?>", "\n")
	text = text:gsub("<.->", "")
	text = html_entity_decode(text)
	text = text:gsub("%s+", " ")
	return trim(text)
end

local function fetch_challenge_metadata(id)
	local url = string.format("https://www.vimgolf.com/challenges/%s", id)
	local body = fn.system({ "curl", "-fsSL", "-H", "Accept: text/html", url })
	if vim.v.shell_error ~= 0 or type(body) ~= "string" then
		return nil, string.format("failed to download challenge metadata (%s)", url)
	end
	local normalized = body:gsub("\r", " ")
	normalized = normalized:gsub("\n", " ")
	local title, summary = normalized:match("<h3[^>]*>%s*<b>(.-)</b>.-<p>(.-)</p>")
	if not title and not summary then
		return nil, "challenge metadata unavailable"
	end
	return {
		title = sanitize_html_text(title),
		summary = sanitize_html_text(summary),
	}
end

local function save_challenge_metadata(id, metadata)
	if not metadata then
		return
	end
	local ok, encoded = pcall(json_encode, metadata)
	if not ok then
		return
	end
	write_file(challenge_meta_path(id), encoded)
end

local function load_challenge_metadata(id)
	local content = read_file(challenge_meta_path(id))
	if not content then
		return nil
	end
	local ok, metadata = pcall(json_decode, content)
	if not ok or type(metadata) ~= "table" then
		return nil
	end
	return metadata
end

local function ensure_dirs()
	fn.mkdir(put_dir, "p")
	fn.mkdir(scripts_dir, "p")
	fn.mkdir(work_dir, "p")
end

ensure_dirs()

local function sanitize_type(value)
	if type(value) ~= "string" or value == "" then
		return "txt"
	end
	local sanitized = value:gsub("[^%w-]", ".")
	if sanitized == "" then
		sanitized = "txt"
	end
	return sanitized
end

local function normalize_content(text)
	if type(text) ~= "string" then
		text = ""
	end
	text = text:gsub("\r\n", "\n")
	text = text:gsub("\r", "\n")
	if text == "" or not text:match("\n$") then
		text = text .. "\n"
	end
	return text
end

local function copy_file(src, dest)
	local data, read_err = read_file(src)
	if not data then
		return nil, read_err
	end
	return write_file(dest, data)
end

local function files_match(a, b)
	local left, left_err = read_file(a)
	if not left then
		return nil, left_err
	end
	local right, right_err = read_file(b)
	if not right then
		return nil, right_err
	end
	return left == right
end

local function split_lines(text)
	text = text:gsub("\r\n?", "\n")
	local lines = vim.split(text, "\n", { plain = true, trimempty = false })
	if #lines > 0 and lines[#lines] == "" then
		table.remove(lines, #lines)
	end
	return lines
end

local function is_stop_value(text)
	if type(text) ~= "string" then
		return false
	end
	local cleaned = trim(text)
	if cleaned == "" then
		return false
	end
	local lower = cleaned:lower()
	if lower == "stop" then
		return true
	end
	return lower:match("^stop%s+") ~= nil
end

local function is_stop_directive(text)
	if type(text) ~= "string" then
		return false
	end
	local trimmed = trim(text)
	if trimmed == "" or trimmed:sub(1, 1) ~= ":" then
		return false
	end
	return is_stop_value(trim(trimmed:sub(2)))
end

local function update_cursor_highlight(session)
	if not session or not session.result_buf or not vim.api.nvim_buf_is_valid(session.result_buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(session.result_buf, cursor_ns, 0, -1)
	if not session.cursor_pos then
		return
	end
	local row = math.max(0, (session.cursor_pos[1] or 1) - 1)
	local col = math.max(0, session.cursor_pos[2] or 0)
	local line = vim.api.nvim_buf_get_lines(session.result_buf, row, row + 1, false)[1]
	if not line then
		return
	end
	local byte_len = #line
	local start_col = math.min(col, byte_len)
	local opts = {
		hl_group = "VimgolfCursor",
		hl_mode = "combine",
	}
	if start_col < byte_len then
		opts.end_row = row
		opts.end_col = start_col + 1
	else
		opts.end_row = row
		opts.end_col = start_col
		opts.virt_text = { { " ", "VimgolfCursor" } }
		opts.virt_text_pos = "overlay"
	end
	vim.api.nvim_buf_set_extmark(session.result_buf, cursor_ns, row, start_col, opts)
end

local function set_session_cursor(session, pos)
	if not session then
		return
	end
	if type(pos) == "table" and type(pos[1]) == "number" and type(pos[2]) == "number" then
		session.cursor_pos = { pos[1], pos[2] }
	else
		session.cursor_pos = nil
	end
	update_cursor_highlight(session)
end

local function highlight_differences(session)
	if not session.result_buf or not vim.api.nvim_buf_is_valid(session.result_buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(session.result_buf, diff_ns, 0, -1)
	local actual, actual_err = read_file(session.work_path)
	if not actual then
		return
	end
	local expected, expected_err = read_file(session.output_path)
	if not expected then
		return
	end
	local actual_lines = split_lines(actual)
	local expected_lines = split_lines(expected)
	local max_lines = math.max(#actual_lines, #expected_lines)
	for i = 1, max_lines do
		local a = actual_lines[i]
		local e = expected_lines[i]
		local row = i - 1
		if a and e then
			if a ~= e then
				vim.api.nvim_buf_add_highlight(session.result_buf, diff_ns, "DiffText", row, 0, -1)
			end
		elseif a and not e then
			vim.api.nvim_buf_add_highlight(session.result_buf, diff_ns, "DiffAdd", row, 0, -1)
		end
	end
end

local function download_challenge(id)
	local url = string.format("https://www.vimgolf.com/challenges/%s.json", id)
	local body = fn.system({ "curl", "-fsSL", url })
	if vim.v.shell_error ~= 0 then
		return nil, string.format("failed to download challenge data (%s)", url)
	end
	local ok, payload = pcall(json_decode, body)
	if not ok or type(payload) ~= "table" then
		return nil, "invalid challenge payload"
	end
	if type(payload["in"]) ~= "table" or type(payload["out"]) ~= "table" then
		return nil, "challenge payload missing input/output data"
	end
	local in_type = sanitize_type(payload["in"].type or "txt")
	local out_type = sanitize_type(payload["out"].type or "txt")
	local base_path = string.format("%s/%s", put_dir, id)
	local input_path = string.format("%s.input.%s", base_path, in_type)
	local output_path = string.format("%s.output.%s", base_path, out_type)
	local in_data = normalize_content(payload["in"].data or "")
	local out_data = normalize_content(payload["out"].data or "")
	local ok_in, err_in = write_file(input_path, in_data)
	if not ok_in then
		return nil, err_in
	end
	local ok_out, err_out = write_file(output_path, out_data)
	if not ok_out then
		return nil, err_out
	end
	local metadata = fetch_challenge_metadata(id)
	if metadata then
		save_challenge_metadata(id, metadata)
	end
	return {
		id = id,
		input_path = input_path,
		output_path = output_path,
		type = in_type,
		otype = out_type,
		title = metadata and metadata.title or nil,
		summary = metadata and metadata.summary or nil,
	}
end

local function find_existing_challenge(id)
	local input_matches = fn.glob(put_dir .. "/" .. id .. ".input.*", 0, 1)
	local output_matches = fn.glob(put_dir .. "/" .. id .. ".output.*", 0, 1)
	if type(input_matches) == "table" and type(output_matches) == "table" then
		if #input_matches > 0 and #output_matches > 0 then
			local input_path = input_matches[1]
			local output_path = output_matches[1]
			local in_type = input_path:match("%.input%.(.+)$") or "txt"
			local out_type = output_path:match("%.output%.(.+)$") or "txt"
			local metadata = load_challenge_metadata(id)
			return {
				id = id,
				input_path = input_path,
				output_path = output_path,
				type = in_type,
				otype = out_type,
				title = metadata and metadata.title or nil,
				summary = metadata and metadata.summary or nil,
			}
		end
	end
	return nil
end

local function ensure_challenge(id)
	local cached = find_existing_challenge(id)
	if cached then
		if not cached.title or cached.title == "" then
			local metadata = fetch_challenge_metadata(id)
			if metadata then
				save_challenge_metadata(id, metadata)
				cached.title = metadata.title
				cached.summary = metadata.summary
			end
		end
		return cached
	end
	return download_challenge(id)
end

local function wrap_text(text, width)
	if type(text) ~= "string" then
		return {}
	end
	width = width or 78
	local lines = {}
	local current = ""
	for word in text:gmatch("%S+") do
		if current == "" then
			current = word
		elseif #current + 1 + #word <= width then
			current = current .. " " .. word
		else
			table.insert(lines, current)
			current = word
		end
	end
	if current ~= "" then
		table.insert(lines, current)
	end
	return lines
end

local function build_script_header(session)
	local lines = {}
	local title
	if session.title and session.title ~= "" then
		title = string.format("VimGolf %s - %s", session.id, session.title)
	else
		title = string.format("VimGolf %s", session.id)
	end
	lines[#lines + 1] = string.format('" %s', title)
	if session.summary and session.summary ~= "" then
		for _, summary_line in ipairs(wrap_text(session.summary, 74)) do
			lines[#lines + 1] = string.format('" %s', summary_line)
		end
	end
	lines[#lines + 1] = string.format('" Working copy: %s', session.work_path)
	lines[#lines + 1] = '" Save this buffer to replay it against the working copy on the right.'
	lines[#lines + 1] = '" Avoid :q in here; stick to editing commands you want to replay.'
	lines[#lines + 1] = '" Non-comment lines run in order: prefix with : for Ex commands, otherwise they are treated as raw keys.'
	lines[#lines + 1] = '" Comments (starting with ") and lines beginning with comment: are ignored. Use <Esc>/<CR>/<Space> notation for special keys.'
	lines[#lines + 1] = '" Add :stop on its own line (or segment) to ignore the rest of the script.'
	lines[#lines + 1] = ""
	lines[#lines + 1] = ""
	return table.concat(lines, "\n")
end

local function ensure_script_file(session)
	local header = build_script_header(session)
	local stat = uv.fs_stat(session.script_path)
	if not stat then
		write_file(session.script_path, header)
		return
	end
	local content = read_file(session.script_path)
	if not content then
		write_file(session.script_path, header)
		return
	end
	if content:sub(1, #header) == header then
		return
	end
	local body = content
	if content:match('^" VimGolf') then
		local header_end = content:find("\n\n", 1, true)
		if header_end then
			body = content:sub(header_end + 2)
		end
	end
	write_file(session.script_path, header .. body)
end

local function parse_script_commands(path)
	local data, err = read_file(path)
	if not data then
		return nil, err
	end
	local commands = {}
	local lines = vim.split(data, "\n", { plain = true, trimempty = false })
	local stop_seen = false
	for _, raw in ipairs(lines) do
		if stop_seen then
			break
		end
		if raw ~= nil then
			local line = raw:gsub("\r$", "")
			if line ~= nil then
				if line ~= "" and not line:match("^%s*$") then
					local trimmed = line:match("^%s*(.-)%s*$") or line
					local lower = trimmed:lower()
					if trimmed:sub(1, 1) ~= '"' and not lower:match("^comment:%s*") then
						if line:match("^%s*:") then
							local command_line = line:gsub("^%s*:", "", 1)
							local segments = vim.split(command_line, "<CR>", { plain = true })
							local first = true
							for _, segment in ipairs(segments) do
								if stop_seen then
									break
								end
								local seg_trim = trim(segment or "")
								if seg_trim ~= "" then
									if first then
										if is_stop_value(seg_trim) then
											stop_seen = true
											break
										end
										table.insert(commands, { type = "ex", value = seg_trim })
									else
										if seg_trim:sub(1, 1) == ":" then
											if is_stop_directive(seg_trim) then
												stop_seen = true
												break
											end
											local rest = trim(seg_trim:sub(2))
											if rest ~= "" then
												table.insert(commands, { type = "ex", value = rest })
											end
										else
											if is_stop_value(seg_trim) then
												stop_seen = true
												break
											end
											table.insert(commands, { type = "normal", value = seg_trim })
										end
									end
								end
								first = false
							end
						else
							table.insert(commands, { type = "normal", value = line })
						end
					end
				end
			end
		end
	end
	return commands
end

local function ensure_indent_provider(buf)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local ft = vim.bo[buf].filetype
	if not ft or ft == "" then
		return
	end
	local indentexpr = vim.bo[buf].indentexpr or ""
	if not indentexpr:find("nvim%-treesitter") then
		return
	end
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("setlocal indentexpr=")
		vim.cmd("setlocal indentkeys=")
		vim.b.did_indent = nil
		local ok = pcall(vim.cmd, "runtime! indent/" .. ft .. ".vim")
		if not ok then
			vim.bo.indentexpr = ""
		end
	end)
end

local function ensure_script_saved(session)
	if not session.script_buf or not vim.api.nvim_buf_is_valid(session.script_buf) then
		return
	end
	if vim.bo[session.script_buf].modified then
		vim.api.nvim_buf_call(session.script_buf, function()
			vim.cmd("silent write")
		end)
	end
end

local function load_api_key()
	local config_path = base_dir .. "/config.yaml"
	local content = read_file(config_path)
	if not content then
		return nil, string.format(
			"VimGolf: missing API key. Run `vimgolf setup` to create %s",
			config_path
		)
	end
	local key = content:match("key:%s*([%w%d]+)") or content:match(":key:%s*([%w%d]+)")
	if not key or key == "" then
		return nil, "VimGolf: API key not found in config"
	end
	return trim(key)
end

local function post_submission(session, log_data)
	local api_key, key_err = load_api_key()
	if not api_key then
		return nil, key_err
	end
	local tmp_path = fn.tempname()
	local ok, err = write_file(tmp_path, log_data)
	if not ok then
		return nil, err
	end
	local url = "https://www.vimgolf.com/entry.json"
	local response = fn.system({
		"curl",
		"-fsSL",
		"-X",
		"POST",
		url,
		"--data-urlencode",
		"challenge_id=" .. session.id,
		"--data-urlencode",
		"apikey=" .. api_key,
		"--data-urlencode",
		"entry@" .. tmp_path,
	})
	pcall(uv.fs_unlink, tmp_path)
	if vim.v.shell_error ~= 0 then
		return nil, string.format("curl error: %s", response)
	end
	local ok_decode, payload = pcall(json_decode, response)
	if not ok_decode or type(payload) ~= "table" then
		return nil, "invalid submission response"
	end
	if payload.status and payload.status ~= "ok" then
		return nil, payload.message or payload.status
	end
	return payload
end

local function build_submission_log(session)
	ensure_script_saved(session)
	local commands, err = parse_script_commands(session.script_path)
	if not commands then
		return nil, err
	end
	if #commands == 0 then
		return nil, "script is empty"
	end
	local chunks = {}
	local function add_keys(keys)
		if not keys or keys == "" then
			return
		end
		local transformed = vim.api.nvim_replace_termcodes(keys, true, true, true)
		if transformed ~= "" then
			table.insert(chunks, transformed)
		end
	end
	for _, command in ipairs(commands) do
		if command.type == "ex" then
			add_keys(":" .. command.value .. "<CR>")
		else
			add_keys(command.value)
		end
	end
	add_keys("ZZ")
	return table.concat(chunks)
end

local function cleanup_session(session)
	if session.run_autocmd then
		pcall(vim.api.nvim_del_autocmd, session.run_autocmd)
		session.run_autocmd = nil
	end
	if session.cleanup_autocmd then
		pcall(vim.api.nvim_del_autocmd, session.cleanup_autocmd)
		session.cleanup_autocmd = nil
	end
	if session.cursor_autocmd then
		pcall(vim.api.nvim_del_autocmd, session.cursor_autocmd)
		session.cursor_autocmd = nil
	end
	if session.result_buf and vim.api.nvim_buf_is_valid(session.result_buf) then
		vim.api.nvim_buf_clear_namespace(session.result_buf, cursor_ns, 0, -1)
	end
	session.cursor_pos = nil
	sessions_by_id[session.id] = nil
end

local function active_ids()
	local ids = {}
	for id, _ in pairs(sessions_by_id) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

local function find_session_for_buffer(buf)
	for _, session in pairs(sessions_by_id) do
		if session.script_buf == buf or session.result_buf == buf then
			return session
		end
	end
	return nil
end

local function prompt_submit_anyway(session)
	local confirm_msg = string.format(
		"VimGolf %s: current working copy differs from the desired output. Submit anyway?",
		session.id
	)
	local choice = fn.confirm(confirm_msg, "&Yes\n&No", 2)
	return choice == 1
end

local function focus_session(session)
	if not session.script_buf or not vim.api.nvim_buf_is_valid(session.script_buf) then
		return false
	end
	local win = fn.bufwinid(session.script_buf)
	if win and win ~= -1 and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return true
	end
	return false
end

local ensure_result_window
local run_session

local function open_layout(session)
	vim.cmd("tabnew")
	vim.cmd("edit " .. fn.fnameescape(session.script_path))
	session.script_buf = vim.api.nvim_get_current_buf()
	session.script_win = vim.api.nvim_get_current_win()
	vim.bo[session.script_buf].filetype = "vim"

	vim.cmd("vsplit " .. fn.fnameescape(session.work_path))
	session.result_win = vim.api.nvim_get_current_win()
	session.result_buf = vim.api.nvim_get_current_buf()
	vim.bo[session.result_buf].bufhidden = "hide"
	vim.bo[session.result_buf].swapfile = false
	ensure_indent_provider(session.result_buf)
	session.cursor_autocmd = vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = session.result_buf,
		callback = function()
			if not session or not session.result_buf or vim.api.nvim_get_current_buf() ~= session.result_buf then
				return
			end
			set_session_cursor(session, vim.api.nvim_win_get_cursor(0))
		end,
	})

	session.run_autocmd = vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = session.script_buf,
		callback = function()
			run_session(session)
		end,
	})
	session.cleanup_autocmd = vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = session.script_buf,
		callback = function()
			cleanup_session(session)
		end,
	})
end

ensure_result_window = function(session)
	if session.result_win and vim.api.nvim_win_is_valid(session.result_win) then
		return true
	end
	if session.result_buf and vim.api.nvim_buf_is_valid(session.result_buf) then
		local wins = fn.win_findbuf(session.result_buf)
		if wins and wins[1] and vim.api.nvim_win_is_valid(wins[1]) then
			session.result_win = wins[1]
			return true
		end
	end
	if session.script_buf and vim.api.nvim_buf_is_valid(session.script_buf) then
		local wins = fn.win_findbuf(session.script_buf)
		if wins and wins[1] and vim.api.nvim_win_is_valid(wins[1]) then
			vim.api.nvim_set_current_win(wins[1])
			vim.cmd("vsplit " .. fn.fnameescape(session.work_path))
			session.result_win = vim.api.nvim_get_current_win()
			session.result_buf = vim.api.nvim_get_current_buf()
			vim.bo[session.result_buf].bufhidden = "hide"
			vim.bo[session.result_buf].swapfile = false
			ensure_indent_provider(session.result_buf)
			return true
		end
	end
	return false
end

	run_session = function(session)
		if not session then
			return
		end
		local ok_copy, copy_err = copy_file(session.input_path, session.work_path)
	if not ok_copy then
		vim.notify(string.format("VimGolf %s: %s", session.id, copy_err), log.levels.ERROR)
		return
	end
	ensure_script_saved(session)
	if not ensure_result_window(session) then
		vim.notify(string.format("VimGolf %s: unable to focus result window", session.id), log.levels.ERROR)
		return
	end
	ensure_indent_provider(session.result_buf)
		local ok_reload, reload_err = pcall(function()
			vim.api.nvim_win_call(session.result_win, function()
				vim.cmd("silent noautocmd edit!")
			end)
		end)
		if not ok_reload then
			vim.notify(string.format("VimGolf %s: %s", session.id, reload_err), log.levels.ERROR)
			return
		end
		local commands, parse_err = parse_script_commands(session.script_path)
		if not commands then
			vim.notify(string.format("VimGolf %s: %s", session.id, parse_err or "unable to read script"), log.levels.ERROR)
			return
		end
		local cursor_pos
		local ok_source, source_err = pcall(function()
			vim.api.nvim_win_call(session.result_win, function()
				vim.cmd("silent normal! gg0")
				for _, command in ipairs(commands) do
					if command.type == "ex" then
						local trimmed = trim(command.value)
						local lower = trimmed:lower()
						local is_close = lower == "wq" or lower == "wq!" or lower == "x" or lower == "xit" or lower == "xa" or lower == "xa!"
						if not is_close then
							vim.cmd(command.value)
						end
					else
						local stripped = trim(command.value)
						local upper = stripped:upper()
						if upper ~= "ZZ" and upper ~= "ZQ" then
							local keys = vim.api.nvim_replace_termcodes(command.value, true, false, true)
							vim.api.nvim_feedkeys(keys, "ntx", false)
						end
					end
				end
				vim.cmd("silent noautocmd write!")
				cursor_pos = vim.api.nvim_win_get_cursor(0)
			end)
		end)
		if not ok_source then
			vim.notify(string.format("VimGolf %s: %s", session.id, source_err), log.levels.ERROR)
			return
		end
		set_session_cursor(session, cursor_pos)
	local matches, cmp_err = files_match(session.work_path, session.output_path)
	if matches == nil then
		vim.notify(string.format("VimGolf %s: %s", session.id, cmp_err), log.levels.ERROR)
		return
	end
	highlight_differences(session)
	if matches then
		vim.notify(string.format("VimGolf %s: output matches target", session.id), log.levels.INFO)
	else
		vim.notify(string.format("VimGolf %s: output differs from %s", session.id, session.output_path), log.levels.WARN)
	end
end

function M.open(opts)
	local id = trim(opts.args or "")
	if id == "" then
		vim.notify("VimGolf: challenge id required", log.levels.ERROR)
		return
	end
	local existing = sessions_by_id[id]
	if existing and focus_session(existing) then
		return
	end
	local challenge, err = ensure_challenge(id)
	if not challenge then
		vim.notify(string.format("VimGolf %s: %s", id, err or "unable to load challenge"), log.levels.ERROR)
		return
	end
	local session = {
		id = id,
		input_path = challenge.input_path,
		output_path = challenge.output_path,
		type = challenge.type,
		title = challenge.title,
		summary = challenge.summary,
	}
	session.work_path = string.format("%s/%s.work.%s", work_dir, id, session.type)
	session.script_path = string.format("%s/%s.vim", scripts_dir, id)
	local ok_copy, copy_err = copy_file(session.input_path, session.work_path)
	if not ok_copy then
		vim.notify(string.format("VimGolf %s: %s", id, copy_err), log.levels.ERROR)
		return
	end
	ensure_script_file(session)
	sessions_by_id[id] = session
	open_layout(session)
	run_session(session)
end

function M.run(opts)
	local id = trim(opts.args or "")
	local session
	if id ~= "" then
		session = sessions_by_id[id]
	else
		session = find_session_for_buffer(vim.api.nvim_get_current_buf())
	end
	if not session then
		vim.notify("VimGolf: no active session", log.levels.ERROR)
		return
	end
	run_session(session)
end

function M.submit()
	local session = find_session_for_buffer(vim.api.nvim_get_current_buf())
	if not session then
		vim.notify("VimGolf: submissions must run from an active challenge buffer", log.levels.ERROR)
		return
	end
	run_session(session)
	local matches, cmp_err = files_match(session.work_path, session.output_path)
	if matches == nil then
		vim.notify(string.format("VimGolf %s: %s", session.id, cmp_err), log.levels.ERROR)
		return
	end
	if not matches and not prompt_submit_anyway(session) then
		vim.notify(string.format("VimGolf %s: submission cancelled", session.id), log.levels.INFO)
		return
	end
	local log_blob, key_err = build_submission_log(session)
	if not log_blob then
		vim.notify(string.format("VimGolf %s: %s", session.id, key_err or "unable to prepare submission"), log.levels.ERROR)
		return
	end
	local payload, submit_err = post_submission(session, log_blob)
	if not payload then
		vim.notify(string.format("VimGolf %s: %s", session.id, submit_err or "submission failed"), log.levels.ERROR)
		return
	end
	local leaderboard = string.format("https://www.vimgolf.com/challenges/%s", session.id)
	vim.notify(string.format("VimGolf %s: entry uploaded. View: %s", session.id, leaderboard), log.levels.INFO)
end

vim.api.nvim_create_user_command("Vimgolf", function(opts)
	M.open(opts)
end, {
	nargs = 1,
	complete = function()
		local cached = fn.glob(put_dir .. "/*.input.*", 0, 1)
		if type(cached) ~= "table" then
			return {}
		end
		local ids = {}
		for _, path in ipairs(cached) do
			local id = path:match("/([^/]+)%.input%.")
			if id then
				ids[id] = true
			end
		end
		local list = {}
		for id, _ in pairs(ids) do
			table.insert(list, id)
		end
		table.sort(list)
		return list
	end,
})

vim.api.nvim_create_user_command("VimgolfRun", function(opts)
	M.run(opts)
end, {
	nargs = "?",
	complete = function()
		return active_ids()
	end,
})

vim.api.nvim_create_user_command("VimgolfSubmit", function()
	M.submit()
end, {
	nargs = 0,
})

return M
