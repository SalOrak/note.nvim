local Logger = require("note.logger")
local Template = require("note.template")
local File = require("note.file")
local uv = vim.uv

---@field path string Path to the notes directory
---@field ext string Extension of the notes. Default to '.md'.
local M = {
	path = "~/notes/",
	ext = ".md",
}

M.setup = function(opts)
	M = vim.tbl_deep_extend("force", M, opts)
end

local function format_note(note)
	local result = note
	if string.match(note, M.ext) == nil then
		result = note .. M.ext
	end
	return result
end

---@param template Template? The template to use when creating the note. Use the helper Template class.
M.note = function(template)
	local cwd = vim.uv.cwd()
	vim.uv.chdir(M.path)
	vim.ui.input({ prompt = "New note: ", completion = "file_in_path" }, function(input)
		if input == nil or input == "" then
			Logger:info("No new created")
			return
		end

		local filepath = format_note(vim.uv.cwd() .. "/" .. input)
		if template and template ~= "" then
			local file_stats = vim.uv.fs_stat(filepath)
			if not (file_stats ~= nil and file_stats.size ~= 0) then
				File.writeFile(filepath, template)
			end
		end
		local command = ":e " .. filepath
		vim.cmd(command)
	end)
	vim.uv.chdir(cwd)
end

M.telescope_note = function()
	local b = require("telescope.builtin")
	b.find_files({
		cwd = M.path,
		hidden = false,
	})
end

return M
