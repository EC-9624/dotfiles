-- Pop a pane out as a centered float, then restore its split (including any
-- panes added to the float). Journal intent before moving panes and progress
-- after each move so an interrupted return can resume after a config reload.

local FLOAT_BOUNDS = { 0.1, 0.1, 0.8, 0.8 }
local HELPER_FLAVOR = "com.superlogical.terminal.shell"
local HELPER_LABEL_PREFIX = "float-return:"

-- A layer's layout is a binary tree: { block_id } or
-- { split = { direction, ratio, before, after } }. Ratio is the share the
-- before side gets; "horizontal" puts before left of after, "vertical" puts
-- it on top.

local function leftmost_block(node)
	return node.block_id or leftmost_block(node.split.before)
end

-- A normalized deep copy: only the fields that define the tree, so copies
-- taken from different snapshots still compare equal.
local function copy_layout(node)
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
				before = copy_layout(split.before),
				after = copy_layout(split.after),
			},
		}
	end
end

local function block_id_set(node, result)
	result = result or {}
	if node and node.block_id then
		result[node.block_id] = true
	elseif node and node.split then
		block_id_set(node.split.before, result)
		block_id_set(node.split.after, result)
	end
	return result
end

local function layouts_equal(a, b)
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
		and layouts_equal(x.before, y.before)
		and layouts_equal(x.after, y.after)
end

-- Is `target` present anywhere inside `node` as a contiguous subtree?
local function contains_layout(node, target)
	if not node then
		return false
	end
	return layouts_equal(node, target)
		or (node.split and (contains_layout(node.split.before, target) or contains_layout(node.split.after, target)))
end

-- The pane's ancestry: nearest sibling first, then progressively more
-- distant ancestor neighbors. Each entry records the split that held the
-- pane, the sibling subtree on the other side, and where the pane sat in it.
local function capture_ancestry(node, id)
	if not node then
		return nil
	end
	if node.block_id == id then
		return {}
	end
	if node.split then
		local split = node.split
		for _, side in ipairs({ "before", "after" }) do
			local path = capture_ancestry(split[side], id)
			if path then
				path[#path + 1] = {
					sibling = copy_layout(split[side == "before" and "after" or "before"]),
					side = side,
					direction = split.direction,
					ratio = split.ratio,
				}
				return path
			end
		end
	end
end

-- Depth-first in layout order, not pairs(), so the fallback is deterministic.
local function first_surviving_block(node, available)
	if node.block_id then
		return available[node.block_id] and node.block_id
	end
	return first_surviving_block(node.split.before, available) or first_surviving_block(node.split.after, available)
end

local function index_session(session_id)
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

local function tiled_layout(window)
	for _, layer in ipairs(window and window.layers or {}) do
		if layer.kind == "tiled" then
			return copy_layout(layer.layout)
		end
	end
end

local function valid_split(value)
	return type(value) == "table"
		and (value.direction == "horizontal" or value.direction == "vertical")
		and type(value.ratio) == "number"
		and value.ratio > 0
		and value.ratio < 1
end

local function valid_layout(node)
	if type(node) ~= "table" then
		return false
	end
	if node.block_id ~= nil then
		return type(node.block_id) == "string" and node.split == nil
	end
	return valid_split(node.split) and valid_layout(node.split.before) and valid_layout(node.split.after)
end

local function valid_array(values, valid_item)
	if type(values) ~= "table" then
		return false
	end
	local count = 0
	for key, value in pairs(values) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #values or not valid_item(value) then
			return false
		end
		count = count + 1
	end
	return count == #values
end

local function valid_placement(value)
	return valid_split(value) and (value.side == "before" or value.side == "after")
end

-- Preserve the original persisted field names: restore/group/next/helper_id/
-- swapped. An interrupted restore must never be mistaken for a fresh float.
local function valid_record(record, window_id)
	if
		type(record) ~= "table"
		or record.window_id ~= window_id
		or type(record.original_block) ~= "string"
		or (record.layer_id ~= nil and type(record.layer_id) ~= "string")
		or record.restore_plan ~= nil
		or not valid_array(record.origins, function(origin)
			return valid_placement(origin) and valid_layout(origin.sibling)
		end)
	then
		return false
	end
	local plan = record.restore
	if plan == nil then
		return true
	end
	return type(plan) == "table"
		and type(record.layer_id) == "string"
		and valid_layout(plan.group)
		and valid_array(plan.moves, function(step)
			return valid_placement(step) and type(step.block_id) == "string" and type(step.anchor_block_id) == "string"
		end)
		and type(plan.next) == "number"
		and plan.next % 1 == 0
		and plan.next >= 1
		and plan.next <= #plan.moves + 1
		and (plan.window_id == nil or type(plan.window_id) == "string")
		and (plan.message == nil or type(plan.message) == "string")
		and (plan.helper_id == nil or type(plan.helper_id) == "string")
		and (plan.swapped == nil or type(plan.swapped) == "boolean")
		and (plan.helper_label == nil or plan.helper_label == HELPER_LABEL_PREFIX .. record.layer_id)
		and (plan.window_id ~= nil or plan.helper_label ~= nil)
end

local function open_journal()
	local base = os.getenv("XDG_STATE_HOME")
	if not base or base == "" then
		base = assert(os.getenv("HOME")) .. "/.local/state"
	end
	local directory = base .. "/rex"
	local made = assert(rex.exec({ "mkdir", "-p", directory }))
	assert(made.ok, "Float: cannot create state directory: " .. (made.stderr or ""))
	local path = directory .. "/floating.json"
	local state = { sessions = {} }
	local file, err, code = io.open(path, "r")
	if file then
		local text = file:read("*a")
		file:close()
		local ok, decoded = pcall(rex.json.decode, text)
		if ok and type(decoded) == "table" and type(decoded.sessions) == "table" then
			for session_id, records in pairs(decoded.sessions) do
				if type(session_id) == "string" and type(records) == "table" then
					local valid = {}
					for window_id, record in pairs(records) do
						if type(window_id) == "string" and valid_record(record, window_id) then
							valid[window_id] = record
						end
					end
					state.sessions[session_id] = valid
				end
			end
		end
		-- Discard malformed records without losing valid return locations.
	else
		assert(code == 2 or tostring(err):lower():find("no such file", 1, true), err)
	end
	-- Atomic save: write a sibling temp file, then rename over the target.
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

-- Expand representative leaves into subtrees, pre-order: each move
-- subdivides the anchor's current cell, so a parent split must be emitted
-- before its children. Moving the remaining leaves collapses their old
-- splits, so this also wraps an unchanged sibling group correctly.
local function compile_moves(node, moves)
	if not node.split then
		return
	end
	local split = node.split
	moves[#moves + 1] = {
		block_id = leftmost_block(split.after),
		anchor_block_id = leftmost_block(split.before),
		direction = split.direction,
		side = "after",
		ratio = split.ratio,
	}
	compile_moves(split.before, moves)
	compile_moves(split.after, moves)
end

-- Where the group goes back, with a three-tier fallback: the intact nearest
-- neighbor; a surviving leaf of any recorded neighbor, nearest first (ratio
-- reset to half, because that split no longer applies); or any pane in the
-- original tab.
local function choose_return_anchor(record, snapshot)
	local layout = tiled_layout(snapshot.windows[record.window_id])
	if not layout then
		return nil, nil, "Original tab has no tiled panes; returned group to a new tab."
	end
	local nearest = record.origins[1]
	if nearest and contains_layout(layout, nearest.sibling) then
		return nearest.sibling, nearest
	end
	local available = block_id_set(layout)
	for _, origin in ipairs(record.origins) do
		local anchor = first_surviving_block(origin.sibling, available)
		if anchor then
			return { block_id = anchor },
				{ direction = origin.direction, side = origin.side, ratio = 0.5 },
				"Original split changed; returned group beside a surviving neighbor."
		end
	end
	return { block_id = leftmost_block(layout) },
		{ direction = "horizontal", side = "after", ratio = 0.5 },
		"Original neighbors are gone; returned group beside another pane in the original tab."
end

local function build_restore_plan(record, snapshot)
	local floating = assert(snapshot.layers[record.layer_id], "Float: floating group no longer exists")
	local group = assert(copy_layout(floating.layer.layout))
	local sibling, placement, message = choose_return_anchor(record, snapshot)
	local plan = { group = group, moves = {}, next = 1, message = message }
	if sibling then
		plan.window_id = record.window_id
		plan.moves[1] = {
			block_id = leftmost_block(group),
			anchor_block_id = leftmost_block(sibling),
			direction = placement.direction,
			side = placement.side,
			ratio = placement.ratio,
		}
		compile_moves(sibling, plan.moves)
	else
		-- new_window only creates new blocks. A short-lived, exited helper
		-- lets us swap an existing terminal in without restarting it.
		plan.helper_label = HELPER_LABEL_PREFIX .. record.layer_id
	end
	compile_moves(group, plan.moves)
	return plan
end

-- Every group member must still exist and be either in the floating layer
-- or already tiled in the destination; the floating layer must hold nothing
-- but members and, later, the helper.
local function validate_group(record, snapshot)
	local plan = record.restore
	local members = block_id_set(plan.group)
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
	return members
end

-- The original tab is gone: create a "Returned panes" tab holding one
-- throwaway block that has already exited (/usr/bin/true, auto-close off),
-- then swap the group's first pane into its place. The helper is labeled so
-- an interrupted run can find it again; it is closed at the very end.
local function ensure_destination(ctx, record, snapshot, save)
	local plan = record.restore
	if not plan.helper_label or plan.swapped then
		return
	end
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
					flavor = HELPER_FLAVOR,
					label = plan.helper_label,
					options = { command = { "/usr/bin/true" }, shell = "none", exit = { on_completion = false } },
				},
			},
		}))
		plan.helper_id, plan.window_id = created.block_ids[1], created.window_id
	else
		local seed = assert(snapshot.blocks[leftmost_block(plan.group)], "Float: return pane disappeared")
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
			block_id = leftmost_block(plan.group),
			other_block_id = plan.helper_id,
		}))
		plan.swapped = true
		save()
	end
end

local function restore(ctx, record, save)
	local snapshot = index_session(ctx.session_id)
	if not record.restore then
		record.restore = build_restore_plan(record, snapshot)
		save() -- Freeze the whole plan before moving any panes.
	end
	local plan = record.restore
	local members = validate_group(record, snapshot)
	ensure_destination(ctx, record, snapshot, save)
	while plan.next <= #plan.moves do
		snapshot = index_session(ctx.session_id)
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
	snapshot = index_session(ctx.session_id)
	assert(
		contains_layout(tiled_layout(snapshot.windows[plan.window_id]), plan.group),
		"Float: group changed during restore"
	)
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
		block_id = members[ctx.block_id] and ctx.block_id or leftmost_block(plan.group),
	}))
	return plan.message
end

local function start_float(ctx, records, current, save)
	assert(current.layer.kind == "tiled", "Float: this popup is separate from the tiled-pane pop-out")
	local record = {
		window_id = current.window.window_id,
		original_block = ctx.block_id,
		origins = assert(capture_ancestry(current.layer.layout, ctx.block_id)),
	}
	records[record.window_id] = record
	save() -- Write-ahead: the record exists before the pane moves.
	local result, err = rex.session.float_block({
		session_id = ctx.session_id,
		block_id = ctx.block_id,
		bounds = FLOAT_BOUNDS,
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

local function toggle_float(ctx)
	assert(ctx.session_id and ctx.block_id, "Float: no focused pane")
	local state, save = open_journal()
	local records = state.sessions[ctx.session_id] or {}
	state.sessions[ctx.session_id] = records
	local snapshot = index_session(ctx.session_id)
	local current = assert(snapshot.blocks[ctx.block_id], "Float: pane is no longer in a tab")

	local active, blocked
	for window_id, record in pairs(records) do
		-- Recover a float that succeeded immediately before a failed save.
		if not record.layer_id then
			local original = snapshot.blocks[record.original_block]
			if original and original.layer.kind == "floating" then
				record.layer_id = original.layer.layer_id
			end
		end
		local layer = record.layer_id and snapshot.layers[record.layer_id]
		local plan = record.restore
		local members = block_id_set(plan and plan.group)
		local alive = false
		for id in pairs(members) do
			alive = alive or snapshot.blocks[id] ~= nil
		end
		if plan and not alive then
			local helper = plan.helper_id and snapshot.blocks[plan.helper_id]
			if helper and helper.block.label == plan.helper_label then
				assert(rex.call("block.close", { session_id = ctx.session_id, block_id = plan.helper_id }))
			end
			records[window_id] = nil
		elseif not layer and not plan then
			records[window_id] = nil -- Closed group or a manual dock; don't chase it.
		elseif (layer and layer.layer.layer_id == current.layer.layer_id) or members[ctx.block_id] then
			active = { key = window_id, record = record }
		elseif window_id == current.window.window_id or (layer and layer.window == current.window) then
			blocked = true
		end
	end
	save()

	if active then
		local message = restore(ctx, active.record, save)
		records[active.key] = nil
		save()
		if message then
			rex.log("warn", "Float: " .. message)
		end
		return message or "Returned floating group to its original split."
	end
	assert(not blocked, "Float: restore the existing floating group first")
	return start_float(ctx, records, current, save)
end

-- An explicit escape hatch after a user manually finishes an interrupted
-- restore. Forgetting metadata must never move or close any panes.
local function forget_float(ctx)
	local state, save = open_journal()
	local snapshot = index_session(ctx.session_id)
	local current = assert(snapshot.blocks[ctx.block_id], "Float: no focused pane")
	local records = state.sessions[ctx.session_id] or {}
	local key = records[current.window.window_id] and current.window.window_id
	for window_id, record in pairs(records) do
		if
			record.layer_id == current.layer.layer_id
			or (record.restore and block_id_set(record.restore.group)[ctx.block_id])
		then
			key = window_id
			break
		end
	end
	assert(key, "Float: no saved return location for this tab or pane")
	records[key] = nil
	save()
	return "Forgot pop-out return location; all panes are unchanged."
end

local busy = false

-- Overlapping toggles (a held key, a double palette trigger) interleave
-- badly, so refuse instead of racing.
local function single_flight(run)
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
	name = "toggle_centered_float",
	title = "Toggle Centered Float",
	description = "Pop the focused pane out as a centered float, or return it to its original split.",
	keywords = "float popout pane restore",
	category = "Pane",
	run = single_flight(toggle_float),
})

rex.action({
	name = "forget_centered_float",
	title = "Forget Pop-out Return Location",
	description = "Drop the saved return location without moving or closing any panes.",
	keywords = "float forget popout",
	category = "Pane",
	run = single_flight(forget_float),
})
