local M = require("lualine.component"):extend()
local highlight = require("lualine.highlight")
local gitstatus = require("nvim-gitstatus")

local hl_id = 1

--- @class GitStatusLualineOptions
local default_options = {
	--- @type table<string|{[1]: string, format?: string, hl?: string}>?
	sections = {
		{ "ahead", format = "{}↑" },
		{ "behind", format = "{}↓" },
		{ "conflicted", format = "{}!" },
		{ "staged", format = "{}=" },
		{ "untracked", format = "{}+" },
		{ "modified", format = "{}*" },
		{ "renamed", format = "{}~" },
		{ "deleted", format = "{}-" },
	},
	--- @type string|{[1]: string, hl?: string}?
	sep = " ",
}

local function hl_to_hex(hl)
	if string.match(hl, "^#%x%x%x%x%x%x$") then
		return hl
	end

	local hl_info = vim.api.nvim_get_hl(0, {
		name = hl,
		link = false,
		create = false,
	})
	if hl_info and hl_info.fg then
		return string.format("#%06x", hl_info.fg)
	end

	return ""
end

function M:create_lualine_hl_groups()
	local hl_groups = {
		colorscheme = vim.g.colors_name,
		gitstatus_default = highlight.create_component_highlight_group({}, "gitstatus_default", self.options),
	}

	for _, section in ipairs(self.options.sections) do
		if section.hl then
			local fg = hl_to_hex(section.hl)

			if fg and section.hl_id then
				hl_groups[section.hl_id] =
					highlight.create_component_highlight_group({ fg = fg }, section.hl_id, self.options)
			end
		end
	end

	local sep = self.options.sep
	if sep and sep.hl then
		local fg = hl_to_hex(sep.hl)

		if fg and sep["hl_id"] then
			hl_groups[sep["hl_id"]] =
				highlight.create_component_highlight_group({ fg = fg }, self.options.sep.hl_id, self.options)
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
		if type(section) == "string" then
			section = { section }
		end

		if section.hl then
			section.hl_id = "gitstatus_" .. hl_id
			hl_id = hl_id + 1
		end
	end

	-- Do the same for the separator
	local sep = self.options.sep or ""
	if type(sep) == "string" then
		sep = { sep }
		self.options.sep = sep
	end

	if sep.hl then
		self.options.sep["hl_id"] = "gitstatus_" .. hl_id
		hl_id = hl_id + 1
	end

	self.hl_groups = self:create_lualine_hl_groups()
end

--- @param hl_id string?
--- @param str string
function M:highlight_with_lualine(hl_id, str)
	local hl_string = highlight.component_format_highlight(self.hl_groups[hl_id or "gitstatus_default"])
	return hl_string .. str
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

			local str = section.format or "{}"
			str = string.gsub(str, "{}", value)
			str = self:highlight_with_lualine(section.hl_id, str)

			table.insert(parts, str)
		end
	end

	local sep_str = ""
	if self.options.sep[1] ~= "" then
		sep_str = self:highlight_with_lualine(self.options.sep.hl_id, self.options.sep[1])
	end
	return table.concat(parts, sep_str)
end

return M
