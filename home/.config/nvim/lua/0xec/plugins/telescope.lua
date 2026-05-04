return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local action_layout = require("telescope.actions.layout")

		telescope.setup({
			defaults = {
				layout_strategy = "horizontal",
				layout_config = {
					width = 0.95,
					preview_width = 0.45,
				},
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-u>"] = actions.preview_scrolling_up,
						["<C-d>"] = actions.preview_scrolling_down,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<M-p>"] = action_layout.toggle_preview,
					},
					n = {
						["<M-p>"] = action_layout.toggle_preview,
					},
				},
				file_ignore_patterns = {
					"node_modules",
					"yarn.lock",
					"pnpm.lock",
					".sl",
					"_build",
					".next",
				},
			},
			pickers = {
				buffers = {
					mappings = {
						i = {
							["<C-x>"] = actions.delete_buffer,
						},
					},
				},
				find_files = {
					path_display = { "truncate" },
				},
				live_grep = {
					additional_args = function()
						return { "--hidden", "-g", "!.git" }
					end,
					path_display = { "truncate" },
				},
				oldfiles = {
					path_display = { "truncate" },
				},
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		})

		pcall(telescope.load_extension, "fzf")
	end,
}
