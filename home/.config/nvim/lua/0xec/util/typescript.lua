local M = {}

--- Resolved native language servers, keyed by project root.
--- `false` means resolution failed; cached so a broken project does not spawn repeatedly.
local server_cache = {} ---@type table<string, { name: string, exe: string }|false>

local function is_effect_root(dir)
	return vim.uv.fs_stat(vim.fs.joinpath(dir, "node_modules", "@effect", "tsgo")) ~= nil
end

---@param start string
---@return string|nil
local function find_root(start)
	local current = start

	while current and current ~= "" do
		-- Stop here rather than selecting a native server from an ancestor workspace.
		if vim.uv.fs_stat(vim.fs.joinpath(current, ".ts_ls")) ~= nil then
			return nil
		end

		if is_effect_root(current) or vim.uv.fs_stat(vim.fs.joinpath(current, "node_modules", "typescript")) ~= nil then
			return current
		end

		local parent = vim.fs.dirname(current)
		if parent == current then
			break
		end

		current = parent
	end
end

---@param root string
---@return string|nil
local function resolve_effect(root)
	local bin = vim.fs.joinpath(root, "node_modules", ".bin", "effect-tsgo")
	if vim.fn.executable(bin) ~= 1 then
		vim.notify_once(
			("effect-tsgo: %s installs @effect/tsgo but node_modules/.bin/effect-tsgo is missing; re-run your package manager install."):format(
				root
			),
			vim.log.levels.WARN
		)
		return nil
	end

	-- The binary path is version- and platform-specific, so ask the package instead of guessing it.
	local ok, result = pcall(function()
		return vim.system({ bin, "get-exe-path" }, { cwd = root, text = true }):wait(5000)
	end)

	if not ok or result.code ~= 0 then
		local detail = ok and vim.trim((result.stderr ~= "" and result.stderr or result.stdout) or "")
			or tostring(result)
		vim.notify_once(
			("effect-tsgo: could not resolve a language server binary for %s (%s). Install TypeScript 7+ (`typescript` >= 7 or `@typescript/native-preview`), then restart Neovim."):format(
				root,
				detail
			),
			vim.log.levels.WARN
		)
		return nil
	end

	local exe = vim.trim(result.stdout or "")
	if exe == "" or vim.uv.fs_stat(exe) == nil then
		vim.notify_once(("effect-tsgo: `get-exe-path` returned no binary for %s."):format(root), vim.log.levels.WARN)
		return nil
	end

	return exe
end

local function resolve_native(root)
	local bin = vim.fs.joinpath(root, "node_modules", ".bin", "tsc")
	if vim.fn.executable(bin) ~= 1 then
		return nil
	end

	local ok, result = pcall(function()
		return vim.system({ bin, "--version" }, { cwd = root, text = true }):wait(5000)
	end)

	if not ok or result.code ~= 0 then
		vim.notify_once(
			("tsc: could not check the workspace TypeScript version in %s; using ts_ls."):format(root),
			vim.log.levels.WARN
		)
		return nil
	end

	local version = vim.version.parse(result.stdout or "")
	if version and version.major >= 7 then
		return bin
	end
end

--- All TypeScript LSP gates share this selection to prevent duplicate clients.
---@param bufnr integer
---@return string|nil root, string|nil exe, string|nil server
function M.resolve(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local root = find_root(name ~= "" and vim.fs.dirname(name) or vim.uv.cwd())
	if not root then
		return nil, nil, nil
	end

	local cached = server_cache[root]
	if cached == nil then
		local effect = is_effect_root(root)
		local exe
		if effect then
			exe = resolve_effect(root)
		else
			exe = resolve_native(root)
		end
		cached = exe and { name = effect and "effect_tsgo" or "tsc", exe = exe } or false
		server_cache[root] = cached
	end

	if not cached then
		return nil, nil, nil
	end

	return root, cached.exe, cached.name
end

--- Binary resolved by M.resolve() for a root it already accepted.
---@param root string|nil
---@return string
function M.exe(root)
	local cached = root and server_cache[root]
	if cached then
		return cached.exe
	end

	-- root_dir only attaches after M.resolve() succeeds, so reaching this is a logic error.
	error(("TypeScript LSP: no resolved binary for %q"):format(root or "<nil>"))
end

return M
