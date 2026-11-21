local uv = vim.uv
local link = vim.fn.expand("~/.config/current-theme")
local syntax = require("0xec.theme.syntax")

local function selected_dir()
	local dir, err = uv.fs_realpath(link)
	return assert(dir, err)
end

local function load_theme(dir)
	local path = dir .. "/neovim.lua"
	local theme = assert(loadfile(path))()
	if
		type(theme) ~= "table"
		or type(theme.colors) ~= "table"
		or type(theme.spec) ~= "table"
		or type(theme.spec.opts) ~= "table"
		or type(theme.spec.config) ~= "function"
	then
		error(("invalid theme definition: %s"):format(path))
	end
	syntax.setup(dir .. "/opencode.json")
	return theme
end

local applied_dir = selected_dir()
local M = load_theme(applied_dir)

local function reload(force, retry)
	local ok, err = pcall(function()
		local dir = force and selected_dir() or uv.fs_realpath(link)
		if not dir then
			-- macOS can briefly reject a lookup racing even with an atomic rename.
			if retry then
				vim.defer_fn(function()
					reload(false)
				end, 10)
			end
			return
		end
		if not force and dir == applied_dir then
			return
		end
		local theme = load_theme(dir)
		theme.spec.config(nil, theme.spec.opts)
		M.colors, M.spec = theme.colors, theme.spec
		applied_dir = dir
		vim.api.nvim_exec_autocmds("User", { pattern = "DotThemeChanged", modeline = false })
	end)
	if not ok then
		vim.notify("Could not reload dotfiles theme: " .. tostring(err), vim.log.levels.WARN)
	end
end

function M.watch()
	vim.api.nvim_create_user_command("DotThemeReload", function()
		reload(true)
	end, { desc = "Reapply the selected dotfiles theme" })

	-- Watch the parent: the selection is a symlink that gets replaced.
	local watcher = assert(uv.new_fs_event())
	local pending = false
	local ok, err = watcher:start(vim.fs.dirname(link), {}, function(watch_err)
		-- macOS can coalesce directory changes and report a different filename.
		if watch_err or pending then
			return
		end
		pending = true
		vim.schedule(function()
			pending = false
			reload(false, true)
		end)
	end)
	if ok then
		vim.api.nvim_create_autocmd("VimLeavePre", {
			once = true,
			callback = function()
				watcher:close()
			end,
		})
	else
		watcher:close()
		vim.notify("Could not watch dotfiles theme: " .. tostring(err), vim.log.levels.WARN)
	end
	reload(false)
end

return M
