local npm_root = vim.trim(vim.fn.system({ "npm", "root", "-g" }))
local typescript = require("0xec.util.typescript")

local function native_typescript(server)
	return {
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		root_dir = function(bufnr, on_dir)
			local root, _, selected = typescript.resolve(bufnr)
			if selected == server then
				on_dir(root)
			end
		end,
		cmd = function(dispatchers, config)
			local root = (config or {}).root_dir
			return vim.lsp.rpc.start({ typescript.exe(root), "--lsp", "--stdio" }, dispatchers, { cwd = root })
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
	}
end

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
	-- Native servers use the workspace installation, never Mason's compiler.
	effect_tsgo = native_typescript("effect_tsgo"),
	tsc = native_typescript("tsc"),
	oxlint = {
		root_markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts", "package.json", ".git" },
		workspace_required = false,
	},
	astro = {},
	zls = {},
}
