local servers = require("0xec.lsp.servers")

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
		},
		config = function()
			local lsp = require("0xec.util.lsp")
			local effect = require("0xec.util.effect")
			local border = "rounded"
			local diagnostic_icons = {
				[vim.diagnostic.severity.ERROR] = "",
				[vim.diagnostic.severity.WARN] = "",
				[vim.diagnostic.severity.INFO] = "",
				[vim.diagnostic.severity.HINT] = "󰌶",
			}

			lsp.setup()

			vim.diagnostic.config({
				virtual_text = {
					spacing = 2,
					prefix = function(diagnostic)
						return diagnostic_icons[diagnostic.severity] or "●"
					end,
				},
				signs = {
					text = diagnostic_icons,
				},
				severity_sort = true,
				underline = true,
				update_in_insert = false,
				float = {
					border = border,
					source = true,
				},
			})

			vim.api.nvim_create_user_command("LspLog", function()
				vim.cmd("tabnew " .. vim.lsp.log.get_filename())
			end, {
				desc = "Open the Nvim LSP client log",
			})

			vim.api.nvim_create_user_command("LspBuf", function()
				local clients = vim.lsp.get_clients({ bufnr = 0 })
				if #clients == 0 then
					print("No LSP clients attached to current buffer")
					return
				end
				for _, c in ipairs(clients) do
					print(("• %s  (id=%d)  root=%s"):format(c.name, c.id, c.root_dir or "—"))
				end
			end, {
				desc = "Show LSP clients attached to current buffer",
			})

			-- Captured before we override it below, while nvim-lspconfig is loaded (it is a dependency).
			local ts_ls_root_dir = vim.lsp.config.ts_ls.root_dir

			for server, config in pairs(servers) do
				local merged = vim.tbl_deep_extend("force", { capabilities = lsp.capabilities() }, config)

				if server == "ts_ls" and ts_ls_root_dir then
					merged.root_dir = function(bufnr, on_dir)
						-- Never run ts_ls alongside effect_tsgo: duplicate diagnostics and two TS engines.
						local root, exe = effect.resolve(bufnr)
						if root and exe then
							return
						end
						ts_ls_root_dir(bufnr, on_dir)
					end
				end

				vim.lsp.config(server, merged)
			end

			-- Not a Mason package, so mason-lspconfig will never enable it; root_dir gates it per buffer.
			vim.lsp.enable("effect_tsgo")
		end,
	},
}
