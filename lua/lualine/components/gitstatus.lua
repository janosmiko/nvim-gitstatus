local M = require("lualine.component"):extend()
local highlight = require("lualine.highlight")
local gitstatus = require("nvim-gitstatus")

local hl_id = 1

--- @class GitStatusLualineOptions
local default_options = {
	--- @type table<{[1]: string, format?: string, hl?: string}>?
	sections = {
		{ "ahead", format = "{}↑" },
		{ "behind", format = "{}↓" },
		{ "staged", format = "{}=" },
		{ "conflicted", format = "{}!" },
		{ "untracked", format = "{}+" },
		{ "modified", format = "{}*" },
		{ "renamed", format = "{}~" },
		{ "deleted", format = "{}-" },
	},
	sep = " ",
}

function M:create_lualine_hl_groups()
	local hl_groups = {
		colorscheme = vim.g.colors_name,
	}

	for _, section in ipairs(self.options.sections) do
		if section.hl then
			local fg = ""
			if string.match(section.hl, "^#%x%x%x%x%x%x$") then
				fg = section.hl
			else
				local hl_info = vim.api.nvim_get_hl(0, {
					name = section.hl,
					link = false,
					create = false,
				})
				if hl_info and hl_info.fg then
					fg = string.format("#%06x", hl_info.fg)
				end
			end

			if fg and section.hl_id then
				hl_groups[section.hl_id] =
					highlight.create_component_highlight_group({ fg = fg }, section.hl_id, self.options)
			end
		end
	end

	return hl_groups
end

--- @override
--- @param options GitStatusLualineOptions
function M:init(options)
	M.super.init(self, options)
	self.options = vim.tbl_deep_extend("force", default_options, options or {})

	-- Assign unique highlight id to each section, for use with lualine
	for _, section in ipairs(self.options.sections) do
		if section.hl then
			section.hl_id = "gitstatus_" .. hl_id
			hl_id = hl_id + 1
		end
	end

	self.hl_groups = self:create_lualine_hl_groups()
end

--- @override
function M:update_status()
	local colorscheme = vim.g.colors_name
	if not self.hl_groups or self.hl_groups.colorscheme ~= colorscheme then
		self.hl_groups = self:create_lualine_hl_groups()
	end

	local status = gitstatus.status
	if not status then
		return ""
	end

	local parts = {}

	for _, section in ipairs(self.options.sections) do
		--- @type string|number|boolean?
		local value = status[section[1]]
		if value and value ~= 0 then
			-- Don't show 'true' for boolean values
			if value == true then
				value = ""
			end

			local hl_string = ""
			if section.hl and section.hl_id then
				hl_string = highlight.component_format_highlight(self.hl_groups[section.hl_id])
			end

			local value_string = section.format or "{}"
			value_string = string.gsub(value_string, "{}", value)

			table.insert(parts, hl_string .. value_string)
		end
	end

	return table.concat(parts, self.options.sep)
end

return M
