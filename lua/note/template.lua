---------------------------
------ Template -----------
---------------------------

---@class Template
local Template = {}
Template.__index = Template

local default_opts = {
	data = {
		title = "",
		enclose = "-",
		eq = ":",
	},
	_header = "",
	_body = "",
	_substitution = {
		title = function(obj, _)
			return obj.data.title
		end,
		date = function(obj, opts)
			local format = "%d-%m-%Y"
			if type(opts) == "string" and opts ~= "" then
				format = opts
			end
			return os.date(format)
		end,

		uuid = function(obj, _)
			local id, _ = vim.fn.system("uuidgen"):gsub("\n", "")
			return id
		end,
		pattern = "{([^:}]+):?(.-)}",
	},
}

function Template:performSubstitution(value)
	local result = value
	local res, d = string.gsub(result, self._substitution.pattern, function(t, data)
		if vim.list_contains(vim.tbl_keys(self._substitution), t) then
			return self._substitution[t](self, data)
		end
		return data
	end)
	return res
end

---@param key string Key parameter to addd
---@param value string Value parameter to add that has template substitution
---@return template Template
function Template:withHeader(key, value)
	-- value = self:performSubstitution(value)
	self._header = string.format("%s\n%s%s %s", self._header, key, self.data.eq, value)
	return self
end

---@param data string Any text to be sequentially added to the body
---@return template Template
function Template:withBody(data)
	-- data = self:performSubstitution(data)
	self._body = string.format("%s\n%s", self._body, data)
	return self
end

---@param opts {title: string?}
---@return template Template
function Template:setOpts(opts)
	self.data = vim.tbl_deep_extend("force", self.data, opts)
	return self
end

---@return templateData string The string substituted.
function Template:build()
	self._header = string.format("%s\n%s", self._header, string.rep(self.data.enclose, 3, ""))
	local result = self._header .. "\n" .. self._body
	result = self:performSubstitution(result)
	return result
end

---@param opts {title: string?} options for the template (in Data)
function Template.new(opts)
	local data = vim.tbl_deep_extend("force", default_opts.data, opts)
	local template = setmetatable(default_opts, Template)
	template._header = string.rep(template.data.enclose, 3, "")
	return template
end

return Template
