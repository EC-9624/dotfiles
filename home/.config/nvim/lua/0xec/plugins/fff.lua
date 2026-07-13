return {
	"dmtrKovalenko/fff.nvim",
	lazy = false,
	build = function()
		require("fff.download").download_or_build_binary()
	end,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		layout = {
			height = 0.8,
			width = 0.95,
			prompt_position = "top",
			preview_position = "right",
			preview_size = 0.45,
			border = "rounded",
			path_shorten_strategy = "middle_number",
		},
		keymaps = {
			move_up = { "<Up>", "<C-p>", "<C-k>" },
			move_down = { "<Down>", "<C-n>", "<C-j>" },
			preview_scroll_up = "<C-u>",
			preview_scroll_down = "<C-d>",
			send_to_quickfix = "<C-q>",
		},
	},
}
