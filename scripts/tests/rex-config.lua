-- Run from the repository root: luajit scripts/tests/rex-config.lua
package.path = "home/.config/rex/?.lua;" .. package.path

local actions, bindings = {}, {}
local action_count, binding_count = 0, 0
rex = {
	action = function(definition)
		assert(not actions[definition.name], "duplicate action: " .. definition.name)
		actions[definition.name] = definition
		action_count = action_count + 1
	end,
	bind = function(key, action, args)
		assert(type(action) == "string", "missing action for " .. key)
		assert(action:find(".", 1, true) or actions[action], "action must be registered before binding: " .. action)
		assert(not bindings[key], "duplicate binding: " .. key)
		bindings[key] = { action = action, args = args }
		binding_count = binding_count + 1
	end,
}

assert(loadfile("home/.config/rex/init.lua"))()
assert(action_count == 9, "expected navigation, popup, and floating actions")
assert(binding_count == 37, "expected all existing shortcuts")
for _, name in ipairs({ "navigation", "popups", "floating", "keys" }) do
	assert(package.loaded[name] == true, name .. " should initialize itself without returning a factory")
end
assert(loadfile("home/.config/rex/init.lua"))() -- require must not register anything twice.
assert(action_count == 9 and binding_count == 37)
assert(bindings["ctrl+space>f"].action == "toggle_centered_float")
assert(bindings["ctrl+space>t"].action == "popup_shell")
assert(bindings["ctrl+space>g"].action == "popup_lazygit")
assert(bindings["ctrl+space>y"].action == "popup_yazi")
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	assert(bindings["ctrl+" .. key].action == "navigate_" .. direction)
	assert(bindings["ctrl+space>" .. key].args.direction == direction)
	assert(bindings["ctrl+space>shift+" .. key].args.amount == 5)
end
for i = 1, 9 do
	assert(bindings["ctrl+space>" .. i].args.index == i)
end
for _, binding in pairs(bindings) do
	assert(binding.action:find(".", 1, true) or actions[binding.action], "unregistered action: " .. binding.action)
end

print("Passed Rex config wiring test: self-initializing modules, 9 actions, 37 shortcuts")
