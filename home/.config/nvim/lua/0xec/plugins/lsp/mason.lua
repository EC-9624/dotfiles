-- effect_tsgo is installed per project (npm i -D @effect/tsgo), never through Mason.
local mason_servers = vim.tbl_filter(function(server)
	return server ~= "effect_tsgo"
end, vim.tbl_keys(require("0xec.lsp.servers")))
table.sort(mason_servers)

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
			ensure_installed = mason_servers,
			automatic_enable = mason_servers,
		},
	},
}
