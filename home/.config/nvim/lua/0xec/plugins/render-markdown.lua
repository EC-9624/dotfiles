return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "norg", "rmd", "org" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		heading = {
			sign = false,
		},
		code = {
			sign = false,
			width = "block",
			right_pad = 1,
		},
		checkbox = {
			enabled = true,
		},
		html = {
			comment = {
				conceal = false,
			},
		},
	},
}
