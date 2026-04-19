local M = {}

local XO_CONFIGS = {
	"xo.config.js",
	"xo.config.ts",
	"xo.config.cjs",
	"xo.config.mjs",
	"xo.config.cts",
	"xo.config.mts",
}

local OXC_CONFIGS = {
	".oxlintrc.json",
	".oxlintrc.jsonc",
	"oxlint.config.ts",
}

local PROJECT_MARKERS = {
	".git",
	"package.json",
	"pnpm-lock.yaml",
	"package-lock.json",
	"yarn.lock",
	"bun.lock",
	"bun.lockb",
}

local function find_up(start, names)
	return vim.fs.find(names, { path = start, upward = true, limit = 1, type = "file" })[1]
end

local function start_dir(path)
	if not path or path == "" then
		return vim.fn.getcwd()
	end
	local stat = vim.uv.fs_stat(path)
	return (stat and stat.type == "directory") and path or vim.fs.dirname(path)
end

local function pkg_declares(pkg_path, name)
	local file = io.open(pkg_path, "r")
	if not file then
		return false
	end
	local content = file:read("*a")
	file:close()

	local ok, data = pcall(vim.json.decode, content)
	if not ok or type(data) ~= "table" then
		return false
	end

	if data[name] ~= nil then
		return true
	end
	for _, section in ipairs({ "dependencies", "devDependencies" }) do
		local deps = data[section]
		if type(deps) == "table" and deps[name] ~= nil then
			return true
		end
	end
	return false
end

---@return { profile: "xo"|"oxc"|nil, root: string }
function M.project_for_path(path)
	local start = start_dir(path)

	local cfg = find_up(start, XO_CONFIGS)
	if cfg then
		return { profile = "xo", root = vim.fs.dirname(cfg) }
	end

	cfg = find_up(start, OXC_CONFIGS)
	if cfg then
		return { profile = "oxc", root = vim.fs.dirname(cfg) }
	end

	local pkg = find_up(start, { "package.json" })
	if pkg then
		if pkg_declares(pkg, "xo") then
			return { profile = "xo", root = vim.fs.dirname(pkg) }
		end
		if pkg_declares(pkg, "oxlint") then
			return { profile = "oxc", root = vim.fs.dirname(pkg) }
		end
	end

	return {
		profile = nil,
		root = vim.fs.root(start, PROJECT_MARKERS) or vim.fn.getcwd(),
	}
end

function M.current_project(bufnr)
	bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
	return M.project_for_path(vim.api.nvim_buf_get_name(bufnr))
end

--- Resolve a JS tool binary. Walks upward from `root` through each ancestor's
--- node_modules/.bin/ (handles pnpm/yarn/npm workspace hoisting), then $PATH,
--- then the bare name.
function M.find_local_or_global_binary(root, name)
	local current = root
	while current and current ~= "" do
		local candidate = vim.fs.joinpath(current, "node_modules", ".bin", name)
		local stat = vim.uv.fs_stat(candidate)
		if stat and stat.type == "file" then
			return candidate
		end
		local parent = vim.fs.dirname(current)
		if parent == current then
			break
		end
		current = parent
	end

	local on_path = vim.fn.exepath(name)
	return on_path ~= "" and on_path or name
end

return M
