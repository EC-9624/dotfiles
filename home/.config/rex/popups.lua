local terminal = "com.superlogical.terminal"

local function current_window(ctx)
	local view = assert(rex.session.view({ session_id = ctx.session_id }))
	for _, window in ipairs(view.windows or {}) do
		for _, layer in ipairs(window.layers or {}) do
			for _, block in ipairs(layer.blocks or {}) do
				if block.block_id == ctx.block_id then
					return window
				end
			end
		end
	end
	error("Popup: no source pane")
end

return function(name, title, command)
	local action = "popup_" .. name
	local label = "popup:" .. name
	rex.action({
		name = action,
		title = title .. " Popup",
		category = "Pane",
		run = function(ctx)
			local window = current_window(ctx)
			-- Discover existing popups so reloads don't lose the scratch shell.
			for _, layer in ipairs(window.layers or {}) do
				if layer.kind == "floating" then
					for _, block in ipairs(layer.blocks or {}) do
						if block.label == label then
							if not command and block.block_id == ctx.block_id then
								rex.client.queue("pane.minimize_floating")
							else
								assert(
									rex.session.raise_layer({ session_id = ctx.session_id, layer_id = layer.layer_id })
								)
								assert(
									rex.session.focus_block({ session_id = ctx.session_id, block_id = block.block_id })
								)
							end
							return
						end
					end
				end
			end

			local process = assert(rex.block.call(terminal, "process", { block_id = ctx.block_id }))
			local cwd = (process.foreground or {}).cwd or (process.child or {}).cwd
			return assert(rex.session.new_layer({
				session_id = ctx.session_id,
				window_id = window.window_id,
				bounds = { 0.1, 0.1, 0.8, 0.8 },
				focus = true,
				layout = {
					block = {
						flavor = terminal .. ".shell",
						label = label,
						options = { cwd = cwd, command = command },
					},
				},
			}))
		end,
	})
	return action
end
