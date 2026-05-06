local servers = {
	"bashls",
	"cssls",
	"gopls",
	"html",
	"intelephense",
	"jsonls",
	"lua_ls",
	"oxlint",
	"svelte",
	"terraformls",
	"yamlls",
	"tailwindcss",
	"ts_ls",
	"astro",
}

return {
	{
		"mason-org/mason.nvim",
		opts = {
			ui = {
				border = "rounded",
			},
		},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = servers,
			automatic_enable = servers,
		},
	},
}
