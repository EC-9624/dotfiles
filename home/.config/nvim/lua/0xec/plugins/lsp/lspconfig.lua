local servers = {
	bashls = {},
	cssls = {},
	gopls = {},
	html = {},
	intelephense = {},
	jsonls = {},
	lua_ls = {
		settings = {
			Lua = {
				completion = {
					callSnippet = "Replace",
				},
				workspace = {
					checkThirdParty = false,
				},
			},
		},
	},
	svelte = {},
	terraformls = {},
	yamlls = {},
	tailwindcss = {
		filetypes = {
			"astro",
			"css",
			"html",
			"javascript",
			"javascriptreact",
			"svelte",
			"typescript",
			"typescriptreact",
		},
	},
	ts_ls = {
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
		},
		init_options = {
			preferences = {
				includeCompletionsForModuleExports = true,
				quotePreference = "auto",
			},
		},
		settings = {
			javascript = {
				inlayHints = {
					includeInlayEnumMemberValueHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayVariableTypeHintsWhenTypeMatchesName = true,
				},
			},
			typescript = {
				inlayHints = {
					includeInlayEnumMemberValueHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayVariableTypeHintsWhenTypeMatchesName = true,
				},
			},
		},
	},
	oxlint = {},
	astro = {},
}

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
		},
		config = function()
			local lsp = require("0xec.util.lsp")
			local border = "rounded"

			lsp.setup()

			vim.diagnostic.config({
				virtual_text = {
					spacing = 2,
					prefix = "●",
				},
				signs = true,
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

			for server, config in pairs(servers) do
				vim.lsp.config(
					server,
					vim.tbl_deep_extend("force", {
						capabilities = lsp.capabilities(),
					}, config)
				)
			end
		end,
	},
}
