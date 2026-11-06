local action = "toggle_centered_float"
local terminal = "com.superlogical.terminal.shell"
local busy = false

local function first(node)
	return node.block_id or first(node.split.before)
end

local function tree(node)
	if not node then
		return nil
	end
	if node.block_id then
		return { block_id = node.block_id }
	end
	local split = node.split
	if split then
		return {
			split = {
				direction = split.direction,
				ratio = split.ratio,
				before = tree(split.before),
				after = tree(split.after),
			},
		}
	end
end

local function leaves(node, result)
	result = result or {}
	if node and node.block_id then
		result[node.block_id] = true
	elseif node and node.split then
		leaves(node.split.before, result)
		leaves(node.split.after, result)
	end
	return result
end

local function same(a, b)
	if not a or not b then
		return a == b
	end
	if a.block_id or b.block_id then
		return a.block_id == b.block_id
	end
	local x, y = a.split, b.split
	return x
		and y
		and x.direction == y.direction
		and math.abs(x.ratio - y.ratio) < 0.000001
		and same(x.before, y.before)
		and same(x.after, y.after)
end

local function contains_tree(node, target)
	if not node then
		return false
	end
	return same(node, target)
		or (node.split and (contains_tree(node.split.before, target) or contains_tree(node.split.after, target)))
end

-- Nearest sibling first, then progressively more distant ancestor neighbors.
local function origins(node, id)
	if not node then
		return nil
	end
	if node.block_id == id then
		return {}
	end
	if node.split then
		local split = node.split
		for _, side in ipairs({ "before", "after" }) do
			local path = origins(split[side], id)
			if path then
				path[#path + 1] = {
					sibling = tree(split[side == "before" and "after" or "before"]),
					side = side,
					direction = split.direction,
					ratio = split.ratio,
				}
				return path
			end
		end
	end
end

local function inspect(session_id)
	local view = assert(rex.session.view({ session_id = session_id }))
	local windows, layers, blocks = {}, {}, {}
	for _, window in ipairs(view.windows or {}) do
		windows[window.window_id] = window
		for _, layer in ipairs(window.layers or {}) do
			layers[layer.layer_id] = { window = window, layer = layer }
			for _, block in ipairs(layer.blocks or {}) do
				blocks[block.block_id] = { window = window, layer = layer, block = block }
			end
		end
	end
	return { windows = windows, layers = layers, blocks = blocks }
end

local function tiled(window)
	for _, layer in ipairs(window and window.layers or {}) do
		if layer.kind == "tiled" then
			return tree(layer.layout)
		end
	end
end

local function storage()
	local base = os.getenv("XDG_STATE_HOME")
	if not base or base == "" then
		base = assert(os.getenv("HOME")) .. "/.local/state"
	end
	local directory = base .. "/rex"
	local made = assert(rex.exec({ "mkdir", "-p", directory }))
	assert(made.ok, "Float: cannot create state directory: " .. (made.stderr or ""))
	local path = directory .. "/floating.json"
	local file, err, code = io.open(path, "r")
	local state = { version = 1, sessions = {} }
	if file then
		local text = file:read("*a")
		file:close()
		state = assert(rex.json.decode(text))
		assert(state.version == 1 and type(state.sessions) == "table", "Float: invalid saved state")
	else
		assert(code == 2 or tostring(err):lower():find("no such file", 1, true), err)
	end
	local function save()
		local text = assert(rex.json.encode(state))
		local output = assert(io.open(path .. ".tmp", "w"))
		local written, write_error = output:write(text)
		local closed, close_error = output:close()
		assert(written, write_error)
		assert(closed, close_error)
		assert(os.rename(path .. ".tmp", path))
	end
	return state, save
end

local function move(moves, block, anchor, direction, side, ratio)
	moves[#moves + 1] = {
		block_id = block,
		anchor_block_id = anchor,
		direction = direction,
		side = side,
		ratio = ratio,
	}
end

-- Expand representatives into subtrees. Moving the remaining leaves collapses
-- their old splits, so this also wraps an unchanged sibling group correctly.
local function rebuild(node, moves)
	if node.split then
		local split = node.split
		move(moves, first(split.after), first(split.before), split.direction, "after", split.ratio)
		rebuild(split.before, moves)
		rebuild(split.after, moves)
	end
end

local function destination(record, snapshot)
	local layout = tiled(snapshot.windows[record.window_id])
	if not layout then
		return nil, nil, "Original tab has no tiled panes; returned group to a new tab."
	end
	local nearest = record.origins[1]
	if nearest and contains_tree(layout, nearest.sibling) then
		return nearest.sibling, nearest
	end
	local available = leaves(layout)
	for _, origin in ipairs(record.origins) do
		-- Use layout order, not pairs(), so the fallback is deterministic.
		local function surviving(node)
			if node.block_id then
				return available[node.block_id] and node.block_id
			end
			return surviving(node.split.before) or surviving(node.split.after)
		end
		local anchor = surviving(origin.sibling)
		if anchor then
			return { block_id = anchor },
				{ direction = origin.direction, side = origin.side, ratio = 0.5 },
				"Original split changed; returned group beside a surviving neighbor."
		end
	end
	return { block_id = first(layout) },
		{ direction = "horizontal", side = "after", ratio = 0.5 },
		"Original neighbors are gone; returned group beside another pane in the original tab."
end

local function restore(ctx, record, save)
	local snapshot = inspect(ctx.session_id)
	if not record.restore then
		local floating = assert(snapshot.layers[record.layer_id], "Float: floating group no longer exists")
		local group = assert(tree(floating.layer.layout))
		local sibling, placement, message = destination(record, snapshot)
		local plan = { group = group, moves = {}, next = 1, message = message }
		if sibling then
			plan.window_id = record.window_id
			move(plan.moves, first(group), first(sibling), placement.direction, placement.side, placement.ratio)
			rebuild(sibling, plan.moves)
		else
			-- new_window only creates new blocks. A short-lived, exited helper
			-- lets us swap an existing terminal in without restarting it.
			plan.helper_label = "float-return:" .. record.layer_id
		end
		rebuild(group, plan.moves)
		record.restore = plan
		save() -- Journal the entire operation before moving any real terminals.
	end
	local plan = record.restore
	local members = leaves(plan.group)
	for id in pairs(members) do
		local placed =
			assert(snapshot.blocks[id], "Float: a group pane closed during restore; finish restoring manually")
		assert(
			placed.layer.layer_id == record.layer_id
				or (placed.window.window_id == plan.window_id and placed.layer.kind == "tiled"),
			"Float: a group pane moved elsewhere; finish restoring manually"
		)
	end
	local floating = snapshot.layers[record.layer_id]
	for _, block in ipairs(floating and floating.layer.blocks or {}) do
		assert(
			members[block.block_id] or block.block_id == plan.helper_id,
			"Float: group changed during interrupted restore; finish restoring manually"
		)
	end
	if plan.helper_label and not plan.swapped then
		local helper = plan.helper_id and snapshot.blocks[plan.helper_id]
		if not helper then
			for id, placement in pairs(snapshot.blocks) do
				if placement.block.label == plan.helper_label then
					plan.helper_id, helper = id, placement
					break
				end
			end
		end
		if not helper then
			local created = assert(rex.session.new_window({
				session_id = ctx.session_id,
				window_label = "Returned panes",
				focus = false,
				layout = {
					block = {
						flavor = terminal,
						label = plan.helper_label,
						options = { command = { "/usr/bin/true" }, shell = "none", exit = { on_completion = false } },
					},
				},
			}))
			plan.helper_id, plan.window_id = created.block_ids[1], created.window_id
		else
			local seed = assert(snapshot.blocks[first(plan.group)], "Float: return pane disappeared")
			-- Recover a swap that succeeded immediately before a failed save.
			if helper.layer.layer_id == record.layer_id and seed.layer.kind == "tiled" then
				plan.window_id, plan.swapped = seed.window.window_id, true
			else
				assert(helper.layer.kind == "tiled", "Float: return helper was moved; finish restoring manually")
				plan.window_id = helper.window.window_id
			end
		end
		save()
		if not plan.swapped then
			assert(rex.session.swap_blocks({
				session_id = ctx.session_id,
				block_id = first(plan.group),
				other_block_id = plan.helper_id,
			}))
			plan.swapped = true
			save()
		end
	end
	while plan.next <= #plan.moves do
		snapshot = inspect(ctx.session_id)
		local step = plan.moves[plan.next]
		for _, id in ipairs({ step.block_id, step.anchor_block_id }) do
			local placed = assert(snapshot.blocks[id], "Float: a restore neighbor closed; finish restoring manually")
			assert(
				(placed.window.window_id == plan.window_id and placed.layer.kind == "tiled")
					or (members[id] and placed.layer.layer_id == record.layer_id),
				"Float: a restore pane moved elsewhere; finish restoring manually"
			)
		end
		local args = { session_id = ctx.session_id }
		for key, value in pairs(step) do
			args[key] = value
		end
		assert(rex.session.move_block(args))
		plan.next = plan.next + 1
		save()
	end
	-- Verify the complete group before dropping its return location.
	snapshot = inspect(ctx.session_id)
	assert(contains_tree(tiled(snapshot.windows[plan.window_id]), plan.group), "Float: group changed during restore")
	local remaining = snapshot.layers[record.layer_id]
	for _, block in ipairs(remaining and remaining.layer.blocks or {}) do
		assert(block.block_id == plan.helper_id, "Float: extra panes remain floating; finish restoring manually")
	end
	if plan.helper_id and snapshot.blocks[plan.helper_id] then
		assert(snapshot.blocks[plan.helper_id].block.label == plan.helper_label, "Float: invalid return helper")
		assert(rex.call("block.close", { session_id = ctx.session_id, block_id = plan.helper_id }))
	end
	assert(rex.session.focus_block({
		session_id = ctx.session_id,
		block_id = members[ctx.block_id] and ctx.block_id or first(plan.group),
	}))
	return plan.message
end

local function toggle(ctx)
	assert(ctx.session_id and ctx.block_id, "Float: no focused pane")
	local state, save = storage()
	local records = state.sessions[ctx.session_id] or {}
	state.sessions[ctx.session_id] = records
	local snapshot = inspect(ctx.session_id)
	local current = assert(snapshot.blocks[ctx.block_id], "Float: pane is no longer in a tab")
	local active
	for window_id, record in pairs(records) do
		local layer = record.layer_id and snapshot.layers[record.layer_id]
		if not layer and not record.layer_id then
			local original = snapshot.blocks[record.original_block]
			if original and original.layer.kind == "floating" then
				record.layer_id = original.layer.layer_id
				layer = snapshot.layers[record.layer_id]
			end
		end
		local restoring_member = record.restore and leaves(record.restore.group)[ctx.block_id]
		local group_alive = false
		for id in pairs(record.restore and leaves(record.restore.group) or {}) do
			group_alive = group_alive or snapshot.blocks[id] ~= nil
		end
		if record.restore and not group_alive then
			local helper = record.restore.helper_id and snapshot.blocks[record.restore.helper_id]
			if helper and helper.block.label == record.restore.helper_label then
				assert(rex.call("block.close", { session_id = ctx.session_id, block_id = helper.block.block_id }))
			end
			records[window_id] = nil
		elseif not layer and not record.restore then
			records[window_id] = nil -- Closed group or a manual dock; don't chase it.
		elseif (layer and layer.layer.layer_id == current.layer.layer_id) or restoring_member then
			active = { key = window_id, record = record }
		elseif window_id == current.window.window_id or (layer and layer.window == current.window) then
			active = active or { blocked = true }
		end
	end
	save()
	if active and active.record then
		local message = restore(ctx, active.record, save)
		records[active.key] = nil
		save()
		if message then
			rex.log("warn", "Float: " .. message)
		end
		return message or "Returned floating group to its original split."
	end
	assert(not active, "Float: restore the existing floating group first")
	assert(current.layer.kind == "tiled", "Float: this popup is separate from the tiled-pane pop-out")
	local record = {
		window_id = current.window.window_id,
		original_block = ctx.block_id,
		origins = assert(origins(current.layer.layout, ctx.block_id)),
	}
	records[record.window_id] = record
	save()
	local result, err = rex.session.float_block({
		session_id = ctx.session_id,
		block_id = ctx.block_id,
		bounds = { 0.1, 0.1, 0.8, 0.8 },
	})
	if not result then
		records[record.window_id] = nil
		save()
		error(err)
	end
	record.layer_id = result.layer_id
	save()
	return "Floated pane; toggle from any pane in this group to return it."
end

local function locked(run)
	return function(ctx)
		assert(not busy, "Float: another toggle is still running")
		busy = true
		local ok, result = pcall(run, ctx)
		busy = false
		if not ok then
			error(result, 0)
		end
		return result
	end
end

rex.action({
	name = action,
	title = "Toggle Centered Float",
	category = "Pane",
	run = locked(toggle),
})

-- An explicit escape hatch after a user manually finishes an interrupted
-- restore. Forgetting metadata must never move or close any panes.
rex.action({
	name = "forget_centered_float",
	title = "Forget Pop-out Return Location",
	category = "Pane",
	run = locked(function(ctx)
		local state, save = storage()
		local snapshot = inspect(ctx.session_id)
		local current = assert(snapshot.blocks[ctx.block_id], "Float: no focused pane")
		local records = state.sessions[ctx.session_id] or {}
		local key = records[current.window.window_id] and current.window.window_id
		for window_id, record in pairs(records) do
			if
				record.layer_id == current.layer.layer_id
				or (record.restore and leaves(record.restore.group)[ctx.block_id])
			then
				key = window_id
				break
			end
		end
		assert(key, "Float: no saved return location for this tab or pane")
		records[key] = nil
		save()
		return "Forgot pop-out return location; all panes are unchanged."
	end),
})
