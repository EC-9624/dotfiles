local npm_root = vim.trim(vim.fn.system({ "npm", "root", "-g" }))
local effect = require("0xec.util.effect")

return {
	bashls = {},
	cssls = {},
	gopls = {
		settings = {
			gopls = {
				semanticTokens = true,
			},
		},
	},
	html = {
		filetypes = { "html", "templ" },
	},
	htmx = {
		filetypes = { "html", "templ" },
	},
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
	marksman = {},
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
			"templ",
			"typescript",
			"typescriptreact",
		},
		init_options = {
			userLanguages = {
				templ = "html",
			},
		},
		settings = {
			tailwindCSS = {
				includeLanguages = {
					templ = "html",
				},
			},
		},
	},
	templ = {},
	ts_ls = {
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"css",
		},
		init_options = {
			plugins = {
				{
					name = "@css-modules-kit/ts-plugin",
					location = npm_root,
					languages = { "css" },
				},
			},
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
	-- Effect Language Service (TypeScript-Go). Installed per project, never by Mason.
	-- Attaches only where @effect/tsgo is installed and `get-exe-path` resolves a binary;
	-- ts_ls yields the buffer in that case (see plugins/lsp/lspconfig.lua).
	effect_tsgo = {
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		root_dir = function(bufnr, on_dir)
			local root, exe = effect.resolve(bufnr)
			if root and exe then
				on_dir(root)
			end
		end,
		cmd = function(dispatchers, config)
			local root = (config or {}).root_dir
			return vim.lsp.rpc.start({ effect.exe(root), "--lsp", "--stdio" }, dispatchers, { cwd = root })
		end,
		settings = {
			["js/ts"] = {
				inlayHints = {
					parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
					parameterTypes = { enabled = true },
					variableTypes = { enabled = true },
					propertyDeclarationTypes = { enabled = true },
					functionLikeReturnTypes = { enabled = true },
					enumMemberValues = { enabled = true },
				},
			},
		},
	},
	oxlint = {
		root_markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts", "package.json", ".git" },
		workspace_required = false,
	},
	astro = {},
	zls = {},
}
