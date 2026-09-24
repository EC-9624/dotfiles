local M = {}

--- Resolved language server binaries, keyed by project root.
--- `false` means resolution failed; cached so a broken project does not spawn repeatedly.
local exe_cache = {} ---@type table<string, string|false>

local function is_effect_root(dir)
	return vim.uv.fs_stat(vim.fs.joinpath(dir, "node_modules", "@effect", "tsgo")) ~= nil
end

--- Explicit per-project opt-out: keeps ts_ls (e.g. for cross-file CSS Modules navigation).
local function forces_ts_ls(dir)
	return vim.uv.fs_stat(vim.fs.joinpath(dir, ".ts_ls")) ~= nil
end

---@param start string
---@return string|nil
local function find_effect_root(start)
	local current = start

	while current and current ~= "" do
		if is_effect_root(current) and not forces_ts_ls(current) then
			return current
		end

		local parent = vim.fs.dirname(current)
		if parent == current then
			break
		end

		current = parent
	end
end

--- Project root of the nearest ancestor installing @effect/tsgo, or nil.
---@param bufnr integer
---@return string|nil
function M.root(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
	return find_effect_root(start)
end

---@param root string
---@return string|nil
local function resolve_exe(root)
	local bin = vim.fs.joinpath(root, "node_modules", ".bin", "effect-tsgo")
	if vim.fn.executable(bin) ~= 1 then
		vim.notify_once(
			("effect-tsgo: %s installs @effect/tsgo but node_modules/.bin/effect-tsgo is missing; re-run your package manager install."):format(root),
			vim.log.levels.WARN
		)
		return nil
	end

	-- The binary path is version- and platform-specific, so ask the package instead of guessing it.
	local ok, result = pcall(function()
		return vim.system({ bin, "get-exe-path" }, { cwd = root, text = true }):wait(5000)
	end)

	if not ok or result.code ~= 0 then
		local detail = ok and vim.trim((result.stderr ~= "" and result.stderr or result.stdout) or "") or tostring(result)
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

--- Detect the effect-tsgo setup for `bufnr`, resolving and caching its binary.
--- Both the `effect_tsgo` and `ts_ls` gates go through here so they can never disagree.
---@param bufnr integer
---@return string|nil root, string|nil exe
function M.resolve(bufnr)
	local root = M.root(bufnr)
	if not root then
		return nil, nil
	end

	local cached = exe_cache[root]
	if cached == nil then
		cached = resolve_exe(root) or false
		exe_cache[root] = cached
	end

	return root, cached or nil
end

--- Binary resolved by M.resolve() for a root it already accepted.
---@param root string|nil
---@return string
function M.exe(root)
	local cached = root and exe_cache[root]
	if type(cached) == "string" then
		return cached
	end

	-- root_dir only attaches after M.resolve() succeeds, so reaching this is a logic error.
	error(("effect_tsgo: no resolved binary for %q"):format(root or "<nil>"))
end

return M
