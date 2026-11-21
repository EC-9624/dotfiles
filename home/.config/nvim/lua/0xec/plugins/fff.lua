local function cursor_highlight()
	-- A scheme can supply its own cursor highlight; otherwise use CursorLine.
	vim.api.nvim_set_hl(0, "FFFCursorLine", { link = "CursorLine", default = true })
end

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
		hl = { cursor = "FFFCursorLine" },
		layout = {
			height = 0.8,
			width = 0.95,
			prompt_position = "top",
			preview_position = "right",
			preview_size = 0.45,
			border = "single",
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
	config = function(_, opts)
		cursor_highlight()
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("0xec-fff-theme", { clear = true }),
			callback = cursor_highlight,
		})
		require("fff").setup(opts)
	end,
}
