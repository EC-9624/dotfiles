-- Run with: nvim --headless -u NONE -l tests/theme-syntax.lua
local root = vim.fn.fnamemodify(arg[0], ":p:h:h")
vim.opt.runtimepath:prepend(root .. "/home/.config/nvim")
local tokens = require("0xec.theme.tokens")
local syntax = require("0xec.theme.syntax")
local scratch = vim.fn.tempname()
vim.fn.mkdir(scratch, "p")

local function equal(actual, expected, message)
	assert(
		vim.deep_equal(actual, expected),
		("%s: expected %s, got %s"):format(message, vim.inspect(expected), vim.inspect(actual))
	)
end

local function rejects(callback, message)
	local ok, err = pcall(callback)
	assert(
		not ok and tostring(err):find(message, 1, true),
		"expected error containing " .. message .. ", got " .. tostring(err)
	)
end

local function fixture(theme)
	local path = scratch .. "/theme.json"
	vim.fn.writefile({ vim.json.encode(theme) }, path)
	return path
end

local function test_tokens()
	local path = root .. "/home/.config/themes/rose-pine/opencode.json"
	local dark = tokens.load(path, "dark")
	local light = tokens.load(path, "light")
	equal(dark("syntax.function"), "#ebbcba", "dark hue alias")
	equal(light("syntax.function"), "#d7827e", "light hue alias")
	equal(light("syntax.keyword"), "#286983", "mode token override")
	equal(dark("@dialog.background.base"), "#1f1d2e", "semantic reference chain")
	equal(dark("hue.neutral.800"), "#191724", "concrete palette background")
	rejects(function()
		dark("background.formfield.base")
	end, "must resolve to an opaque #RRGGBB color")
	rejects(function()
		dark("syntax.missing")
	end, "missing theme token")
	rejects(function()
		dark("syntax")
	end, "must resolve to an opaque #RRGGBB color")

	local circular = fixture({
		base = { syntax = { keyword = "$hue.accent.200" } },
		dark = { hue = { accent = "$hue.other", other = "$hue.accent" } },
	})
	rejects(function()
		tokens.load(circular, "dark")("syntax.keyword")
	end, "circular theme reference")
	rejects(function()
		tokens.load(fixture({ base = {} }), "dark")
	end, "invalid OpenCode V2 theme")
	vim.fn.writefile({ "not JSON" }, scratch .. "/invalid.json")
	rejects(function()
		tokens.load(scratch .. "/invalid.json", "dark")
	end, "invalid OpenCode V2 theme")
	rejects(function()
		tokens.load(scratch .. "/missing.json", "dark")
	end, "cannot read theme tokens")
end

local cases = {
	{
		name = "rose-pine",
		plugin = "rose-pine",
		scheme = "rose-pine",
		colors = { "#6e6a86", "#31748f", "#ebbcba", "#e0def4", "#f6c177", "#c4a7e7", "#9ccfd8", "#908caa", "#908caa" },
	},
	{
		name = "tokyo-night",
		plugin = "tokyonight.nvim",
		scheme = "tokyonight-night",
		colors = { "#828bb8", "#c099ff", "#82aaff", "#ff757f", "#c3e88d", "#ff966c", "#ffc777", "#86e1fc", "#c8d3f5" },
	},
	{
		name = "catppuccin",
		plugin = "catppuccin",
		scheme = "catppuccin-macchiato",
		colors = { "#939ab7", "#c6a0f6", "#8aadf4", "#ed8796", "#a6da95", "#f5a97f", "#eed49f", "#91d7e3", "#cad3f5" },
	},
}

local groups = {
	{ "comment", "Comment", "@comment", "@lsp.type.comment" },
	{ "keyword", "Keyword", "StorageClass", "@keyword.storage", "@keyword.directive", "@lsp.type.keyword" },
	{
		"function",
		"Function",
		"@function.method.call",
		"@function.builtin",
		"@function.call.lua",
		"@lsp.type.method",
		"@lsp.typemod.variable.callable",
	},
	{
		"variable",
		"Identifier",
		"@variable",
		"@variable.parameter",
		"@variable.member",
		"@lsp.type.parameter",
		"@lsp.typemod.variable.defaultLibrary",
	},
	{ "string", "String", "@string.regexp", "@string.escape", "@lsp.type.string" },
	{ "number", "Number", "Float", "Boolean", "@number.float", "@lsp.type.number" },
	{ "type", "Type", "@type.builtin", "@constructor.tsx", "@lsp.type.interface", "@lsp.typemod.type.defaultLibrary" },
	{ "operator", "Operator", "@operator", "@keyword.operator", "@lsp.type.operator" },
	{ "punctuation", "Delimiter", "@punctuation.bracket", "@tag.delimiter.tsx" },
}

local function test_highlights()
	-- Simulate explicit theme/language overrides and higher-priority LSP modifiers.
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			vim.api.nvim_set_hl(0, "@function.call.lua", { fg = "#123456", italic = true })
			vim.api.nvim_set_hl(0, "@constructor.tsx", { fg = "#123456" })
			vim.api.nvim_set_hl(0, "@tag.delimiter.tsx", { fg = "#123456" })
			vim.api.nvim_set_hl(0, "@lsp.typemod.type.defaultLibrary", { fg = "#123456" })
			vim.api.nvim_set_hl(0, "@lsp.mod.readonly", { fg = "#123456", underline = true })
		end,
	})
	for _, case in ipairs(cases) do
		local plugin = vim.fn.stdpath("data") .. "/lazy/" .. case.plugin
		assert(vim.fn.isdirectory(plugin) == 1, "install Neovim theme plugin before testing: " .. plugin)
		vim.opt.runtimepath:prepend(plugin)
		local directory = root .. "/home/.config/themes/" .. case.name
		local color = tokens.load(directory .. "/opencode.json", "dark")
		syntax.setup(directory .. "/opencode.json")
		local theme = dofile(directory .. "/neovim.lua")
		theme.spec.opts.cache = false
		theme.spec.opts.compile_path = scratch .. "/catppuccin"
		theme.spec.config(nil, theme.spec.opts)

		local function verify()
			for index, entry in ipairs(groups) do
				local expected = case.colors[index]
				equal(color("syntax." .. entry[1]), expected, case.name .. " token " .. entry[1])
				for i = 2, #entry do
					local highlight = vim.api.nvim_get_hl(0, { name = entry[i], link = false })
					equal(highlight.fg, tonumber(expected:sub(2), 16), case.name .. " " .. entry[i])
				end
			end
			equal(
				vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg,
				nil,
				case.name .. " transparent background"
			)
			equal(
				vim.api.nvim_get_hl(0, { name = "@function.call.lua", link = false }).italic,
				true,
				"preserved syntax style"
			)
			local modifier = vim.api.nvim_get_hl(0, { name = "@lsp.mod.readonly", link = false })
			equal(modifier.fg, nil, "semantic modifier foreground")
			equal(modifier.underline, true, "semantic modifier decoration")
		end
		verify()
		vim.cmd.colorscheme(case.scheme)
		verify()
		print("verified syntax and colorscheme reload: " .. case.name)
	end
end

local ok, err = xpcall(function()
	test_tokens()
	test_highlights()
end, debug.traceback)
vim.fn.delete(scratch, "rf")
if not ok then
	error(err)
end
print("theme token and highlight checks passed")
