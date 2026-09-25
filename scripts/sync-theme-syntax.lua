-- Run with: nvim --headless -u NONE -l scripts/sync-theme-syntax.lua [--check]
local root = vim.fn.fnamemodify(arg[0], ":p:h:h")
vim.opt.runtimepath:prepend(root .. "/home/.config/nvim")
local tokens = require("0xec.theme.tokens")

local themes = {
	["rose-pine"] = "Rose Pine",
	["tokyo-night"] = "Tokyo Night",
	catppuccin = "Catppuccin Macchiato",
}

-- TextMate/Syntect equivalents of Neovim's syntax categories. Specific scopes
-- override their broader parents (for example, keyword.operator and variable.function).
local rules = {
	{ "syntax.comment", "comment, punctuation.definition.comment", "italic" },
	{ "syntax.string", "string, constant.character, punctuation.definition.string" },
	{ "syntax.number", "constant, constant.numeric, constant.language" },
	{ "syntax.variable", "variable, support.variable, entity.other.attribute-name, entity.name.namespace" },
	{ "syntax.keyword", "keyword, storage" },
	{ "syntax.function", "entity.name.function, support.function, variable.function" },
	{
		"syntax.type",
		"entity.name.type, entity.name.class, entity.name.tag, support.type, support.class",
	},
	{ "syntax.operator", "keyword.operator" },
	{ "syntax.punctuation", "punctuation" },
	{ "markdown.heading", "markup.heading", "bold" },
	{ "markdown.strong", "markup.bold", "bold" },
	{ "markdown.emphasis", "markup.italic", "italic" },
	{ "markdown.code", "markup.raw.inline" },
	{ "markdown.codeBlock", "markup.raw.block" },
	{ "markdown.link", "markup.underline.link", "underline" },
	{ "markdown.linkText", "string.other.link.title, string.other.link.description" },
	{ "markdown.blockQuote", "markup.quote", "italic" },
	{ "markdown.listItem", "markup.list.unnumbered" },
	{ "markdown.listEnumeration", "markup.list.numbered" },
	{ "text.feedback.error.base", "invalid" },
	{ "diff.text.added", "markup.inserted" },
	{ "diff.text.removed", "markup.deleted" },
}

local function xml(text)
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

for name, title in pairs(themes) do
	local directory = root .. "/home/.config/themes/" .. name
	local color = tokens.load(directory .. "/opencode.json", "dark")
	local lines = {
		'<?xml version="1.0" encoding="UTF-8"?>',
		'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
		"<!-- Generated from opencode.json (dark) by scripts/sync-theme-syntax.lua. -->",
		'<plist version="1.0">',
		"<dict>",
		"\t<key>name</key><string>" .. xml(title) .. "</string>",
		"\t<key>settings</key>",
		"\t<array>",
		"\t\t<dict><key>settings</key><dict>",
	}
	-- Syntect needs a concrete palette color; OpenCode's canvas is transparent.
	for _, setting in ipairs({
		{ "background", "hue.neutral.800" },
		{ "foreground", "text.base" },
		{ "caret", "text.base" },
		{ "selection", "background.raised.high" },
	}) do
		lines[#lines + 1] = ("\t\t\t<key>%s</key><string>%s</string>"):format(setting[1], color(setting[2]))
	end
	lines[#lines + 1] = "\t\t</dict></dict>"
	for _, rule in ipairs(rules) do
		vim.list_extend(lines, {
			"\t\t<dict>",
			"\t\t\t<key>name</key><string>" .. rule[1] .. "</string>",
			"\t\t\t<key>scope</key><string>" .. xml(rule[2]) .. "</string>",
			"\t\t\t<key>settings</key><dict>",
			"\t\t\t\t<key>foreground</key><string>" .. color(rule[1]) .. "</string>",
			"\t\t\t\t<key>fontStyle</key><string>" .. (rule[3] or "") .. "</string>",
			"\t\t\t</dict>",
			"\t\t</dict>",
		})
	end
	vim.list_extend(lines, { "\t</array>", "</dict>", "</plist>" })
	local path = directory .. "/yazi.tmTheme"
	if arg[1] == "--check" then
		assert(vim.deep_equal(vim.fn.readfile(path), lines), path .. " is stale; run scripts/sync-theme-syntax.lua")
	else
		assert(vim.fn.writefile(lines, path) == 0, "failed to write " .. path)
	end
	print((arg[1] == "--check" and "verified: " or "generated: ") .. name .. "/yazi.tmTheme")
end
