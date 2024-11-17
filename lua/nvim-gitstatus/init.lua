--- @class GitStatus
--- @field branch string
--- @field upstream_branch string
--- @field ahead number
--- @field behind number
--- @field stashed number
--- @field conflicted number
--- @field deleted number
--- @field modified number
--- @field renamed number
--- @field staged number
--- @field untracked number

--- @class GitStatusPlugin
local M = {
	--- @class GitStatusOptions
	--- Plugin options
	opts = {
		--- @type (number|false)?
		--- @default 30000
		--- Auto fetch interval in milliseconds. Set to false to disable auto fetch.
		auto_fetch_interval = 30000,
		--- @type number?
		--- @default 1000
		--- Timeout for the git status command in milliseconds.
		git_status_timeout = 1000,
	},
	--- @type GitStatus?
	--- Current git status, or nil if not available
	status = nil,
}

local git_status_running = false

--- Initialize the plugin
--- @param opts GitStatusOptions?
function M.setup(opts)
	-- Merge user options with defaults
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	-- Set up auto commands
	vim.api.nvim_create_autocmd({
		"BufWritePost", -- When saving a file
		"FileChangedShellPost", -- When a file changes outside of Neovim
	}, {
		callback = function()
			M.update_git_status()
		end,
	})

	-- Initialize git status
	M.update_git_status()
	M.git_fetch()

	-- Auto fetch
	if M.opts.auto_fetch_interval and M.opts.auto_fetch_interval > 0 then
		local timer = vim.uv.new_timer()
		local interval = M.opts.auto_fetch_interval or 30000
		timer:start(interval, interval, M.git_fetch)
	end
end

--- @param callback fun(success: boolean, status: GitStatus?)
local function try_get_status(callback)
	if git_status_running then
		callback(false, nil)
		return
	end

	vim.system({
		"git",
		"status",
		"--porcelain=2",
		"--branch",
		"--show-stash",
	}, {
		text = true,
		timeout = M.opts.git_status_timeout,
	}, function(obj)
		-- Terminated by timeout
		if obj.signal == 15 then
			callback(false, nil)
			return
		end

		-- Other errors, presume not a git repo
		if obj.code ~= 0 then
			M.status = nil
			callback(true, M.status)
			return
		end

		--- @type GitStatus
		local status = {
			branch = "",
			upstream_branch = "",
			ahead = 0,
			behind = 0,
			stashed = 0,
			conflicted = 0,
			deleted = 0,
			modified = 0,
			renamed = 0,
			staged = 0,
			untracked = 0,
		}

		-- Parse output
		local lines = vim.split(obj.stdout, "\n")
		for _, line in ipairs(lines) do
			local parts = vim.split(line, " ")
			if parts[1] == "#" then
				if parts[2] == "branch.head" then
					status.branch = parts[3]
				elseif parts[2] == "branch.upstream" then
					status.upstream_branch = parts[3]
				elseif parts[2] == "branch.ab" then
					status.ahead = tonumber(string.sub(parts[3], 2)) or 0
					status.behind = tonumber(string.sub(parts[4], 2)) or 0
				elseif parts[2] == "stash" then
					status.stashed = tonumber(parts[3]) or 0
				end
			elseif parts[1] == "1" then
				-- The second part is the status code XY, where X is the status of the
				-- index and Y is the status of the working directory. X and Y can be
				-- one of the following letters:
				--  - '.' = unmodified
				--  - 'M' = modified
				--  - 'D' = deleted
				--  - 'T' = type changed
				--  - etc. See at:
				-- https://git-scm.com/docs/git-status#_short_format
				local code_x = string.sub(parts[2], 1, 1)
				local code_y = string.sub(parts[2], 2, 2)
				if code_x ~= "." then
					status.staged = status.staged + 1
				end
				if code_y == "M" or code_y == "T" then
					status.modified = status.modified + 1
				elseif code_y == "D" then
					status.deleted = status.deleted + 1
				end
			elseif parts[1] == "2" then
				status.renamed = status.renamed + 1
			elseif parts[1] == "u" then
				status.conflicted = status.conflicted + 1
			elseif parts[1] == "?" then
				status.untracked = status.untracked + 1
			end
		end

		M.status = status
		callback(true, status)
	end)
end

local function try_git_fetch()
	vim.system({
		"git",
		"fetch",
	}, {
		text = true,
	}, function(obj)
		if obj.code == 0 then
			M.update_git_status()
		end
	end)
end

--- Update git status asynchronously, and call the callback when done. When
--- `success` is false, the git status is not updated. This happens when
--- either the git command times out, or another git command is still running.
--- @param callback fun(success: boolean, status: GitStatus?)?
function M.update_git_status(callback)
	callback = callback or function() end
	if not pcall(try_get_status, callback) then
		callback(false)
	end
end

--- Run git fetch asynchronously
function M.git_fetch()
	pcall(try_git_fetch)
end

--- @class GitStatusFormat
local default_format = {
	ahead_behind = true,
}

--- Format the git status
--- @param options GitStatusFormat?
--- @return string
function M.format(options)
	options = vim.tbl_deep_extend("force", default_format, options or {})

	local status = M.status
	if not status then
		return ""
	end

	local parts = {}
	if options.ahead_behind then
		if status.ahead and status.ahead > 0 then
			table.insert(parts, status.ahead .. "↑")
		end
		if status.behind and status.behind > 0 then
			table.insert(parts, status.behind .. "↓")
		end
	end

	if status.modified > 0 then
		table.insert(parts, status.modified .. "~")
	end

	return table.concat(parts, " ")
end

return M
