local colors = {
	base = "#282828",
	surface = "#3c3836",
	overlay = "#504945",
	muted = "#928374",
	subtle = "#bdae93",
	text = "#ebdbb2",
	love = "#fb4934",
	gold = "#fabd2f",
	rose = "#fe8019",
	pine = "#83a598",
	foam = "#8ec07c",
	iris = "#d3869b",
	highlight_med = "#665c54",
	highlight_high = "#7c6f64",
	none = "NONE",
}

return {
	colors = colors,
	spec = {
		"ellisonleao/gruvbox.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent_mode = true,
			overrides = {
				NormalFloat = { fg = colors.text, bg = colors.surface },
				FloatBorder = { fg = colors.iris, bg = colors.surface },
				FloatTitle = { fg = colors.iris, bg = colors.surface, bold = true },

				SnacksPickerListCursorLine = { fg = colors.text, bg = colors.highlight_high, bold = true },
				FFFCursorLine = { fg = colors.text, bg = colors.highlight_high, bold = true },
				FFFSelectedActive = { fg = colors.foam, bg = colors.highlight_high, bold = true },

				NeoTreeNormal = { fg = colors.text, bg = colors.none },
				NeoTreeNormalNC = { fg = colors.subtle, bg = colors.none },
				NeoTreeEndOfBuffer = { fg = colors.none, bg = colors.none },
				NeoTreeFloatBorder = { fg = colors.muted, bg = colors.none },
				NeoTreeFloatTitle = { fg = colors.base, bg = colors.foam, bold = true },
				NeoTreeTitleBar = { fg = colors.base, bg = colors.iris, bold = true },
				NeoTreeDirectoryName = { fg = colors.foam },
				NeoTreeDirectoryIcon = { fg = colors.foam },
				NeoTreeRootName = { fg = colors.iris, bold = true },
				NeoTreeGitAdded = { fg = colors.foam },
				NeoTreeGitModified = { fg = colors.gold },
				NeoTreeGitDeleted = { fg = colors.love },
				NeoTreeGitUntracked = { fg = colors.iris },
				NeoTreeIndentMarker = { fg = colors.highlight_med },
				NeoTreeExpander = { fg = colors.muted },
				NeoTreeCursorLine = { bg = colors.overlay },

				SnacksIndent = { fg = colors.highlight_med },
				SnacksIndentScope = { fg = colors.love },
				SnacksIndentChunk = { fg = colors.foam },

				OilFile = { fg = colors.text },
				OilLink = { fg = colors.iris },
				OilOrphanLink = { fg = colors.love },
				OilLinkTarget = { fg = colors.muted },
				OilSocket = { fg = colors.pine },
			},
		},
		config = function(_, opts)
			require("gruvbox").setup(opts)
			vim.cmd.colorscheme("gruvbox")
		end,
	},
}
