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
			})

			-- Run xo --fix on the actual saved file after prettier formats.
			-- Uses vim.system (async) so the editor is not blocked.
			local xo_fix_group = vim.api.nvim_create_augroup("0xec-xo-fix", { clear = true })

			vim.api.nvim_create_autocmd("BufWritePost", {
				group = xo_fix_group,
				pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
				callback = function(args)
					local bufnr = args.buf

					-- Skip the re-save that conform triggers after format_on_save
					if vim.b[bufnr].conform_applying_formatting then
						return
					end

					-- Skip if xo --fix is already running for this buffer
					if vim.b[bufnr]._xo_fixing then
						return
					end

					local project = js_tooling.current_project(bufnr)
					if project.profile ~= "xo" then
						return
					end

					local file = vim.api.nvim_buf_get_name(bufnr)
					local xo_bin = js_tooling.find_local_or_global_binary(project.root, "xo")

					vim.b[bufnr]._xo_fixing = true
					vim.system(
						{ xo_bin, "--fix", file, "--cwd=" .. project.root },
						{ cwd = project.root },
						vim.schedule_wrap(function()
							if not vim.api.nvim_buf_is_valid(bufnr) then
								return
							end

							vim.b[bufnr]._xo_fixing = false

							-- Reload from disk only if the user hasn't started editing
							if not vim.bo[bufnr].modified then
								vim.api.nvim_buf_call(bufnr, function()
									vim.cmd("silent! checktime")
								end)
							end
						end)
					)
				end,
			})

			-- Manual batch-fix command
			vim.api.nvim_create_user_command("XoFix", function()
				local bufnr = vim.api.nvim_get_current_buf()
				local project = js_tooling.current_project(bufnr)
				if project.profile ~= "xo" then
					vim.notify("Not an XO project", vim.log.levels.WARN)
					return
				end

				local file = vim.api.nvim_buf_get_name(bufnr)
				local xo_bin = js_tooling.find_local_or_global_binary(project.root, "xo")

				-- Save first so xo operates on the latest content
				vim.cmd("silent write")

				vim.system(
					{ xo_bin, "--fix", file, "--cwd=" .. project.root },
					{ cwd = project.root },
					vim.schedule_wrap(function()
						if vim.api.nvim_buf_is_valid(bufnr) then
							vim.api.nvim_buf_call(bufnr, function()
								vim.cmd("silent! edit")
							end)
						end
					end)
				)
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
