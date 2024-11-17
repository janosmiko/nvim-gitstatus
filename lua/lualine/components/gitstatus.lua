local M = require("lualine.component"):extend()
local highlight = require("lualine.highlight")
local gitstatus = require("nvim-gitstatus")

--- @class GitStatusLualineOptions
local default_options = {
	--- @type table<{[1]: string, format: string, hl?: string}>?
	sections = {
		{ "up_to_date", format = "" },
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

	for i, section in ipairs(self.options.sections) do
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

			if fg then
				hl_groups["gitstatus_" .. i] =
					highlight.create_component_highlight_group({ fg = fg }, "gitstatus_" .. i, self.options)
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

	for i, section in ipairs(self.options.sections) do
		--- @type string|number?
		local value = status[section[1]]
		if value and value ~= 0 then
			table.insert(
				parts,
				highlight.component_format_highlight(self.hl_groups["gitstatus_" .. i])
					.. string.gsub(section.format, "{}", value)
			)
		end
	end

	return table.concat(parts, self.options.sep)
end

return M
