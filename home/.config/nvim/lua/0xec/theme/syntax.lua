local M = {}

local legacy = {
	Comment = "comment",
	SpecialComment = "comment",
	Constant = "number",
	Boolean = "number",
	Number = "number",
	Float = "number",
	String = "string",
	Character = "string",
	SpecialChar = "string",
	Identifier = "variable",
	Function = "function",
	Statement = "keyword",
	Conditional = "keyword",
	Repeat = "keyword",
	Label = "keyword",
	Keyword = "keyword",
	Exception = "keyword",
	Debug = "keyword",
	PreProc = "keyword",
	Include = "keyword",
	Define = "keyword",
	Macro = "keyword",
	PreCondit = "keyword",
	StorageClass = "keyword",
	Type = "type",
	Structure = "type",
	Typedef = "type",
	Tag = "type",
	Operator = "operator",
	Delimiter = "punctuation",
}

local captures = {
	comment = "comment",
	keyword = "keyword",
	["keyword.operator"] = "operator",
	["function"] = "function",
	method = "function",
	constructor = "type",
	variable = "variable",
	parameter = "variable",
	property = "variable",
	field = "variable",
	module = "variable",
	namespace = "variable",
	constant = "number",
	boolean = "number",
	number = "number",
	float = "number",
	string = "string",
	character = "string",
	type = "type",
	["type.qualifier"] = "keyword",
	attribute = "type",
	label = "keyword",
	operator = "operator",
	punctuation = "punctuation",
	tag = "type",
	["tag.attribute"] = "variable",
	["tag.delimiter"] = "punctuation",
}

local semantic = {
	comment = "comment",
	keyword = "keyword",
	["function"] = "function",
	method = "function",
	macro = "function",
	variable = "variable",
	parameter = "variable",
	property = "variable",
	namespace = "variable",
	event = "variable",
	enumMember = "number",
	boolean = "number",
	number = "number",
	string = "string",
	regexp = "string",
	class = "type",
	struct = "type",
	interface = "type",
	enum = "type",
	type = "type",
	typeParameter = "type",
	typeAlias = "type",
	builtinType = "type",
	decorator = "type",
	operator = "operator",
}

local function category(group)
	if legacy[group] then
		return legacy[group]
	end
	local semantic_type = group:match("^@lsp%.type%.([^.]+)") or group:match("^@lsp%.typemod%.([^.]+)")
	if semantic_type then
		if group:match("^@lsp%.typemod%.variable%.callable") then
			return "function"
		end
		return semantic[semantic_type]
	end
	local capture = group:match("^@(.+)")
	while capture do
		if captures[capture] then
			return captures[capture]
		end
		capture = capture:match("^(.+)%.[^.]+$")
	end
end

function M.apply(color)
	local colors = {}
	for _, token in ipairs({
		"comment",
		"keyword",
		"function",
		"variable",
		"string",
		"number",
		"type",
		"operator",
		"punctuation",
	}) do
		colors[token] = color("syntax." .. token)
	end

	-- Include explicit language/capture overrides, not just their parent groups.
	local groups = vim.api.nvim_get_hl(0, {})
	for name in pairs(legacy) do
		groups[name] = true
	end
	for name in pairs(captures) do
		groups["@" .. name] = true
	end
	for name in pairs(semantic) do
		groups["@lsp.type." .. name] = true
	end
	groups["@lsp.typemod.variable.callable"] = true

	for name in pairs(groups) do
		local token = category(name)
		if token or name:match("^@lsp%.mod%.") then
			-- Keep font styles and diagnostic decorations; semantic modifiers must
			-- not repaint the foreground supplied by their token type.
			local highlight = vim.api.nvim_get_hl(0, { name = name, link = false, create = false })
			highlight.fg = token and colors[token] or nil
			highlight.ctermfg = nil
			vim.api.nvim_set_hl(0, name, highlight)
		end
	end
end

function M.setup(path)
	-- All three editor presets are pinned to dark variants (main/night/macchiato).
	local color = require("0xec.theme.tokens").load(path, "dark")
	local group = vim.api.nvim_create_augroup("0xec-theme-syntax", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			M.apply(color)
		end,
	})
end

return M
