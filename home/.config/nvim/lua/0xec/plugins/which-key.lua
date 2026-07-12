return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern",
		triggers = {
			{ "<auto>", mode = "nxso" },
			{ "<leader>", mode = { "n", "v" } },
		},
		spec = {
			{ "<leader>c", group = "Code" },
			{ "<leader>f", group = "Find" },
			{ "<leader>g", group = "Git" },
			{ "<leader>l", group = "Toggles" },
			{ "<leader>n", group = "Notifications" },
			{ "<leader>s", group = "Search/Save" },
			{ "<leader>t", group = "Tabs/Context" },
			{ "<leader>x", group = "Diagnostics/Close" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ keys = "<leader>" })
			end,
			desc = "Show leader keymaps",
		},
	},
}
