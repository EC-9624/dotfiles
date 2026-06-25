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
			end, "Next git hunk")
			map("n", "[h", function()
				gitsigns.nav_hunk("prev")
			end, "Previous git hunk")

			map("n", "<leader>gs", gitsigns.stage_hunk, "Stage git hunk")
			map("n", "<leader>gr", gitsigns.reset_hunk, "Reset git hunk")
			map("v", "<leader>gs", function()
				gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Stage selected git hunk")
			map("v", "<leader>gr", function()
				gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Reset selected git hunk")

			map("n", "<leader>gS", gitsigns.stage_buffer, "Stage git buffer")
			map("n", "<leader>gR", gitsigns.reset_buffer, "Reset git buffer")
			map("n", "<leader>gu", gitsigns.undo_stage_hunk, "Undo stage git hunk")
			map("n", "<leader>gp", gitsigns.preview_hunk, "Preview git hunk")
			map("n", "<leader>gb", function()
				gitsigns.blame_line({ full = true })
			end, "Git blame line")
			map("n", "<leader>gB", gitsigns.toggle_current_line_blame, "Toggle git line blame")
			map("n", "<leader>gd", gitsigns.diffthis, "Git diff this")
			map("n", "<leader>gD", function()
				gitsigns.diffthis("~")
			end, "Git diff this against index")
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select git hunk")
		end,
	},
}
