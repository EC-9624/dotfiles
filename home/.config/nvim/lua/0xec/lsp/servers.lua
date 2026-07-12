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
	oxlint = {
		root_markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts", "package.json", ".git" },
		workspace_required = false,
	},
	astro = {},
	zls = {},
}
