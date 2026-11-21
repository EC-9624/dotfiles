local dir = vim.fn.expand("~/.config/themes/opencode")
local token = require("0xec.theme.tokens").load(dir .. "/opencode.json", "dark")

return {
	-- These roles are consumed by the existing lualine and bufferline configs.
	colors = {
		base = token("background.base"),
		surface = token("background.raised.base"),
		overlay = token("background.raised.high"),
		text = token("text.base"),
		muted = token("text.muted"),
		subtle = token("hue.neutral.300"),
		love = token("text.feedback.error.base"),
		gold = token("hue.interactive.200"),
		rose = token("syntax.number"),
		pine = token("hue.blue.200"),
		foam = token("text.feedback.success.base"),
		iris = token("hue.accent.200"),
		highlight_med = token("border.base"),
		highlight_high = token("hue.neutral.300"),
		none = "NONE",
	},
	spec = {
		name = "dotfiles-opencode-nvim",
		dir = dir,
		lazy = false,
		priority = 1000,
		opts = {},
		config = function()
			-- A live preview can be the first time this local colorscheme is loaded.
			if not vim.tbl_contains(vim.opt.runtimepath:get(), dir) then
				vim.opt.runtimepath:prepend(dir)
			end
			vim.cmd.colorscheme("opencode")
		end,
	},
}
