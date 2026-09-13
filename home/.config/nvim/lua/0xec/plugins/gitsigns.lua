return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		current_line_blame = false,
		on_attach = function(bufnr)
			local gitsigns = package.loaded.gitsigns

			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, {
					buffer = bufnr,
					silent = true,
					desc = desc,
				})
			end

			map("n", "]h", function()
				gitsigns.nav_hunk("next")
			end, "Next Git hunk")
			map("n", "[h", function()
				gitsigns.nav_hunk("prev")
			end, "Previous Git hunk")

			map("n", "<leader>gs", gitsigns.stage_hunk, "Git stage: current hunk")
			map("n", "<leader>gr", gitsigns.reset_hunk, "Git reset: current hunk")
			map("v", "<leader>gs", function()
				gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Git stage: selected lines")
			map("v", "<leader>gr", function()
				gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Git reset: selected lines")

			map("n", "<leader>gS", gitsigns.stage_buffer, "Git stage: buffer")
			map("n", "<leader>gR", gitsigns.reset_buffer, "Git reset: buffer")
			map("n", "<leader>gu", gitsigns.undo_stage_hunk, "Git: undo hunk staging")
			map("n", "<leader>gp", gitsigns.preview_hunk, "Git preview: current hunk")
			map("n", "<leader>gb", function()
				gitsigns.blame_line({ full = true })
			end, "Git blame: current line")
			map("n", "<leader>gB", gitsigns.toggle_current_line_blame, "Git blame: toggle inline")
			map("n", "<leader>gd", gitsigns.diffthis, "Git diff: current base")
			map("n", "<leader>gD", function()
				gitsigns.diffthis("~")
			end, "Git diff: HEAD~1")
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Git hunk")
		end,
	},
}
