-- Run from the repository root: luajit scripts/tests/rex-floating.lua
local module_path = "home/.config/rex/floating.lua"
local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item)
	end
	return result
end

local function leaf(id)
	return { block_id = id }
end

local function split(direction, ratio, before, after)
	return { split = { direction = direction, ratio = ratio, before = before, after = after } }
end

local function horizontal(a, b, ratio)
	return split("horizontal", ratio or 0.5, a, b)
end

local function vertical(a, b, ratio)
	return split("vertical", ratio or 0.5, a, b)
end

local function shape(node)
	if not node then
		return "empty"
	end
	if node.block_id then
		return node.block_id
	end
	local s = node.split
	return string.format("%s:%.3f(%s,%s)", s.direction, s.ratio, shape(s.before), shape(s.after))
end

local function equal(actual, expected)
	assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function harness(layout)
	local files, serialized, actions = {}, {}, {}
	local h = { windows = {}, labels = {}, calls = {}, count = 0, moves = 0, focus = nil }
	local function next_id(prefix)
		h.count = h.count + 1
		return prefix .. h.count
	end
	function h.add_window(id, root)
		local window = { window_id = id, layers = { { layer_id = id .. ":tile", kind = "tiled", layout = root } } }
		h.windows[#h.windows + 1] = window
		return window
	end
	local function find(node, id)
		return node
			and (node.block_id == id or (node.split and (find(node.split.before, id) or find(node.split.after, id))))
	end
	function h.location(id)
		for _, window in ipairs(h.windows) do
			for _, layer in ipairs(window.layers) do
				if find(layer.layout, id) then
					return window, layer
				end
			end
		end
	end
	local function remove(node, id)
		if not node or node.block_id == id then
			return nil
		end
		if node.split then
			node.split.before = remove(node.split.before, id)
			node.split.after = remove(node.split.after, id)
			if not node.split.before then
				return node.split.after
			elseif not node.split.after then
				return node.split.before
			end
		end
		return node
	end
	local function replace(node, id, replacement)
		if node.block_id == id then
			return replacement
		end
		if node.split then
			node.split.before = replace(node.split.before, id, replacement)
			node.split.after = replace(node.split.after, id, replacement)
		end
		return node
	end
	local function cleanup()
		for wi = #h.windows, 1, -1 do
			local window = h.windows[wi]
			for li = #window.layers, 1, -1 do
				local layer = window.layers[li]
				if layer.kind == "floating" and not layer.layout then
					table.remove(window.layers, li)
				end
			end
			if #window.layers == 1 and not window.layers[1].layout then
				table.remove(h.windows, wi)
			end
		end
	end
	function h.close(id)
		local _, layer = assert(h.location(id))
		layer.layout = remove(layer.layout, id)
		cleanup()
	end
	function h.split(id, new_id, direction, ratio)
		local _, layer = h.location(id)
		layer.layout = replace(layer.layout, id, split(direction or "horizontal", ratio or 0.5, leaf(id), leaf(new_id)))
	end
	local function view()
		local windows = copy(h.windows)
		local function blocks(node, result)
			if not node then
				return
			end
			if node.block_id then
				result[#result + 1] = { block_id = node.block_id, label = h.labels[node.block_id] or node.block_id }
			else
				blocks(node.split.before, result)
				blocks(node.split.after, result)
			end
		end
		for _, window in ipairs(windows) do
			for _, layer in ipairs(window.layers) do
				layer.blocks = {}
				blocks(layer.layout, layer.blocks)
			end
		end
		return { windows = windows }
	end
	local rex = { session = {}, json = {} }
	function rex.action(definition)
		actions[definition.name] = definition.run
	end
	function rex.exec()
		return { ok = true }
	end
	function rex.log(_, message)
		h.message = message
	end
	function rex.json.encode(value)
		local token = next_id("json:")
		serialized[token] = copy(value)
		return token
	end
	function rex.json.decode(token)
		return copy(assert(serialized[token]))
	end
	rex.session.view = view
	function rex.session.float_block(args)
		local window, layer = h.location(args.block_id)
		assert(layer.kind == "tiled")
		layer.layout = remove(layer.layout, args.block_id)
		local id = next_id("float:")
		window.layers[#window.layers + 1] = {
			layer_id = id,
			kind = "floating",
			layout = leaf(args.block_id),
			bounds = args.bounds,
		}
		return { layer_id = id }
	end
	function rex.session.move_block(args)
		h.moves = h.moves + 1
		if h.fail_move == h.moves then
			return nil, "injected move failure"
		end
		h.calls[#h.calls + 1] = copy(args)
		local _, source = assert(h.location(args.block_id))
		source.layout = remove(source.layout, args.block_id)
		local _, target = assert(h.location(args.anchor_block_id))
		local a, b = leaf(args.anchor_block_id), leaf(args.block_id)
		if args.side == "before" then
			a, b = b, a
		end
		target.layout = replace(target.layout, args.anchor_block_id, split(args.direction, args.ratio, a, b))
		cleanup()
		return {}
	end
	function rex.session.new_window(args)
		local id, block = next_id("window:"), next_id("helper:")
		h.labels[block] = args.layout.block.label
		h.add_window(id, leaf(block))
		return { window_id = id, block_ids = { block } }
	end
	function rex.session.swap_blocks(args)
		local _, a = assert(h.location(args.block_id))
		local _, b = assert(h.location(args.other_block_id))
		a.layout = replace(a.layout, args.block_id, leaf(args.other_block_id))
		b.layout = replace(b.layout, args.other_block_id, leaf(args.block_id))
		return {}
	end
	function rex.session.focus_block(args)
		assert(h.location(args.block_id))
		h.focus = args.block_id
		return {}
	end
	function rex.call(method, args)
		equal(method, "block.close")
		assert(args.block_id:match("^helper:"), "must never close a real terminal")
		h.close(args.block_id)
		return {}
	end
	local environment = setmetatable({
		rex = rex,
		os = {
			getenv = function()
				return "/state"
			end,
			rename = function(source, target)
				h.saves = (h.saves or 0) + 1
				if h.fail_save == h.saves then
					return nil, "injected save failure"
				end
				files[target], files[source] = files[source], nil
				return true
			end,
		},
		io = {
			open = function(path, mode)
				if mode == "r" and not files[path] then
					return nil, "No such file", 2
				end
				local file = {}
				function file:read()
					return files[path]
				end
				function file:write(text)
					files[path] = text
					return self
				end
				function file:close()
					return true
				end
				return file
			end,
		},
	}, { __index = _G })
	function h.reload()
		setfenv(assert(loadfile(module_path)), environment)()
	end
	function h.toggle(id)
		return actions.toggle_centered_float({ session_id = "session:test", block_id = id })
	end
	function h.forget(id)
		return actions.forget_centered_float({ session_id = "session:test", block_id = id })
	end
	function h.reject(id, text)
		local ok, err = pcall(h.toggle, id)
		assert(not ok, "expected toggle to fail")
		assert(tostring(err):find(text, 1, true), tostring(err))
	end
	function h.layout(id)
		for _, window in ipairs(h.windows) do
			if window.window_id == (id or "original") then
				return window.layers[1].layout
			end
		end
	end
	h.add_window("original", layout)
	h.reload()
	return h
end

local count = 0
local function test(name, run)
	run()
	count = count + 1
	print("ok " .. count .. " - " .. name)
end

test("simple split preserves ratio and process IDs", function()
	local original = horizontal(leaf("A"), leaf("B"), 0.65)
	local h = harness(copy(original))
	h.toggle("B")
	local _, layer = h.location("B")
	equal(table.concat(layer.bounds, ","), "0.1,0.1,0.8,0.8")
	h.toggle("B")
	equal(shape(h.layout()), shape(original))
	equal(h.focus, "B")
end)

test("nested leaf returns below its direct sibling", function()
	local original = horizontal(leaf("A"), vertical(leaf("B"), leaf("C"), 0.3), 0.6)
	local h = harness(copy(original))
	h.toggle("C")
	h.toggle("C")
	equal(shape(h.layout()), shape(original))
end)

test("pop beside a sibling subtree restores that entire subtree", function()
	local original = horizontal(leaf("A"), vertical(leaf("B"), leaf("C"), 0.3), 0.6)
	local h = harness(copy(original))
	h.toggle("A")
	h.toggle("A")
	equal(shape(h.layout()), shape(original))
end)

test("split floating group returns together from any member", function()
	local h = harness(horizontal(leaf("A"), vertical(leaf("B"), leaf("C"), 0.3), 0.6))
	h.toggle("C")
	h.split("C", "D", "horizontal", 0.7)
	h.toggle("D")
	equal(
		shape(h.layout()),
		shape(horizontal(leaf("A"), vertical(leaf("B"), horizontal(leaf("C"), leaf("D"), 0.7), 0.3), 0.6))
	)
	equal(h.focus, "D")
end)

test("complex sibling and floating subtrees preserve all ratios", function()
	local sibling = horizontal(vertical(leaf("B"), leaf("C"), 0.2), vertical(leaf("D"), leaf("E"), 0.7), 0.3)
	local h = harness(vertical(leaf("A"), copy(sibling), 0.4))
	h.toggle("A")
	h.split("A", "F", "horizontal", 0.6)
	h.split("A", "G", "vertical", 0.8)
	h.split("F", "H", "vertical", 0.9)
	h.toggle("H")
	local group = horizontal(vertical(leaf("A"), leaf("G"), 0.8), vertical(leaf("F"), leaf("H"), 0.9), 0.6)
	equal(shape(h.layout()), shape(vertical(group, sibling, 0.4)))
end)

test("second pop-out is blocked but other tabs remain independent", function()
	local h = harness(horizontal(leaf("A"), leaf("B")))
	h.add_window("other", horizontal(leaf("X"), leaf("Y")))
	h.toggle("B")
	h.reject("A", "restore the existing floating group first")
	h.toggle("Y")
	h.toggle("B")
	h.toggle("Y")
end)

test("original pane may close while its floating siblings survive", function()
	local h = harness(horizontal(leaf("A"), leaf("B")))
	h.toggle("B")
	h.split("B", "C")
	h.close("B")
	h.reload()
	h.toggle("C")
	equal(shape(h.layout()), shape(horizontal(leaf("A"), leaf("C"))))
end)

test("closing the whole float releases its slot", function()
	local h = harness(horizontal(leaf("A"), leaf("B")))
	h.toggle("B")
	h.close("B")
	h.toggle("A")
	local _, layer = h.location("A")
	equal(layer.kind, "floating")
end)

test("config reload retains origin", function()
	local original = horizontal(leaf("A"), leaf("B"), 0.8)
	local h = harness(copy(original))
	h.toggle("B")
	h.reload()
	h.toggle("B")
	equal(shape(h.layout()), shape(original))
end)

test("closed direct sibling falls back to an ancestor neighbor", function()
	local h = harness(horizontal(leaf("A"), vertical(leaf("B"), leaf("C"))))
	h.toggle("C")
	h.close("B")
	h.toggle("C")
	equal(shape(h.layout()), shape(horizontal(leaf("A"), leaf("C"))))
	assert(h.message:find("surviving neighbor", 1, true))
end)

test("moved neighbor is not followed into another tab", function()
	local h = harness(horizontal(leaf("A"), vertical(leaf("B"), leaf("C"))))
	h.add_window("other", leaf("X"))
	h.toggle("C")
	local _, old = h.location("B")
	old.layout = leaf("A")
	-- Move B manually to another tab without invoking the implementation.
	h.windows[2].layers[1].layout = horizontal(leaf("X"), leaf("B"))
	h.toggle("C")
	equal(shape(h.layout()), shape(horizontal(leaf("A"), leaf("C"))))
	equal(shape(h.layout("other")), shape(horizontal(leaf("X"), leaf("B"))))
end)

test("new unrelated splits remain untouched", function()
	local h = harness(horizontal(leaf("A"), leaf("B"), 0.6))
	h.toggle("B")
	h.split("A", "X", "vertical", 0.3)
	h.toggle("B")
	equal(shape(h.layout()), shape(vertical(horizontal(leaf("A"), leaf("B"), 0.6), leaf("X"), 0.3)))
end)

test("no surviving tiled neighbors returns whole group to a new tab", function()
	local h = harness(horizontal(leaf("A"), leaf("B")))
	h.toggle("B")
	h.split("B", "C", "vertical", 0.7)
	h.close("A")
	h.toggle("C")
	equal(#h.windows, 1)
	equal(shape(h.windows[1].layers[1].layout), shape(vertical(leaf("B"), leaf("C"), 0.7)))
	equal(h.focus, "C")
	assert(h.message:find("new tab", 1, true))
end)

test("single-pane pop-out returns using a new tab", function()
	local h = harness(leaf("A"))
	h.toggle("A")
	h.toggle("A")
	equal(#h.windows, 1)
	equal(shape(h.windows[1].layers[1].layout), "A")
end)

test("failed move can resume after config reload", function()
	local original = horizontal(leaf("A"), vertical(leaf("B"), leaf("C")))
	local h = harness(copy(original))
	h.toggle("A")
	h.split("A", "D")
	h.fail_move = 2
	h.reject("A", "injected move failure")
	assert(h.location("A") and h.location("B") and h.location("C") and h.location("D"))
	h.reload()
	h.toggle("D")
	equal(shape(h.layout()), shape(horizontal(horizontal(leaf("A"), leaf("D")), vertical(leaf("B"), leaf("C")))))
end)

test("failed new-tab group return can resume", function()
	local h = harness(leaf("A"))
	h.toggle("A")
	h.split("A", "B")
	h.fail_move = 1
	h.reject("B", "injected move failure")
	h.reload()
	h.toggle("A")
	equal(#h.windows, 1)
	equal(shape(h.windows[1].layers[1].layout), shape(horizontal(leaf("A"), leaf("B"))))
end)

test("untracked popups are left alone", function()
	local h = harness(leaf("A"))
	h.windows[1].layers[2] = { layer_id = "popup", kind = "floating", layout = leaf("scratch") }
	h.reject("scratch", "popup is separate")
	h.toggle("A")
	h.toggle("A")
	local _, layer = h.location("scratch")
	equal(layer.layer_id, "popup")
end)

test("a save failure after floating recovers the pending origin", function()
	local original = horizontal(leaf("A"), leaf("B"), 0.7)
	local h = harness(copy(original))
	h.fail_save = 3
	h.reject("B", "injected save failure")
	h.reload()
	h.toggle("B")
	equal(shape(h.layout()), shape(original))
end)

test("a save failure after moving safely repeats only that step", function()
	local original = horizontal(leaf("A"), vertical(leaf("B"), leaf("C")))
	local h = harness(copy(original))
	h.toggle("A")
	h.fail_save = h.saves + 3 -- cleanup save, plan save, first move's progress save
	h.reject("A", "injected save failure")
	h.reload()
	h.toggle("A")
	equal(shape(h.layout()), shape(original))
end)

test("new-tab helper creation and swap survive progress save failures", function()
	for _, offset in ipairs({ 3, 4 }) do
		local h = harness(leaf("A"))
		h.toggle("A")
		h.split("A", "B")
		h.fail_save = h.saves + offset
		h.reject("B", "injected save failure")
		h.reload()
		h.toggle("B")
		equal(#h.windows, 1)
		equal(shape(h.windows[1].layers[1].layout), shape(horizontal(leaf("A"), leaf("B"))))
	end
end)

test("closing every member during an interrupted return releases its slot", function()
	local h = harness(horizontal(leaf("A"), leaf("B")))
	h.toggle("B")
	h.split("B", "C")
	h.fail_move = 1
	h.reject("B", "injected move failure")
	h.close("B")
	h.close("C")
	h.toggle("A")
	local _, layer = h.location("A")
	equal(layer.kind, "floating")
end)

test("manual recovery can forget metadata without moving terminals", function()
	local h = harness(horizontal(leaf("A"), leaf("B")))
	h.toggle("B")
	h.fail_move = 1
	h.reject("B", "injected move failure")
	local before = h.moves
	h.forget("A")
	equal(h.moves, before)
	h.close("B") -- user closes/docks the untracked float manually
	h.toggle("A")
	local _, layer = h.location("A")
	equal(layer.kind, "floating")
end)

test("random nested layouts and split pop-outs restore their original slot", function()
	math.randomseed(42)
	local function replace(node, id, replacement)
		if node.block_id == id then
			return copy(replacement)
		elseif node.split then
			node.split.before = replace(node.split.before, id, replacement)
			node.split.after = replace(node.split.after, id, replacement)
		end
		return node
	end
	for _ = 1, 80 do
		local original = leaf("A")
		local ids = { "A" }
		for i = 2, 7 do
			local id, anchor = "N" .. i, ids[math.random(#ids)]
			local subtree = split(
				math.random(2) == 1 and "horizontal" or "vertical",
				math.random(2, 8) / 10,
				leaf(anchor),
				leaf(id)
			)
			original = replace(original, anchor, subtree)
			ids[#ids + 1] = id
		end
		local selected = ids[math.random(#ids)]
		local h = harness(copy(original))
		h.toggle(selected)
		h.split(selected, "extra1", "vertical", 0.3)
		h.split("extra1", "extra2", "horizontal", 0.7)
		h.split(selected, "extra3", "horizontal", 0.4)
		local _, floating = h.location(selected)
		local expected = replace(copy(original), selected, floating.layout)
		h.toggle("extra2")
		equal(shape(h.layout()), shape(expected))
	end
end)

print("Passed " .. count .. " Rex floating tests")
