local path = vim.fn.expand("~/.config/current-theme/neovim.lua")
local chunk, load_error = loadfile(path)

if chunk == nil then
	error(("failed to load theme from %s: %s"):format(path, load_error))
end

local theme = chunk()

if type(theme) ~= "table" or type(theme.spec) ~= "table" or type(theme.colors) ~= "table" then
	error(("invalid theme definition: %s"):format(path))
end

require("0xec.theme.syntax").setup(vim.fn.expand("~/.config/current-theme/opencode.json"))

return theme
