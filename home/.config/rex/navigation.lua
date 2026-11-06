local function is_nvim(process)
	for _, field in ipairs({ "name", "path", "argv0" }) do
		local name = (process[field] or ""):match("([^/]+)$")
		if name == "nvim" or name == "nvim-wrapped" then
			return true
		end
	end
	return false
end

local function should_forward(process)
	-- If detection fails, leave the key with the terminal program.
	if not process or not process.foreground or is_nvim(process.foreground) then
		return true
	end
	for _, ancestor in ipairs(process.ancestors or {}) do
		if is_nvim(ancestor) then
			return true
		end
	end
	return false
end

-- Let Neovim handle its own splits before handing off at an editor edge.
return function(key, direction)
	local action = "navigate_" .. direction
	rex.action({
		name = action,
		title = "Navigate Neovim or Pane " .. direction,
		category = "Pane",
		repeats = true,
		run = function(ctx)
			local process = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
			if should_forward(process) then
				-- The client send-key action is unavailable in floating popups.
				assert(rex.block.call("com.superlogical.terminal", "write", {
					block_id = ctx.block_id,
					data = string.char(string.byte(key) - string.byte("a") + 1),
				}))
				return
			end
			rex.client.queue("pane.focus", { direction = direction, wrap = true })
		end,
	})
	return action
end
