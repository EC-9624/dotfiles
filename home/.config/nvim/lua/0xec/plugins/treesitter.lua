local parser_languages = {
	"bash",
	"astro",
	"css",
	"dockerfile",
	"go",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"php",
	"query",
	"svelte",
	"templ",
	"terraform",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

local highlight_filetypes = {
	"astro",
	"bash",
	"css",
	"dockerfile",
	"go",
	"html",
	"javascript",
	"javascriptreact",
	"json",
	"lua",
	"markdown",
	"php",
	"query",
	"svelte",
	"templ",
	"terraform",
	"typescript",
	"typescriptreact",
	"vim",
	"yaml",
}

local function install_missing_parsers()
	local treesitter = require("nvim-treesitter")
	local installed = {}

	for _, language in ipairs(treesitter.get_installed()) do
		installed[language] = true
	end

	local missing = vim.tbl_filter(function(language)
		return not installed[language]
	end, parser_languages)

	if #missing > 0 then
		treesitter.install(missing)
	end
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = function()
			local treesitter = require("nvim-treesitter")

			treesitter.install(parser_languages):wait(300000)
			treesitter.update(parser_languages):wait(300000)
		end,
		config = function()
			require("nvim-treesitter").setup({
				auto_install = true,
			})
			vim.api.nvim_create_autocmd("FileType", {
				pattern = highlight_filetypes,
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
			install_missing_parsers()
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup({
				enable = false,
				max_lines = 1,
				trim_scope = "inner",
			})
		end,
	},
}
