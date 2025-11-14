---------------------------
----- Template  Builder ---
---------------------------
---@class TemplateBuilder
local TemplateBuilder = {}
TemplateBuilder.__index = TemplateBuilder

local default_opt_builder = {
	title = "",
	type = "yaml",
	sep = "-",
	_header = "",
	_body = "",
	_substitution = {
		title = function(obj, _)
			return obj.title
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

---@param opts {type: string?} options for the template
---@return templateBuilder TemplateBuilder
function TemplateBuilder:new(opts)
	local opts = vim.tbl_deep_extend("force", default_opt_builder, opts)
	local templateBuilder = setmetatable(opts, self)
	templateBuilder._header = string.rep(templateBuilder.sep, 3, "")
	return templateBuilder
end

function TemplateBuilder:performSubstitution(value)
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
---@return templateBuilder TemplateBuilder
function TemplateBuilder:withHeader(key, value)
	value = self:performSubstitution(value)
	self._header = string.format("%s\n%s: %s", self._header, key, value)
	return self
end

---@param data string Any text to be sequentially added to the body
---@return templateBuilder TemplateBuilder
function TemplateBuilder:withBody(data)
	data = self:performSubstitution(data)
	self._body = string.format("%s\n%s", self._body, data)
	return self
end

---@return templateData string The string substituted.
function TemplateBuilder:build()
	self._header = string.format("%s\n%s", self._header, string.rep(self.sep, 3, ""))
	local result = self._header .. "\n" .. self._body
	return result
end

---------------------------
------ Template -----------
---------------------------
---@class Template
local Template = {}
Template.__index = Template
Template.title = ""

---@type Template
local template = nil

local default_opts = {
	title = "",
	template_builder = nil,
}

---@param opts {title: string?} options for the template
function Template.new(opts)
	local opts = vim.tbl_deep_extend("force", default_opts, opts)
	local template = setmetatable(opts, Template)
	return template
end

---@return builder TemplateBuilder
function Template:builder()
	self.template_builder = TemplateBuilder:new({ type = self.type, title = self.title })
	return self.template_builder
end

return Template
