return {
	"folke/trouble.nvim",
	cmd = "Trouble",
	dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
	opts = {
		focus = true,
	},
	keys = {
		{ "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", desc = "Workspace diagnostics: toggle list" },
		{
			"<leader>xd",
			"<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
			desc = "Document diagnostics: toggle list",
		},
		{ "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", desc = "Quickfix: toggle list" },
		{ "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list: toggle" },
		{ "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "TODO comments: toggle list" },
	},
}
