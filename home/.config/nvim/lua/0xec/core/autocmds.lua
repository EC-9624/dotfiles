local git_message_files = {
	COMMIT_EDITMSG = true,
	MERGE_MSG = true,
	TAG_EDITMSG = true,
	SQUASH_MSG = true,
	REBASE_EDITMSG = true,
}

local function is_git_message_file(path)
	local normalized = path:gsub("\\", "/")
	local name = normalized:match("([^/]+)$")
	local in_git_dir = normalized:sub(1, 5) == ".git/" or normalized:find("/.git/", 1, true) ~= nil

	return name ~= nil and git_message_files[name] == true and in_git_dir
end

local function filter_git_message_oldfiles()
	vim.v.oldfiles = vim.tbl_filter(function(file)
		return not is_git_message_file(file)
	end, vim.v.oldfiles)
end

local function exclude_from_shada(path)
	local absolute = vim.fn.fnamemodify(path, ":p")
	local resolved = vim.fn.resolve(absolute)

	vim.opt.shada:append("r" .. absolute)

	if resolved ~= "" and resolved ~= absolute then
		vim.opt.shada:append("r" .. resolved)
	end
end

local git_message_oldfiles_group = vim.api.nvim_create_augroup("0xec-git-message-oldfiles", { clear = true })

vim.api.nvim_create_autocmd({ "VimEnter", "VimLeavePre" }, {
	group = git_message_oldfiles_group,
	callback = filter_git_message_oldfiles,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	group = git_message_oldfiles_group,
	callback = function(event)
		if is_git_message_file(event.file) then
			exclude_from_shada(event.file)
			vim.schedule(filter_git_message_oldfiles)
		end
	end,
})
