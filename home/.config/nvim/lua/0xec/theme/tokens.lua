local M = {}

-- OpenCode V2 references can alias whole hue scales as well as individual colors.
function M.load(path, mode)
	local file, open_error = io.open(path, "r")
	if not file then
		error(("cannot read theme tokens from %s: %s"):format(path, open_error))
	end
	local content = file:read("*a")
	file:close()
	local ok, theme = pcall(vim.json.decode, content)
	if not ok or type(theme) ~= "table" or type(theme.base) ~= "table" or type(theme[mode]) ~= "table" then
		error(("invalid OpenCode V2 theme in %s: expected base and %s objects"):format(path, mode))
	end

	local root = vim.tbl_deep_extend("force", {}, theme.base, theme[mode])
	local visiting = {}
	local resolve
	local function lookup(key)
		if visiting[key] then
			error(("circular theme reference $%s in %s"):format(key, path))
		end
		visiting[key] = true
		local value = root
		for part in key:gmatch("[^.]+") do
			value = resolve(value)
			if type(value) ~= "table" or value[part] == nil then
				error(("missing theme token $%s in %s"):format(key, path))
			end
			value = value[part]
		end
		value = resolve(value)
		visiting[key] = nil
		return value
	end
	resolve = function(value)
		if type(value) == "string" and value:sub(1, 1) == "$" then
			return lookup(value:sub(2))
		end
		return value
	end

	return function(key)
		local color = lookup(key)
		if type(color) ~= "string" or not color:match("^#%x%x%x%x%x%x$") then
			error(("theme token %s in %s must resolve to an opaque #RRGGBB color"):format(key, path))
		end
		return color
	end
end

return M
