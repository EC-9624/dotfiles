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
			{ "<leader>b", group = "Buffers" },
			{ "<leader>c", group = "Code / Cursor" },
			{ "<leader>f", group = "Find / File path" },
			{ "<leader>g", group = "Git" },
			{ "<leader>l", group = "Display toggles" },
			{ "<leader>n", group = "Notifications" },
			{ "<leader>s", group = "Save / Select / Splits" },
			{ "<leader>t", group = "Tabs / Treesitter" },
			{ "<leader>x", group = "Diagnostics / Close" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ keys = "<leader>" })
			end,
			desc = "Show leader keybindings",
		},
	},
}
