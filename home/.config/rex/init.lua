-- Keep Rex's native Cmd shortcuts alongside tmux-style prefix sequences.
local prefix = "ctrl+space>"

local function bind(key, action, args)
	rex.bind(prefix .. key, action, args)
end

local function is_nvim(process)
	for _, field in ipairs({ "name", "path", "argv0" }) do
		local name = (process[field] or ""):match("([^/]+)$")
		if name == "nvim" or name == "nvim-wrapped" then
			return true
		end
	end
	return false
end

-- Splits
bind("\\", "pane.split", { direction = "right" })
bind("-", "pane.split", { direction = "down" })

-- Vim-style pane movement and resizing
for key, direction in pairs({
	h = "left",
	j = "down",
	k = "up",
	l = "right",
}) do
	bind(key, "pane.focus", { direction = direction })
	bind("shift+" .. key, "pane.resize", {
		direction = direction,
		amount = 5, -- Percentage of the split, not terminal cells.
	})

	-- Let Neovim handle its own splits before handing off at an editor edge.
	local control_key = "ctrl+" .. key
	local pane_direction = direction
	local action = "navigate_" .. direction
	rex.action({
		name = action,
		title = "Navigate Neovim or Pane " .. direction,
		category = "Pane",
		repeats = true,
		run = function(ctx)
			local process = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
			local pass_through = not process or not process.foreground
			if not pass_through then
				pass_through = is_nvim(process.foreground)
				for _, ancestor in ipairs(process.ancestors or {}) do
					pass_through = pass_through or is_nvim(ancestor)
				end
			end

			if pass_through then
				rex.client.queue("pane.send_key", { key = control_key })
			else
				rex.client.queue("pane.focus", { direction = pane_direction, wrap = false })
			end
		end,
	})
	rex.bind(control_key, action)
end

bind("m", "pane.zoom")
bind("=", "pane.balance")

-- Tabs correspond to tmux windows.
bind("c", "client.tab.new")
bind("n", "client.tab.next")
bind("p", "client.tab.previous")

for i = 1, 9 do
	bind(tostring(i), "client.tab.goto", { index = i })
end

bind("s", "session.switch")
bind("shift+p", "client.palette.toggle")
bind("r", "client.config.reload")

-- Press the prefix twice to send Ctrl+Space through to the terminal.
bind("ctrl+space", "pane.send_key", { key = "ctrl+space" })

-- Ctrl+L navigates now; prefix, Ctrl+L still clears the shell screen.
bind("ctrl+l", "pane.send_key", { key = "ctrl+l" })
