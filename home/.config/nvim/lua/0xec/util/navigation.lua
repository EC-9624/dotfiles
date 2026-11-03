local M = {}

local directions = { h = "left", j = "down", k = "up", l = "right" }

function M.move(key)
	local direction = assert(directions[key], "Unknown navigation key: " .. tostring(key))
	local window = vim.api.nvim_get_current_win()
	vim.cmd("wincmd " .. key)
	if vim.api.nvim_get_current_win() ~= window then
		return
	end

	local session = vim.env.REX_SESSION
	if not session or session == "" then
		return
	end
	if vim.fn.executable("rex") ~= 1 then
		vim.notify("Rex navigation: rex is not on PATH", vim.log.levels.WARN)
		return
	end

	-- No RPC listener: the local Rex CLI moves focus only at an editor edge.
	vim.system({ "rex", "--autostart=false", "--timeout=2s", "focus", "-s", session, direction, "--wrap" }, {
		text = true,
		timeout = 2500,
	}, function(result)
		if result.code ~= 0 then
			vim.schedule(function()
				vim.notify("Rex navigation failed: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
			end)
		end
	end)
end

return M
