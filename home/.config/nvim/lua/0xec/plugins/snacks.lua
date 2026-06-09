local filtered_messages = { "No information available" }

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		bufdelete = { enabled = true },
		dashboard = {
			enabled = true,
			preset = {
				pick = function(cmd, opts)
					local builtin = require("telescope.builtin")

					if cmd == "files" then
						return require("0xec.util.telescope").find_files(opts)
					elseif cmd == "live_grep" then
						return builtin.live_grep(opts)
					elseif cmd == "oldfiles" then
						return builtin.oldfiles(opts)
					end
				end,
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep')",
					},
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })",
					},
					{ icon = " ", key = "s", desc = "Restore Session", section = "session" },
					{
						icon = "󰒲 ",
						key = "l",
						desc = "Lazy",
						action = ":Lazy",
						enabled = package.loaded.lazy ~= nil,
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
			},
			formats = {
				file = function(item, ctx)
					local fname = vim.fn.fnamemodify(item.file, ":~:.")
					local width = ctx.width or 60

					if #fname > width then
						fname = "…" .. fname:sub(-(width - 1))
					end

					local dir, file = fname:match("^(.*)/(.+)$")
					return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
				end,
			},
			sections = {
				{ section = "header" },
				{ section = "keys", indent = 1, padding = 1 },
				{ section = "recent_files", icon = " ", title = "Recent Files", indent = 3, padding = 2 },
				{ section = "startup" },
			},
		},
		dim = { enabled = true },
		gitbrowse = { enabled = true },
		image = { enabled = true },
		indent = {
			enabled = true,
			char = "┆",
			animate = {
				enabled = false,
			},
			scope = {
				enabled = true,
				char = "┆",
			},
		},
		input = { enabled = true },
		lazygit = { enabled = true },
		notifier = {
			enabled = true,
			timeout = 3000,
			style = "fancy",
		},
		picker = { enabled = true },
		quickfile = { enabled = true },
		rename = { enabled = true },
		scratch = { enabled = true },
		statuscolumn = { enabled = true },
		toggle = { enabled = true },
		words = { enabled = true },
	},
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				local notify = Snacks.notifier.notify

				Snacks.notifier.notify = function(message, level, opts)
					for _, filtered in ipairs(filtered_messages) do
						if message == filtered then
							return nil
						end
					end

					return notify(message, level, opts)
				end
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "OilActionsPost",
			callback = function(event)
				local action = event.data.actions

				if action.type == "move" then
					Snacks.rename.on_rename_file(action.src_url, action.dest_url)
				end
			end,
		})
	end,
}
