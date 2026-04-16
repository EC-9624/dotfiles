local M = {}

local xo_config_files = {
  "xo.config.js",
  "xo.config.ts",
  "xo.config.cjs",
  "xo.config.mjs",
  "xo.config.cts",
  "xo.config.mts",
}

local oxc_config_files = {
  ".oxlintrc.json",
  ".oxlintrc.jsonc",
  ".oxfmtrc.json",
  ".oxfmtrc.jsonc",
  "oxlint.config.ts",
}

local project_markers = {
  ".git",
  "package.json",
  "pnpm-lock.yaml",
  "package-lock.json",
  "yarn.lock",
  "bun.lock",
  "bun.lockb",
}

local function read_package_json(path)
  local file = io.open(path, "r")

  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end

  return decoded
end

local function package_uses_tool(package_json, name)
  if not package_json then
    return false
  end

  if package_json[name] ~= nil then
    return true
  end

  for _, section in ipairs({ "dependencies", "devDependencies" }) do
    local dependencies = package_json[section]

    if type(dependencies) == "table" and dependencies[name] ~= nil then
      return true
    end
  end

  return false
end

local function search_upwards(start_path, names)
  local found = vim.fs.find(names, {
    path = start_path,
    upward = true,
    limit = 1,
    type = "file",
  })

  return found[1]
end

local function normalize_start_path(path)
  if path == nil or path == "" then
    return vim.fn.getcwd()
  end

  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == "directory" then
    return path
  end

  return vim.fs.dirname(path)
end

function M.project_for_path(path)
  local start_path = normalize_start_path(path)
  local xo_config = search_upwards(start_path, xo_config_files)

  if xo_config then
    return {
      profile = "xo",
      root = vim.fs.dirname(xo_config),
    }
  end

  local oxc_config = search_upwards(start_path, oxc_config_files)

  if oxc_config then
    return {
      profile = "oxc",
      root = vim.fs.dirname(oxc_config),
    }
  end

  local package_json_path = search_upwards(start_path, { "package.json" })
  if package_json_path then
    local package_json = read_package_json(package_json_path)

    if package_uses_tool(package_json, "xo") then
      return {
        profile = "xo",
        root = vim.fs.dirname(package_json_path),
      }
    end

    if package_uses_tool(package_json, "oxlint") or package_uses_tool(package_json, "oxfmt") then
      return {
        profile = "oxc",
        root = vim.fs.dirname(package_json_path),
      }
    end
  end

  return {
    profile = nil,
    root = vim.fs.root(start_path, project_markers) or vim.fn.getcwd(),
  }
end

function M.current_project(bufnr)
  local buffer = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  return M.project_for_path(vim.api.nvim_buf_get_name(buffer))
end

function M.find_local_or_global_binary(root, name)
  local local_binary = vim.fs.joinpath(root, "node_modules", ".bin", name)

  if vim.fn.executable(local_binary) == 1 then
    return local_binary
  end

  local global_binary = vim.fn.exepath(name)
  if global_binary ~= "" then
    return global_binary
  end

  return name
end

return M
