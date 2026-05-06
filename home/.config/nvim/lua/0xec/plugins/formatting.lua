local js_fts = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

local function find_local_binary(start, name)
	local root = vim.fs.root(start, { "package.json", ".git" })
	local current = root

	while current and current ~= "" do
		local candidate = vim.fs.joinpath(current, "node_modules", ".bin", name)
		local stat = vim.uv.fs_stat(candidate)
		if stat and stat.type == "file" then
			return candidate
		end

		local parent = vim.fs.dirname(current)
		if parent == current then
			break
		end

		current = parent
	end
end

local function formatter_root(_, ctx)
	return vim.fs.root(ctx.dirname, {
		".oxfmtrc.json",
		".oxfmtrc.jsonc",
		"oxfmt.config.ts",
		"package.json",
	})
end

return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo", "ConformFormat" },
		config = function()
			local conform = require("conform")

			conform.setup({
				formatters = {
					oxfmt = {
						inherit = true,
						command = function(_, ctx)
							return find_local_binary(ctx.dirname, "oxfmt") or "oxfmt"
						end,
						condition = function(_, ctx)
							return find_local_binary(ctx.dirname, "oxfmt") ~= nil
						end,
						cwd = formatter_root,
					},
					prettierd = {
						prepend_args = { "--no-bracket-spacing" },
					},
					prettier = {
						prepend_args = { "--no-bracket-spacing" },
					},
				},
				formatters_by_ft = {
					javascript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
					javascriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
					typescript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
					typescriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
					astro = { "prettierd", "prettier", stop_after_first = true },
					css = { "prettierd", "prettier", stop_after_first = true },
					html = { "prettierd", "prettier", stop_after_first = true },
					json = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
					svelte = { "prettierd", "prettier", stop_after_first = true },
					yaml = { "prettierd", "prettier", stop_after_first = true },
					lua = { "stylua" },
				},
				format_on_save = function(bufnr)
					if vim.bo[bufnr].buftype ~= "" then
						return
					end
					local is_js = vim.tbl_contains(js_fts, vim.bo[bufnr].filetype)
					return { lsp_format = is_js and "never" or "fallback", timeout_ms = 5000 }
				end,
			})

			vim.api.nvim_create_user_command("ConformFormat", function(opts)
				conform.format({
					formatters = #opts.fargs > 0 and opts.fargs or nil,
					async = true,
					timeout_ms = 30000,
				})
			end, {
				nargs = "*",
				desc = "Format buffer (async). Usage: :ConformFormat [formatter_name ...]",
				complete = function()
					local names = {}
					local seen = {}
					for name, _ in pairs(conform.formatters) do
						if not seen[name] then
							table.insert(names, name)
							seen[name] = true
						end
					end
					for _, info in ipairs(conform.list_all_formatters()) do
						if not seen[info.name] then
							table.insert(names, info.name)
							seen[info.name] = true
						end
					end
					table.sort(names)
					return names
				end,
			})
		end,
	},
}
