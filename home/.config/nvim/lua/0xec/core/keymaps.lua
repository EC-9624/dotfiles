local map = vim.keymap.set
local default_opts = { noremap = true, silent = true }

local function opts(desc, extra)
	return vim.tbl_extend("force", default_opts, { desc = desc }, extra or {})
end

-- Movement and search
map("n", "k", "v:count == 0 ? 'gk' : 'k'", opts("Move up display line; counted: actual lines", { expr = true }))
map("n", "j", "v:count == 0 ? 'gj' : 'j'", opts("Move down display line; counted: actual lines", { expr = true }))
map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts("Clear search highlighting"))
map("n", "<C-d>", "<C-d>zz", opts("Scroll half-page down and center"))
map("n", "<C-u>", "<C-u>zz", opts("Scroll half-page up and center"))
map("n", "n", "nzzzv", opts("Next search result: center and reveal"))
map("n", "N", "Nzzzv", opts("Previous search result: center and reveal"))
map("n", "J", "mzJ`z", opts("Join lines and keep cursor"))
map("v", "J", ":m '>+1<CR>gv=gv", opts("Move selected lines down"))
map("v", "K", ":m '<-2<CR>gv=gv", opts("Move selected lines up"))
map("v", "<", "<gv", opts("Indent left and keep selection"))
map("v", ">", ">gv", opts("Indent right and keep selection"))

-- File and editing
map("n", "<C-s>", "<cmd>write<CR>", opts("Save file"))
map("n", "<leader>sn", "<cmd>noautocmd write<CR>", opts("Save: no autocommands"))
map("n", "<C-q>", "<cmd>quit<CR>", opts("Quit current window"))
map("n", "U", "<C-r>", opts("Redo"))
map("n", "H", "^", opts("First nonblank character"))
map("n", "L", "$", opts("End of line"))
map("n", "x", '"_x', opts("Delete character without changing registers"))

-- Window resizing
map("n", "<Up>", "<cmd>resize -2<CR>", opts("Decrease window height"))
map("n", "<Down>", "<cmd>resize +2<CR>", opts("Increase window height"))
map("n", "<Left>", "<cmd>vertical resize -2<CR>", opts("Decrease window width"))
map("n", "<Right>", "<cmd>vertical resize +2<CR>", opts("Increase window width"))

-- Buffers
map("n", "]b", "<cmd>bnext<CR>", opts("Next buffer"))
map("n", "[b", "<cmd>bprevious<CR>", opts("Previous buffer"))
map("n", "<leader>sb", "<cmd>buffers<CR>:buffer ", opts("Select buffer by name or number", { silent = false }))
map("n", "<leader>bd", function()
	Snacks.bufdelete()
end, opts("Buffer: delete"))
map("n", "<leader>bn", "<cmd>enew<CR>", opts("Buffer: new"))

-- Numbers and wrapping
map("n", "<leader>+", "<C-a>", opts("Increment number"))
map("n", "<leader>_", "<C-x>", opts("Decrement number"))
map("n", "<leader>lw", "<cmd>set wrap!<CR>", opts("Line wrap: toggle"))
map("n", "<leader>ln", function()
	Snacks.toggle.option("relativenumber", { name = "Relative Number" }):toggle()
end, opts("Line numbers: toggle relative"))
map("n", "<leader>ld", function()
	Snacks.toggle.diagnostics():toggle()
end, opts("Diagnostics: toggle display"))
map("n", "<leader>cl", function()
	Snacks.toggle.option("cursorline", { name = "Cursor Line" }):toggle()
end, opts("Cursor line: toggle"))
map("n", "<leader>zm", function()
	Snacks.toggle.dim():toggle()
end, opts("Dim mode: toggle"))
map("n", "<leader>tc", function()
	local tsc = require("treesitter-context")

	Snacks.toggle({
		name = "Treesitter Context",
		get = tsc.enabled,
		set = function(state)
			if state then
				tsc.enable()
			else
				tsc.disable()
			end
		end,
	}):toggle()
end, opts("Treesitter context: toggle"))
map("n", "<leader>ih", function()
	Snacks.toggle({
		name = "Inlay Hints",
		get = function()
			return vim.lsp.inlay_hint.is_enabled()
		end,
		set = function(state)
			vim.lsp.inlay_hint.enable(state)
		end,
	}):toggle()
end, opts("Inlay hints: toggle"))

-- Windows
map("n", "<leader>v", "<C-w>v", opts("Split window vertically"))
map("n", "<leader>h", "<C-w>s", opts("Split window horizontally"))
map("n", "<leader>se", "<C-w>=", opts("Splits: equalize sizes"))
map("n", "<leader>xs", "<cmd>close<CR>", opts("Close current split"))
map("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", opts("Focus upper window or tmux pane"))
map("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", opts("Focus lower window or tmux pane"))
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", opts("Focus left window or tmux pane"))
map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", opts("Focus right window or tmux pane"))

-- Tabs
map("n", "<leader>to", "<cmd>tabnew<CR>", opts("Tab: open"))
map("n", "<leader>tx", "<cmd>tabclose<CR>", opts("Tab: close"))
map("n", "<leader>tn", "<cmd>tabnext<CR>", opts("Tab: next"))
map("n", "<leader>tp", "<cmd>tabprevious<CR>", opts("Tab: previous"))

-- Git
map("n", "<leader>gg", function()
	Snacks.lazygit()
end, opts("Git: open Lazygit"))

-- Clipboard and explorer
map("v", "p", '"_dP', opts("Paste without replacing source register"))
map({ "n", "v" }, "<leader>y", '"+y', opts("Yank to system clipboard"))
map("n", "<leader>Y", '"+Y', opts("Yank line to system clipboard"))
map("n", "<leader>fp", function()
	local file_path = vim.fn.expand("%:~:.")

	if file_path == "" then
		vim.notify("No file path for current buffer", vim.log.levels.WARN)
		return
	end

	vim.fn.setreg("+", file_path)
	vim.notify("Copied file path: " .. file_path)
end, opts("File path: copy"))
map({ "n", "v" }, "<leader>og", function()
	Snacks.gitbrowse()
end, opts("Open Git in browser"))
map("n", "<leader>nh", function()
	Snacks.notifier.show_history()
end, opts("Notifications: history"))
map("n", "<leader>nd", function()
	Snacks.notifier.hide()
end, opts("Notifications: dismiss"))
map("n", "<leader>.", function()
	Snacks.scratch()
end, opts("Scratch buffer: toggle"))
map("n", "<leader>s.", function()
	Snacks.scratch.select()
end, opts("Select scratch buffer"))
map("n", "<leader>e", function()
	require("neo-tree.command").execute({
		source = "filesystem",
		position = "right",
		reveal = true,
		toggle = true,
	})
end, opts("Explorer: toggle and reveal file on open"))
map("n", "-", "<cmd>Oil<CR>", opts("Open parent directory"))
map("n", "<leader>-", function()
	require("oil").toggle_float()
end, opts("Oil: toggle floating explorer"))

-- Find
map("n", "<leader>ff", function()
	require("fff").find_files()
end, opts("Find files"))
map("n", "<leader>fg", function()
	require("fff").live_grep()
end, opts("Find text (live grep)"))
map("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, opts("Find buffers"))
map("n", "<leader>fh", function()
	Snacks.picker.help()
end, opts("Find help"))
