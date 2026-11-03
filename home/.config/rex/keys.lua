local register_navigation = require("navigation")

-- Keep Rex's native Cmd shortcuts alongside tmux-style prefix sequences.
local prefix = "ctrl+space>"

local function bind(key, action, args)
	rex.bind(prefix .. key, action, args)
end

-- Splits
bind("\\", "pane.split", { direction = "right" })
bind("-", "pane.split", { direction = "down" })

-- Vim-style movement and resizing (amounts are percentages).
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	bind(key, "pane.focus", { direction = direction })
	bind("shift+" .. key, "pane.resize", { direction = direction, amount = 5 })
	rex.bind("ctrl+" .. key, register_navigation(key, direction))
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
