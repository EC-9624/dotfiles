local M = {}

local find_files

find_files = function(opts, show_hidden)
	opts = opts or {}
	show_hidden = vim.F.if_nil(show_hidden, true)
	opts.path_display = { "truncate" }
	opts.attach_mappings = function(_, map)
		map({ "n", "i" }, "<C-h>", function(prompt_bufnr)
			local prompt = require("telescope.actions.state").get_current_line()
			require("telescope.actions").close(prompt_bufnr)
			local next_opts = vim.tbl_extend("force", {}, opts, { default_text = prompt })

			find_files(next_opts, not show_hidden)
		end)

		return true
	end

	if show_hidden then
		opts.hidden = true
		opts.prompt_title = "Find Files <HIDDEN>"
	else
		opts.hidden = false
		opts.prompt_title = "Find Files"
	end

	require("telescope.builtin").find_files(opts)
end

M.find_files = find_files

return M
