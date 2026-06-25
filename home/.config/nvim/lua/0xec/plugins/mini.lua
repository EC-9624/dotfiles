return {
	{
		"echasnovski/mini.surround",
		version = false,
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},
	{
		"echasnovski/mini.trailspace",
		version = false,
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			only_in_normal_buffers = true,
		},
		keys = {
			{
				"<leader>cw",
				function()
					require("mini.trailspace").trim()
				end,
				desc = "Trim trailing whitespace",
			},
		},
	},
	{
		"echasnovski/mini.splitjoin",
		version = false,
		opts = {
			mappings = {
				toggle = "",
			},
		},
		keys = {
			{
				"sj",
				function()
					require("mini.splitjoin").join()
				end,
				mode = { "n", "x" },
				desc = "Join split expression",
			},
			{
				"sk",
				function()
					require("mini.splitjoin").split()
				end,
				mode = { "n", "x" },
				desc = "Split joined expression",
			},
		},
	},
}
