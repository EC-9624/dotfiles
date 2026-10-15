-- Run with: nvim --headless -u NONE -l tests/typescript-lsp.lua
local root = vim.fn.fnamemodify(arg[0], ":p:h:h")
vim.opt.runtimepath:prepend(root .. "/home/.config/nvim")
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/nvim-lspconfig")
require("0xec.plugins.lsp.lspconfig")[1].config()

local typescript = require("0xec.util.typescript")
local scratch_path = vim.fn.tempname()
vim.fn.mkdir(scratch_path, "p")
local scratch = assert(vim.uv.fs_realpath(scratch_path))

local function write(path, lines)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile(lines, path)
end

local function executable(path, lines)
	write(path, vim.list_extend({ "#!/bin/sh" }, lines))
	assert(vim.fn.setfperm(path, "rwx------") == 1)
	return path
end

local function project(name, version)
	local path = scratch .. "/" .. name
	write(path .. "/bun.lock", {})
	write(path .. "/node_modules/typescript/package.json", { vim.json.encode({ version = version }) })
	executable(path .. "/node_modules/.bin/tsc", {
		'[ "$1" = "--version" ] || exit 1',
		'echo "Version ' .. version .. '"',
	})
	return path
end

local function selected(path, expected, expected_root)
	write(path .. "/src/index.ts", {})
	local buf = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_buf_set_name(buf, path .. "/src/index.ts")
	local accepted = {}
	for _, name in ipairs({ "ts_ls", "tsc", "effect_tsgo" }) do
		vim.lsp.config[name].root_dir(buf, function(dir)
			assert(dir == expected_root, name .. ": unexpected root " .. tostring(dir))
			table.insert(accepted, name)
		end)
	end
	assert(vim.deep_equal(accepted, { expected }), path .. ": selected " .. vim.inspect(accepted))
	local dir, exe, server = typescript.resolve(buf)
	if expected ~= "ts_ls" then
		assert(server == expected and dir == expected_root)
		assert(exe == typescript.exe(dir), "command must use the selected workspace binary")
	end
	vim.api.nvim_buf_delete(buf, { force = true })
	return exe
end

local function test()
	local native = project("native", "7.0.2")
	assert(selected(native, "tsc", native) == native .. "/node_modules/.bin/tsc")
	selected(native .. "/packages/app", "tsc", native)

	local legacy = project("legacy", "6.0.3")
	selected(legacy, "ts_ls", legacy)

	local effect = project("effect", "7.0.2")
	write(effect .. "/node_modules/@effect/tsgo/package.json", { "{}" })
	local effect_bin = executable(effect .. "/native-effect", { "exit 0" })
	executable(effect .. "/node_modules/.bin/effect-tsgo", {
		'[ "$1" = "get-exe-path" ] || exit 1',
		"printf '%s\\n' " .. vim.fn.shellescape(effect_bin),
	})
	assert(selected(effect, "effect_tsgo", effect) == effect_bin)

	-- Overrides must win even after the native selection has been cached.
	write(native .. "/.ts_ls", {})
	selected(native, "ts_ls", native)
	write(effect .. "/.ts_ls", {})
	selected(effect, "ts_ls", effect)

	local workspace = project("workspace", "7.0.2")
	local child = project("workspace/packages/legacy", "6.0.3")
	selected(child, "ts_ls", child)
	local override = workspace .. "/packages/override"
	write(override .. "/.ts_ls", {})
	selected(override, "ts_ls", workspace)

	local missing = scratch .. "/missing"
	write(missing .. "/bun.lock", {})
	selected(missing, "ts_ls", missing)

	local mason = require("0xec.plugins.lsp.mason")[2].opts
	for _, servers in ipairs({ mason.ensure_installed, mason.automatic_enable }) do
		assert(not vim.tbl_contains(servers, "tsc"), "Mason must not manage native TypeScript")
		assert(not vim.tbl_contains(servers, "effect_tsgo"), "Mason must not manage Effect")
		assert(vim.tbl_contains(servers, "ts_ls"), "Mason must manage the legacy server")
	end
end

local ok, err = xpcall(test, debug.traceback)
vim.fn.delete(scratch, "rf")
if not ok then
	error(err)
end
print("TypeScript LSP selection passed")
