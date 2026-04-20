local js_fts = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo", "ConformFormat", "XoFix" },
		config = function()
			local conform = require("conform")
			local js_tooling = require("0xec.util.js_tooling")

			conform.setup({
				formatters = {
					prettierd = {
						prepend_args = { "--no-bracket-spacing" },
					},
					prettier = {
						prepend_args = { "--no-bracket-spacing" },
					},
					xo_fix = {
						meta = {
							url = "https://github.com/xojs/xo",
							description = "Fix auto-fixable XO/ESLint issues",
						},
						command = function()
							local project = js_tooling.current_project(0)
							return js_tooling.find_local_or_global_binary(project.root, "xo")
						end,
						args = { "--fix", "$FILENAME" },
						stdin = false,
						tmpfile = "conform_$FILENAME",
						cwd = function()
							return js_tooling.current_project(0).root
						end,
						condition = function()
							return js_tooling.current_project(0).profile == "xo"
						end,
						exit_codes = { 0, 1 },
					},
				},
				formatters_by_ft = {
					javascript = { "prettierd", "prettier", stop_after_first = true },
					javascriptreact = { "prettierd", "prettier", stop_after_first = true },
					typescript = { "prettierd", "prettier", stop_after_first = true },
					typescriptreact = { "prettierd", "prettier", stop_after_first = true },
					astro = { "prettierd", "prettier", stop_after_first = true },
					css = { "prettierd", "prettier", stop_after_first = true },
					html = { "prettierd", "prettier", stop_after_first = true },
					json = { "prettierd", "prettier", stop_after_first = true },
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
				format_after_save = function(bufnr)
					if vim.bo[bufnr].buftype ~= "" then
						return
					end
					if not vim.tbl_contains(js_fts, vim.bo[bufnr].filetype) then
						return
					end
					-- xo_fix's condition auto-skips non-XO projects
					return { formatters = { "xo_fix" }, lsp_format = "never", timeout_ms = 15000 }
				end,
			})

			vim.api.nvim_create_user_command("XoFix", function()
				conform.format({ formatters = { "xo_fix" }, async = true, timeout_ms = 30000 })
			end, { desc = "Run XO --fix on current buffer" })

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
