return {
	{
		"delphinus/md-render.nvim",
		version = "*",
		cmd = "MdRender",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<leader>mp", "<Plug>(md-render-preview)", desc = "Markdown preview: toggle" },
			{ "<leader>mt", "<Plug>(md-render-preview-tab)", desc = "Markdown preview: toggle tab" },
			{ "<leader>md", "<Plug>(md-render-demo)", desc = "Markdown render demo" },
		},
	},
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			opts.picker = opts.picker or {}
			opts.picker.preview = require("md-render.snacks").preview()
		end,
	},
}
