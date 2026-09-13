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
	"css",
	"dockerfile",
	"go",
	"help",
	"html",
	"javascript",
	"javascriptreact",
	"json",
	"lua",
	"markdown",
	"php",
	"query",
	"sh",
	"svelte",
	"templ",
	"terraform",
	"typescript",
	"typescriptreact",
	"vim",
	"yaml",
}

local installing = {}

local function start_highlighting(bufnr)
	if not vim.api.nvim_buf_is_loaded(bufnr) or not vim.tbl_contains(highlight_filetypes, vim.bo[bufnr].filetype) then
		return
	end

	local language = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
	if language and installing[language] then
		return
	end

	local ok, err = pcall(vim.treesitter.start, bufnr)
	if not ok then
		vim.notify_once(
			("Treesitter highlighting failed for %s: %s. Run :checkhealth nvim-treesitter and :TSInstall %s."):format(
				vim.bo[bufnr].filetype,
				err,
				language or vim.bo[bufnr].filetype
			),
			vim.log.levels.WARN
		)
	end
end

local function install_missing_parsers()
	local treesitter = require("nvim-treesitter")
	local installed = {}

	for _, language in ipairs(treesitter.get_installed("parsers")) do
		installed[language] = true
	end

	local missing = vim.tbl_filter(function(language)
		return not installed[language]
	end, parser_languages)

	if #missing > 0 then
		for _, language in ipairs(missing) do
			installing[language] = true
		end

		-- Force only missing parsers, so leftover queries cannot make installation skip them.
		treesitter.install(missing, { force = true }):await(vim.schedule_wrap(function(err, success)
			installing = {}
			if err or not success then
				vim.notify_once(
					("Treesitter parser installation failed: %s. Run :checkhealth nvim-treesitter and retry :TSInstall %s."):format(
						err or "see parser installation messages",
						table.concat(missing, " ")
					),
					vim.log.levels.WARN
				)
			end

			-- FileType may have fired before the asynchronous installation finished.
			for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
				start_highlighting(bufnr)
			end
		end))
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
			local group = vim.api.nvim_create_augroup("0xec-treesitter-highlight", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = highlight_filetypes,
				callback = function(event)
					start_highlighting(event.buf)
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
