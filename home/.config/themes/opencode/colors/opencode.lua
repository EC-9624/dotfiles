local color = require("0xec.theme.tokens").load(vim.fn.expand("~/.config/themes/opencode/opencode.json"), "dark")
local fg, bg = color("text.base"), color("background.base")
local muted, surface = color("text.muted"), color("background.raised.base")
local raised, selection = color("background.raised.high"), color("background.raised.max")
local accent = color("hue.interactive.200")

vim.g.colors_name = nil
vim.o.background = "dark"
vim.cmd("highlight clear")
vim.g.colors_name = "opencode"

local groups = {
	Normal = { fg = fg, bg = bg },
	NormalNC = { link = "Normal" },
	NormalFloat = { fg = fg, bg = surface },
	FloatBorder = { fg = muted, bg = surface },
	FloatTitle = { fg = accent, bg = surface, bold = true },
	WinSeparator = { fg = color("border.base") },
	LineNr = { fg = muted },
	CursorLineNr = { fg = accent, bold = true },
	CursorLine = { bg = raised },
	Visual = { fg = fg, bg = selection },
	FFFCursorLine = { link = "Visual" },
	FFFSelectedActive = { fg = accent, bg = selection, bold = true },
	Pmenu = { link = "NormalFloat" },
	PmenuSel = { link = "Visual" },
	Search = { fg = bg, bg = accent },
	Directory = { fg = color("hue.blue.200") },
	-- Transparent lualine sections inherit these, not Normal.
	StatusLine = { fg = fg, bg = surface },
	StatusLineNC = { fg = muted, bg = surface },
	DiagnosticError = { fg = color("text.feedback.error.base") },
	DiagnosticWarn = { fg = color("text.feedback.warning.base") },
	DiagnosticInfo = { fg = color("text.feedback.info.base") },
	DiagnosticHint = { fg = color("hue.purple.200") },
	DiffAdd = { bg = color("diff.background.added") },
	DiffDelete = { fg = color("diff.text.removed"), bg = color("diff.background.removed") },
	DiffChange = { bg = raised },
	DiffText = { link = "Visual" },
}
for group, settings in pairs(groups) do
	vim.api.nvim_set_hl(0, group, settings)
end
