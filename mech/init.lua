--[[

  mech - mechanisms (standalone version)

  Originally part of ITB (insidethebox) minetest game.
  Boxes/hint/tui/fsc/frame dependencies removed.

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public License
  as published by the Free Software Foundation; either version 2.1
  of the License, or (at your option) any later version.

]]--

local S = core.get_translator("mech")

dofile(core.get_modpath("mech") .. "/inspector.lua")

mech = {}

local rng = math.random

-- Logic

-- Hashes a vector as a 6-byte string
local function hash_vector(v)
	local x = v.x + 32768
	local y = v.y + 32768
	local z = v.z + 32768
	return string.char(math.floor(x / 256)) .. string.char(x % 256) ..
		string.char(math.floor(y / 256)) .. string.char(y % 256) ..
		string.char(math.floor(z / 256)) .. string.char(z % 256)
end

local function dehash_vector(s)
	return {
		x = 256 * string.byte(s, 1) + string.byte(s, 2) - 32768,
		y = 256 * string.byte(s, 3) + string.byte(s, 4) - 32768,
		z = 256 * string.byte(s, 5) + string.byte(s, 6) - 32768,
	}
end

local defer_tbl = {}
local rate_tbl = {}
local rate_time = 1.0

core.register_globalstep(function(dtime)
	local t = table.copy(defer_tbl)
	defer_tbl = {}
	for _, item in pairs(t) do
		item.func(item.pos)
	end

	-- prune rate_tbl occasionally
	rate_time = rate_time - dtime
	if rate_time > 0 then
		return
	end
	rate_time = 1.0

	-- simple decay prune
	for k, v in pairs(rate_tbl) do
		if v > 1 then
			rate_tbl[k] = math.floor(v / 2)
		else
			rate_tbl[k] = nil
		end
	end
end)

local function defer(pos, func)
	local p = core.pos_to_string(pos)

	local r = rate_tbl[p] or 1
	rate_tbl[p] = r + 1
	if r > 15 then
		return
	end

	defer_tbl[#defer_tbl + 1] = {pos = pos, func = func}
end

function mech.send_trigger_to(pos)
	local node = core.get_node(pos)
	if node and core.registered_nodes[node.name] and
			core.registered_nodes[node.name].on_trigger then
		defer(pos, core.registered_nodes[node.name].on_trigger)
	--[[elseif node and node.name ~= "air" and node.name ~= "nodes:placeholder" then
		-- mech breaking
		local def = core.registered_nodes[node.name]
		local sounds = def.sounds or {}
		if sounds.dug then
			core.sound_play(sounds.dug, {pos = pos})
		end
		core.remove_node(pos)
		core.check_for_falling(pos)

		-- throw some particles around
		if not def.tiles then
			return
		end
		local texture = def.tiles and def.tiles[1] and def.tiles[1].name or
		      def.tiles[1] or def.tiles or "dirt.png"
		if type(texture) ~= "string" then
			return
		end
		core.add_particlespawner({
			amount = 16,
			time = 0.05,
			minpos = vector.add(pos, -0.5),
			maxpos = vector.add(pos, 0.5),
			minvel = {x = -0.4, y = -0.4, z = -0.4},
			maxvel = {x = -0.4, y = -0.4, z = -0.4},
			minacc = {x = 0, y = -10, z = 0},
			maxacc = {x = 0, y = -10, z = 0},
			minexptime = 0.3,
			maxexptime = 0.7,
			minsize = 1.0,
			maxsize = 2.4,
			collisiondetection = true,
			texture = texture .. "^[sheet:4x4:" .. (rng(4)-1) .. "," .. (rng(4)-1)
		})--]]
	end
end

function mech.send_untrigger_to(pos)
	local node = core.get_node(pos)
	if node and core.registered_nodes[node.name] and
			core.registered_nodes[node.name].on_untrigger then
		defer(pos, core.registered_nodes[node.name].on_untrigger)
	end
end

function mech.trigger(pos)
	local meta = core.get_meta(pos)
	local offsets = core.deserialize(meta:get_string("offsets")) or {}
	for v, _ in pairs(offsets) do
		mech.send_trigger_to(vector.add(pos, dehash_vector(v)))
	end
end

function mech.untrigger(pos)
	local meta = core.get_meta(pos)
	local offsets = core.deserialize(meta:get_string("offsets")) or {}
	for v, _ in pairs(offsets) do
		mech.send_untrigger_to(vector.add(pos, dehash_vector(v)))
	end
end

-- Build the connections list as an array rather than a hash table
-- Saves it to triggers, also checks for and respects untrigger hash table.
-- (used by Randomizer)
local function update_trigger_list(pos)
	local meta = core.get_meta(pos)
	local offsets = core.deserialize(meta:get_string("offsets")) or {}
	local untrigger = core.deserialize(meta:get_string("untrigger")) or {}
	local triggers = {}
	for v in pairs(offsets) do
		if not untrigger[v] then
			table.insert(triggers, v)
		end
	end
	meta:set_string("triggers", core.serialize(triggers))
	meta:mark_as_private("triggers")

	-- Check for dirty untrigger list
	local dirty = false
	for v in pairs(untrigger) do
		if not offsets[v] then
			untrigger[v] = nil
			dirty = true
		end
	end
	if dirty then
		meta:set_string("untrigger", core.serialize(untrigger))
		meta:mark_as_private("untrigger")
	end

	return triggers
end

function mech.link(pos1, pos2)
	local meta1 = core.get_meta(pos1)
	local off1 = core.deserialize(meta1:get_string("offsets")) or {}
	off1[hash_vector(vector.subtract(pos2, pos1))] = true

	local meta2 = core.get_meta(pos2)
	local off2 = core.deserialize(meta2:get_string("roffsets")) or {}
	off2[hash_vector(vector.subtract(pos1, pos2))] = true

	local function c(t)
		local n = 0
		for _, _ in pairs(t) do
			n = n + 1
		end
		return n
	end

	if c(off1) > 64 or c(off2) > 64 then
		return false
	end

	meta1:set_string("offsets", core.serialize(off1))
	meta1:mark_as_private("offsets")
	meta2:set_string("roffsets", core.serialize(off2))
	meta1:mark_as_private("roffsets")

	if meta1:get_string("triggers") ~= "" then
		update_trigger_list(pos1)
	end

	return true
end

local function unlink(pos, meta)
	local offsets = core.deserialize(meta.fields.offsets or "") or {}
	for v, _ in pairs(offsets) do
		local np = vector.add(pos, dehash_vector(v))
		local meta2 = core.get_meta(np)
		local roff = core.deserialize(meta2:get_string("roffsets")) or {}
		roff[hash_vector(vector.subtract(pos, np))] = nil
		meta2:set_string("roffsets", core.serialize(roff))
		meta2:mark_as_private("roffsets")
	end
	local roffsets = core.deserialize(meta.fields.roffsets or "") or {}
	for v, _ in pairs(roffsets) do
		local np = vector.add(pos, dehash_vector(v))
		local meta2 = core.get_meta(np)
		local off = core.deserialize(meta2:get_string("offsets")) or {}
		off[hash_vector(vector.subtract(pos, np))] = nil
		meta2:set_string("offsets", core.serialize(off))
		meta2:mark_as_private("offsets")
	end

	if meta and meta.fields and meta.fields.triggers then
		update_trigger_list(pos)
	end
end

function mech.after_dig(pos, oldnode, oldmetadata, digger)
	unlink(pos, oldmetadata)
end

local function mech_connect(itemstack, placer, pointed_thing, rightclick)
	if not pointed_thing or not pointed_thing.under then
		return
	end
	if not placer then
		return
	end

	local meta = itemstack:get_meta()
	if rightclick then
		local link = meta:get_string("link")
		if link == "" then
			core.chat_send_player(placer:get_player_name(),
				S("Left-click a node first."))
			return itemstack
		end

		local pos1 = core.deserialize(link)
		local pos2 = pointed_thing.under

		if placer:get_player_control().sneak then
			-- unlink
			local m1 = core.get_meta(pos1)
			local t1 = m1:to_table()
			local offsets = core.deserialize(t1.fields.offsets or "") or {}
			offsets[hash_vector(vector.subtract(pos2, pos1))] = nil
			m1:set_string("offsets", core.serialize(offsets))
			m1:mark_as_private("offsets")

			local m2 = core.get_meta(pos2)
			local t2 = m2:to_table()
			local roffsets = core.deserialize(t2.fields.roffsets or "") or {}
			roffsets[hash_vector(vector.subtract(pos1, pos2))] = nil
			m2:set_string("roffsets", core.serialize(roffsets))
			m2:mark_as_private("roffsets")

			core.chat_send_player(placer:get_player_name(), S("Connection removed from \"@1\" at ",
					core.get_node(pos2).name) ..
					core.pos_to_string(pos2) .. ".")
			core.sound_play("button_untrigger", {pos = pointed_thing.under})
		else
			if mech.link(pos1, pos2) then
				core.chat_send_player(placer:get_player_name(), S("Connection completed with \"@1\" at ",
						core.get_node(pos2).name) ..
						core.pos_to_string(pos2) .. ".")
				core.sound_play("button_untrigger", {pos = pointed_thing.under})
			else
				core.chat_send_player(placer:get_player_name(), S("Connection failed. Too many connections."))
			end
		end
	else -- left click
		core.chat_send_player(placer:get_player_name(), S("Connection started with \"@1\" at ",
				core.get_node(pointed_thing.under).name) ..
				core.pos_to_string(pointed_thing.under) .. ".")
		core.sound_play("button_trigger", {pos = pointed_thing.under})
		meta:set_string("description", S("Connector tool").."\n" ..
			S("Right-click creates a connection from \"@1\" at ",
				core.get_node(pointed_thing.under).name) ..
				core.pos_to_string(pointed_thing.under) .. "\n" ..
			S("Right click + Shift to remove the connection from \"@1\" at ",
			core.get_node(pointed_thing.under).name) ..
			core.pos_to_string(pointed_thing.under) .. ".")
		meta:set_string("link", core.serialize(pointed_thing.under))
	end
	return itemstack
end

core.register_tool("mech:connector", {
	description = S("Connector tool").."\n"..
		S("Left-click to start a link").."\n"..
		S("Right-click to complete a link"),
	inventory_image = "connector_tool.png",
	on_use = function(itemstack, placer, pointed_thing)
		if core.is_protected(pointed_thing.under, placer:get_player_name()) then
			core.chat_send_player(placer:get_player_name(), S("You don't have permission to modify this node."))
			return itemstack
		end
		return mech_connect(itemstack, placer, pointed_thing, false)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if core.is_protected(pointed_thing.under, placer:get_player_name()) then
			core.chat_send_player(placer:get_player_name(), S("You don't have permission to modify this node."))
			return itemstack
		end
		return mech_connect(itemstack, placer, pointed_thing, true)
	end,
})

-- event creators:
-- buttons
core.register_node("mech:button", {
	description = S("Button"),
	drawtype = "mesh",
	use_texture_alpha = "clip",
	mesh = "button_up.obj",
	tiles = {"button_switch.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	collision_box = {
		type = "fixed",
		fixed = {{-5/16, -1/4, 1/4, 5/16, 1/4, 1/2}},
	},
	selection_box = {
		type = "fixed",
		fixed = {{-5/16, -1/4, 1/4, 5/16, 1/4, 1/2}},
	},
	after_dig_node = mech.after_dig,
	on_punch = function(pos, node, puncher, pointed_thing)
		mech.trigger(pos)
		node.name = "mech:button_down"
		core.swap_node(pos, node)
		core.get_node_timer(pos):start(1)
		core.sound_play("button_trigger", {pos = pos})
	end,
	on_rightclick = function(pos, node, puncher, itemstack, pointed_thing)
		mech.trigger(pos)
		node.name = "mech:button_down"
		core.swap_node(pos, node)
		core.get_node_timer(pos):start(1)
		core.sound_play("button_trigger", {pos = pos})
		return itemstack
	end,
})

core.register_node("mech:button_down", {
	description = S("Button (pressed)"),
	drawtype = "mesh",
	use_texture_alpha = "clip",
	mesh = "button_down.obj",
	tiles = {"button_switch.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	groups = {node = 1, cracky = 2, mech = 1, trigger = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
	collision_box = {
		type = "fixed",
		fixed = {{-5/16, -1/4, 1/4, 5/16, 1/4, 1/2}},
	},
	selection_box = {
		type = "fixed",
		fixed = {{-5/16, -1/4, 1/4, 5/16, 1/4, 1/2}},
	},
	after_dig_node = mech.after_dig,
	on_timer = function(pos)
		mech.untrigger(pos)
		local node = core.get_node(pos)
		node.name = "mech:button"
		core.swap_node(pos, node)
		core.sound_play("button_untrigger", {pos = pos})
	end,
})

-- switches
core.register_node("mech:switch", {
	description = S("Switch"),
	drawtype = "mesh",
	use_texture_alpha = "clip",
	mesh = "switch.obj",
	tiles = {"button_switch.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	collision_box = {
		type = "fixed",
		fixed = {{-1/4, -5/16, 1/4, 1/4, 5/16, 1/2}},
	},
	selection_box = {
		type = "fixed",
		fixed = {{-1/4, -5/16, 1/4, 1/4, 5/16, 1/2}},
	},
	after_dig_node = mech.after_dig,
	on_punch = function(pos, node, puncher, pointed_thing)
		mech.trigger(pos)
		node.name = "mech:switch_on"
		core.swap_node(pos, node)
		core.sound_play("button_trigger", {pos = pos})
	end,
	on_rightclick = function(pos, node, puncher, itemstack, pointed_thing)
		mech.trigger(pos)
		node.name = "mech:switch_on"
		core.swap_node(pos, node)
		core.sound_play("button_trigger", {pos = pos})
		return itemstack
	end,
})

core.register_node("mech:switch_on", {
	description = S("Switch (on)"),
	drawtype = "mesh",
	use_texture_alpha = "clip",
	mesh = "switch_on.obj",
	tiles = {"button_switch.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	groups = {node = 1, cracky = 2, mech = 1, trigger = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
	collision_box = {
		type = "fixed",
		fixed = {{-1/4, -5/16, 1/4, 1/4, 5/16, 1/2}},
	},
	selection_box = {
		type = "fixed",
		fixed = {{-1/4, -5/16, 1/4, 1/4, 5/16, 1/2}},
	},
	after_dig_node = mech.after_dig,
	on_punch = function(pos, node, puncher, pointed_thing)
		mech.untrigger(pos)
		node.name = "mech:switch"
		core.swap_node(pos, node)
		core.sound_play("button_untrigger", {pos = pos})
	end,
	on_rightclick = function(pos, node, puncher, itemstack, pointed_thing)
		mech.untrigger(pos)
		node.name = "mech:switch"
		core.swap_node(pos, node)
		core.sound_play("button_untrigger", {pos = pos})
		return itemstack
	end,
})

-- pressure plates
core.register_node("mech:pressure_plate", {
	description = S("Pressure plate"),
	drawtype = "nodebox",
	tiles = {"blocks_tiles.png^[sheet:8x8:3,2"},
	node_box = {
		type = "fixed",
		fixed = {{-7/16, -1/2, -7/16, 7/16, -7/16, 7/16}},
	},
	paramtype = "light",
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	walkable = false,
	after_dig_node = mech.after_dig,
	on_walk_over = function(pos, node, player)
		local remove
		local meta = core.get_meta(pos)
		local offsets = core.deserialize(meta:get_string("offsets")) or {}
		local h = hash_vector({x = 0, y = 0, z = 0})
		for v, _ in pairs(offsets) do
			if v == h then
				remove = true
			end
		end

		mech.trigger(pos)

		if remove then
			return
		end

		node.name = "mech:pressure_plate_down"
		core.swap_node(pos, node)
		core.get_node_timer(pos):start(0.5)
		core.sound_play("button_trigger", {pos = pos})
	end,
})

core.register_node("mech:pressure_plate_down", {
	description = S("Pressure plate (pressed)"),
	drawtype = "nodebox",
	tiles = {"blocks_tiles.png^[sheet:8x8:3,2"},
	node_box = {
		type = "fixed",
		fixed = {{-7/16, -1/2, -7/16, 7/16, -1/2 + 0.001, 7/16}},
	},
	paramtype = "light",
	groups = {node = 1, cracky = 2, mech = 1, trigger = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	walkable = false,
	on_walk_over = function(pos, node, player)
		core.get_node_timer(pos):start(0.5)
	end,
	on_timer = function(pos)
		mech.untrigger(pos)
		local node = core.get_node(pos)
		node.name = "mech:pressure_plate"
		core.swap_node(pos, node)
		core.sound_play("button_untrigger", {pos = pos})
	end,
})

core.register_globalstep(function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		local ppos = player:get_pos()
		local pos = vector.round(ppos)
		if ppos.y - pos.y <= 0.1 then
			local node = core.get_node(pos)

			local def = core.registered_nodes[node.name]
			if def and def.on_walk_over then
				def.on_walk_over(pos, node, player)
			end
		end
	end
end)

-- xbows target
minetest.after(0, function()
    local target = "x_bows:target"
    local def = minetest.registered_nodes[target]
    if not def then
        minetest.log("error", "[mech] Node inexistant: " .. target)
        return
    end
    local old_on_punch = def.on_punch
    local old_on_timer = def.on_timer
    minetest.override_item(target, {
        on_punch = function(pos, node, puncher, pointed_thing)
            mech.trigger(pos)
            local timer = minetest.get_node_timer(pos)
            timer:start(2)

            if old_on_punch then
                return old_on_punch(pos, node, puncher, pointed_thing)
            end
        end,

        on_timer = function(pos, elapsed)
            mech.untrigger(pos)
            if old_on_timer then
                return old_on_timer(pos, elapsed)
            end

            return false
        end
    })
end)

-- piston
local pistondir = {
	[0] = {x = 0, y = 1, z = 0},
	[1] = {x = 0, y = 0, z = 1},
	[2] = {x = 0, y = 0, z = -1},
	[3] = {x = 1, y = 0, z = 0},
	[4] = {x = -1, y = 0, z = 0},
	[5] = {x = 0, y = -1, z = 0},
}

local function piston_on_trigger(pos)
	local node = core.get_node(pos)
	local dir = pistondir[math.floor(node.param2 / 4)]

	local _p = vector.add(pos, dir)
	local stack = 16
	while true do
		local _n = core.get_node(_p)
		if core.registered_nodes[_n.name].unpushable then
			return
		end
		if core.registered_nodes[_n.name].buildable_to then
			break
		end
		stack = stack - 1
		if stack == 0 then
			return
		end
		_p = vector.add(_p, dir)
	end

	while stack < 16 do
		local _pp = vector.subtract(_p, dir)
		local _nn = core.get_node(_pp)
		local _ppmeta = core.get_meta(_pp)
		local _pmeta = core.get_meta(_p)
		core.set_node(_p, _nn)
		_pmeta:from_table(_ppmeta:to_table())

		core.check_for_falling(_pp)

		stack = stack + 1
		_p = _pp
	end

	if node.name == "mech:piston_base" then
		node.name = "mech:piston_top"
	else
		node.name = "mech:piston_top_sticky"
	end
	core.set_node(_p, node)

	node.name = "mech:piston_base_extended"
	core.swap_node(pos, node)
	core.sound_play("piston_trigger", {pos = pos})

	core.check_for_falling(_p)
end

core.register_node("mech:piston_base", {
	description = S("Piston"),
	paramtype2 = "facedir",
	tiles = {"piston_top_normal.png", "piston_bottom.png", "piston_side.png"},
	groups = {node = 1, cracky = 2},
	sounds = default.node_sound_wood_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = piston_on_trigger,
})

core.register_node("mech:piston_base_sticky", {
	description = S("Sticky piston"),
	paramtype2 = "facedir",
	tiles = {"piston_top_sticky.png", "piston_bottom.png", "piston_side.png"},
	groups = {node = 1, cracky = 2},
	sounds = default.node_sound_wood_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = piston_on_trigger,
})

core.register_node("mech:piston_base_extended", {
	description = S("Extended piston base"),
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	tiles = {"piston_inner.png", "piston_bottom.png", "[combine:16x16:0,0=piston_side.png:0,-12=piston_side.png"},
	node_box = {
		type = "fixed",
		fixed = {
			{-1/2, -1/2, -1/2, 1/2, 1/4, 1/2}, -- base
			{-1/8, 1/4, -1/8, 1/8, 1/2, 1/8}, -- rod
		}
	},
	groups = {node = 1, unbreakable = 1, mech = 1, not_in_creative_inventory = 1},
	unpushable = 1,
	sounds = default.node_sound_wood_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = function(pos) end,
	on_untrigger = function(pos)
		local node = core.get_node(pos)
		local dir = pistondir[math.floor(node.param2 / 4)]
		local npos = vector.add(pos, dir)
		local nnode = core.get_node(npos)
		local nnpos = vector.add(npos, dir)
		if nnode.name == "mech:piston_top_sticky" then
			local nnnode = core.get_node(nnpos)
			if not core.registered_nodes[nnnode.name].unpushable then
				local nnmeta = core.get_meta(nnpos)
				local nmeta = core.get_meta(npos)
				core.swap_node(npos, nnnode)
				nmeta:from_table(nnmeta:to_table())
				core.remove_node(nnpos)
			else
				core.remove_node(npos)
			end
			node.name = "mech:piston_base_sticky"
		elseif nnode.name == "mech:piston_top" then
			core.remove_node(npos)
			node.name = "mech:piston_base"
		else
			return
		end
		core.swap_node(pos, node)
		core.sound_play("piston_untrigger", {pos = pos})

		core.check_for_falling(npos)
		core.check_for_falling(nnpos)
	end,
})

core.register_node("mech:piston_top", {
	description = S("Piston head"),
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	tiles = {"piston_top_normal.png", "piston_inner.png", "piston_side.png"},
	node_box = {
		type = "fixed",
		fixed = {
			{-1/2, 1/4, -1/2, 1/2, 1/2, 1/2}, -- head
			{-1/8, -1/2, -1/8, 1/8, 1/4, 1/8}, -- rod
		}
	},
	groups = {node = 1, unbreakable = 1, piston_top = 1, not_in_creative_inventory = 1},
	unpushable = 1,
	sounds = default.node_sound_wood_defaults(),
	on_trigger = function(pos) end,
})

core.register_node("mech:piston_top_sticky", {
	description = S("Sticky piston head"),
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	tiles = {"piston_top_sticky.png", "piston_inner.png", "piston_side.png"},
	groups = {node = 1, unbreakable = 1, piston_top = 1, not_in_creative_inventory = 1},
	unpushable = 1,
	sounds = default.node_sound_wood_defaults(),
	node_box = {
		type = "fixed",
		fixed = {
			{-1/2, 1/4, -1/2, 1/2, 1/2, 1/2}, -- head
			{-1/8, -1/2, -1/8, 1/8, 1/4, 1/8}, -- rod
		}
	},
	on_trigger = function(pos) end,
})

core.register_node("mech:delayer", {
	description = S("Delayer"),
	tiles = {"delayer.png"},
	place_param2 = 1,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = function(pos)
		local node = core.get_node(pos)
		core.after(node.param2, mech.trigger, pos)
	end,
	on_untrigger = function(pos)
		local node = core.get_node(pos)
		core.after(node.param2, mech.untrigger, pos)
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher then return end
		if core.is_protected(pos, puncher:get_player_name()) then
			return
		end
		node.param2 = (node.param2 % 16) + 1
		core.chat_send_player(puncher:get_player_name(), S("Delay = @1", node.param2))
		core.swap_node(pos, node)
	end,
	on_rightclick = function(pos, node, puncher, itemstack, pointed_thing)
		if not puncher then return itemstack end
		if core.is_protected(pos, puncher:get_player_name()) then
			return itemstack
		end
		node.param2 = (node.param2 - 2) % 16 + 1
		core.chat_send_player(puncher:get_player_name(), S("Delay = @1", node.param2))
		core.swap_node(pos, node)
		return itemstack
	end,
	on_reveal = function(name, pos)
		local node = core.get_node(pos)
		core.chat_send_player(name, core.colorize(
			"#4444ff", S("> delay = @1", node.param2)
			))
	end,
})

core.register_node("mech:extender", {
	description = S("Extender"),
	tiles = {"extender.png"},
	place_param2 = 1,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = mech.trigger,
	on_untrigger = function(pos)
		local node = core.get_node(pos)
		core.after(node.param2, mech.untrigger, pos)
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher then return end
		if core.is_protected(pos, puncher:get_player_name()) then
			return
		end
		node.param2 = (node.param2 % 16) + 1
		core.chat_send_player(puncher:get_player_name(), S("Delay = @1", node.param2))
		core.swap_node(pos, node)
	end,
	on_rightclick = function(pos, node, puncher, itemstack, pointed_thing)
		if not puncher then return itemstack end
		if core.is_protected(pos, puncher:get_player_name()) then
			return itemstack
		end
		node.param2 = (node.param2 - 2) % 16 + 1
		core.chat_send_player(puncher:get_player_name(), S("Delay = @1", node.param2))
		core.swap_node(pos, node)
		return itemstack
	end,
	on_reveal = function(name, pos)
		local node = core.get_node(pos)
		core.chat_send_player(name, core.colorize(
			"#4444ff", S("> extension = @1", node.param2)
			))
	end,
})

core.register_node("mech:inverter", {
	description = S("Inverter"),
	tiles = {"inverter.png"},
	place_param2 = 1,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = mech.untrigger,
	on_untrigger = mech.trigger,
})

core.register_node("mech:filter", {
	description = S("Filter"),
	tiles = {"filter.png"},
	place_param2 = 1,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = mech.trigger,
})

core.register_node("mech:toggle", {
	description = S("Toggle"),
	tiles = {"toggle.png"},
	place_param2 = 0,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = function(pos)
		local node = core.get_node(pos)
		if node.param2 == 0 then
			node.param2 = 1
			core.swap_node(pos, node)
			mech.trigger(pos)
		else
			node.param2 = 0
			core.swap_node(pos, node)
			mech.untrigger(pos)
		end
	end,
	on_untrigger = function(pos)
		local node = core.get_node(pos)
		if node.param2 == 0 then
			node.param2 = 1
			core.swap_node(pos, node)
			mech.trigger(pos)
		else
			node.param2 = 0
			core.swap_node(pos, node)
			mech.untrigger(pos)
		end
	end,
})

core.register_node("mech:adder", {
	description = S("Adder"),
	tiles = {"adder.png"},
	place_param2 = 32,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = function(pos)
		local node = core.get_node(pos)
		local count = (node.param2 % 16)
		local need = math.floor(node.param2 / 16)
		if count < 15 then
			count = count + 1
		end
		if count == need then
			mech.trigger(pos)
		end
		node.param2 = need * 16 + count
		core.swap_node(pos, node)
	end,
	on_untrigger = function(pos)
		local node = core.get_node(pos)
		local count = (node.param2 % 16)
		local need = math.floor(node.param2 / 16)
		if count > 0 then
			count = count - 1
		end
		if count == (need - 1) then
			mech.untrigger(pos)
		end
		node.param2 = need * 16 + count
		core.swap_node(pos, node)
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher then return end
		if core.is_protected(pos, puncher:get_player_name()) then
			return
		end
		node.param2 = (node.param2 + 16) % 256
		core.chat_send_player(puncher:get_player_name(), S("Count = @1", math.floor(node.param2 / 16)))
		core.swap_node(pos, node)
	end,
	on_rightclick = function(pos, node, puncher, itemstack, pointed_thing)
		if not puncher then return itemstack end
		if core.is_protected(pos, puncher:get_player_name()) then
			return itemstack
		end
		node.param2 = (node.param2 - 16) % 256
		core.chat_send_player(puncher:get_player_name(), S("Count = @1", math.floor(node.param2 / 16)))
		core.swap_node(pos, node)
		return itemstack
	end,
	on_reveal = function(name, pos)
		local node = core.get_node(pos)
		local count = (node.param2 % 16)
		local need = math.floor(node.param2 / 16)
		core.chat_send_player(name, core.colorize(
			"#4444ff",
			S("> target count = @1", need)
			))
		core.chat_send_player(name, core.colorize(
			"#4444ff",
			S("> current count = @1", count)
			))
	end,
})

local facedir_top = {
	[0] = {x = 0, y = 1, z = 0},
	[1] = {x = 0, y = 0, z = 1},
	[2] = {x = 0, y = 0, z = -1},
	[3] = {x = 1, y = 0, z = 0},
	[4] = {x = -1, y = 0, z = 0},
	[5] = {x = 0, y = -1, z = 0},
}

local function is_detected(name, meta)
	local n = meta:get_string("nodes")
	if n ~= "" then
		local nodes = core.deserialize(n)
		if nodes[name] then
			return true
		end
		return false
	end
	if name == "air" or name == "nodes:placeholder" then
		return false
	end
	local g = core.registered_nodes[name].groups
	if g.torch ~= nil or g.piston_top ~= nil then
		return false
	end
	return true
end

core.register_node("mech:node_detector", {
	description = S("Node detector").."\n"..S("Punch nodes while wielding this to limit detection to punched nodes"),
	tiles = {"detector_top.png", "detector_bottom.png", "detector_side.png"},
	liquids_pointable = true,
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	paramtype2 = "facedir",
	on_use = function(itemstack, user, pointed_thing)
		if not pointed_thing.under then
			return itemstack
		end
		local pos = pointed_thing.under
		local node = core.get_node(pos)
		local meta = itemstack:get_meta()
		local def = core.registered_nodes[node.name]
		if def.groups.not_in_creative_inventory and not def.groups.frame_with_content or
		   def.groups.trigger or def.groups.mech or
		   def.groups.door
		then
			return itemstack
		end
		local nodes = core.deserialize(meta:get_string("nodes")) or {}
		nodes[node.name] = 1
		meta:set_string("nodes", core.serialize(nodes))
		local s = ""
		for k, _ in pairs(nodes) do
			if s == "" then
				s = k
			else
				s = s .. ", " .. k
			end
		end
		core.chat_send_player(user:get_player_name(), S("This detector will detect: ") .. s)
		meta:set_string("description", S("Detector node").."\n"..S("Detects: ") .. s)
		return itemstack
	end,
	on_place = function(itemstack, placer, pointed_thing)
		local meta = itemstack:get_meta()
		local pos = pointed_thing.above
		core.set_node(pos, {name = "mech:node_detector"})
		local nmeta = core.get_meta(pos)
		local nodes = meta:get_string("nodes")
		if nodes ~= "" then
			nmeta:set_string("nodes", nodes)
			nmeta:mark_as_private("nodes")
		end
		return itemstack
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher then return end
		if core.is_protected(pos, puncher:get_player_name()) then
			return
		end
		local meta = core.get_meta(pos)
		local dist = (meta:get_int("distance") + 1) % 16
		core.chat_send_player(puncher:get_player_name(), S("Distance = @1", dist))
		meta:set_int("distance", dist)
	end,
	on_rightclick = function(pos, node, puncher, itemstack, pointed_thing)
		if not puncher then return itemstack end
		if core.is_protected(pos, puncher:get_player_name()) then
			return itemstack
		end
		local meta = core.get_meta(pos)
		local dist = (meta:get_int("distance") - 1) % 16
		core.chat_send_player(puncher:get_player_name(), S("Distance = @1", dist))
		meta:set_int("distance", dist)
		return itemstack
	end,
	after_dig_node = mech.after_dig,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_int("detected", 0)
		core.get_node_timer(pos):start(0.5)
	end,
	on_timer = function(pos)
		local node = core.get_node(pos)
		local dir = facedir_top[math.floor(node.param2 / 4)]
		local meta = core.get_meta(pos)
		local dist = meta:get_int("distance") or 0
		if dist > 0 then
			dir = vector.multiply(dir, dist + 1)
		end
		local p2 = vector.add(pos, dir)

		local n2 = core.get_node(p2)
		local state = meta:get_int("detected")
		if state == 0 and is_detected(n2.name, meta) == true then
			mech.trigger(pos)
			meta:set_int("detected", 1)
			core.sound_play("button_trigger", {pos = pos})
		elseif state == 1 and is_detected(n2.name, meta) == false then
			mech.untrigger(pos)
			meta:set_int("detected", 0)
			core.sound_play("button_untrigger", {pos = pos})
		end
		return true
	end,
	on_trigger = function() end,
	on_untrigger = function() end,
	on_reveal = function(name, pos)
		local meta = core.get_meta(pos)
		local n = meta:get_string("nodes")
		if n ~= "" then
			local nodes = core.deserialize(n)
			for k, _ in pairs(nodes) do
				local def = core.registered_nodes[k]
				core.chat_send_player(name, core.colorize(
					"#88ff44", S("> Detects ") .. def.description:gsub("\n.*", "")))
			end
		else
			core.chat_send_player(name, core.colorize(
				"#88ff44", S("> Detects anything")))
		end

		local dist = meta:get_int("distance") or 0
		core.chat_send_player(name, core.colorize(
			"#4444ff", S("> distance = @1", dist)
			))
	end,
})

core.register_node("mech:node_creator", {
	description = S("Node creator"),
	tiles = {"creator_top.png", "creator_bottom.png", "creator_side.png"},
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	paramtype2 = "facedir",
	liquids_pointable = true,

	on_construct = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()

		inv:set_size("node", 1)

		meta:set_int("distance", 0)

		meta:set_string("formspec", table.concat({
			"formspec_version[4]",
			"size[12,9]",
			"label[0.3,0.3;" .. core.formspec_escape(S("Node to place")) .. "]",
			"list[context;node;5,1;1,1;]",
			"label[0.3,2.5;" .. core.formspec_escape(S("Punch = increase distance")) .. "]",
			"list[current_player;main;1,3.5;8,4;]",
			"listring[context;node]",
			"listring[current_player;main]",
		}))
	end,

	can_dig = function(pos, player)
		if core.is_protected(pos, player:get_player_name()) then
			return 0
		end
		local inv = core.get_meta(pos):get_inventory()
		return inv:is_empty("node")
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname ~= "node" then
			return 0
		end

		if core.is_protected(pos, player:get_player_name()) then
			return 0
		end

		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		if not inv:is_empty("node") then
			return 0
		end

		local name = stack:get_name()

		if not core.registered_nodes[name] then
			return 0
		end

		return 1
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if core.is_protected(pos, player:get_player_name()) then
			return 0
		end
		return stack:get_count()
	end,

	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher then
			return
		end

		if core.is_protected(pos, puncher:get_player_name()) then
			return
		end

		local meta = core.get_meta(pos)
		local dist = (meta:get_int("distance") + 1) % 16

		meta:set_int("distance", dist)

		core.chat_send_player(
			puncher:get_player_name(),
			S("Distance = @1", dist)
		)
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)

		if core.is_protected(pos, clicker:get_player_name()) then
			return itemstack
		end

		local meta = core.get_meta(pos)

		core.show_formspec(clicker:get_player_name(), "mech:node_creator_" .. core.pos_to_string(pos), meta:get_string("formspec"))
	end,

	after_dig_node = mech.after_dig,

	on_trigger = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()

		local stack = inv:get_stack("node", 1)

		if stack:is_empty() then
			local distance = meta:get_int("distance")
			local block_pos = pos
			block_pos.y = block_pos.y + distance + 1 -- index commence à partir de 0
			if not core.is_protected(block_pos, "") then
				local node = core.get_node(block_pos).name
				if node ~= "air" and node ~= nil then
					if core.get_item_group(node.name, "unbreakable") == 0 then
						core.set_node(pos, {name = "air"})
						inv:add_item("node", node)
					end
				end
			end
			return
		end

		local nodename = stack:get_name()

		local node = core.get_node(pos)

		local dist = meta:get_int("distance") or 0

		local dir = facedir_top[math.floor(node.param2 / 4)]

		if dist > 0 then
			dir = vector.multiply(dir, dist + 1)
		end

		local target_pos = vector.add(pos, dir)

		local current = core.get_node(target_pos)

		-- Empêche d'écraser un bloc différent
		if current.name ~= "air" then
			return false
		end

		local def_current = core.registered_nodes[current.name]

		if def_current
		and def_current.groups
		and def_current.groups.sign
		and def_current.on_destruct then
			def_current.on_destruct(target_pos)
		end

		core.swap_node(target_pos, {name = nodename})

		inv:set_stack("node", 1, ItemStack(""))

		local def = core.registered_nodes[nodename]

		if def then
			if def.after_place_node then
				def.after_place_node(
					target_pos,
					nil,
					ItemStack(nodename),
					nil
				)
			end

			local sounds = def.sounds or {}

			if sounds.place then
				core.sound_play(sounds.place, {
					pos = target_pos
				})
			end
		end

		core.check_for_falling(target_pos)

		return true
	end,

	on_untrigger = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()

		local node = core.get_node(pos)

		local dist = meta:get_int("distance") or 0

		local dir = facedir_top[math.floor(node.param2 / 4)]

		if dist > 0 then
			dir = vector.multiply(dir, dist + 1)
		end

		local target_pos = vector.add(pos, dir)

		local current = core.get_node(target_pos)

		if inv:get_stack("node", 1):get_count() < 2 then
			return
		end

		if current.name == "air" then
			if inv:get_stack("node", 1):is_empty() then
				inv:set_stack("node", 1, ItemStack(""))
			end
			return
		end

		inv:set_stack("node", 1, ItemStack(current.name))

		core.remove_node(target_pos)

		core.check_for_falling(target_pos)
	end,

	on_reveal = function(name, pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack("node", 1)

		if not stack:is_empty() then
			core.chat_send_player(name, core.colorize(
				"#88ff44",
				S("> Creates ") .. stack:get_name()
			))
		else
			core.chat_send_player(name, core.colorize(
				"#ff4444",
				S("> Creates air")
			))
		end

		local dist = meta:get_int("distance") or 0

		core.chat_send_player(name, core.colorize(
			"#4444ff",
			S("> distance = @1", dist)
		))
	end,
})

core.register_node("mech:randomizer", {
	description = S("Randomizer"),
	tiles = {"randomizer.png"},
	groups = {node = 1, cracky = 2, trigger = 1},
	sounds = default.node_sound_metal_defaults(),
	after_dig_node = mech.after_dig,
	on_trigger = function(pos)
		local meta = core.get_meta(pos)
		local triggers = meta:get_string("triggers")
		if triggers == "" then
			triggers = update_trigger_list(pos)
		else
			triggers = core.deserialize(triggers) or {}
		end
		if #triggers > 0 then
			local i = rng(#triggers)
			local v = table.remove(triggers, i)
			meta:set_string("triggers", core.serialize(triggers))

			local untrigger = core.deserialize(meta:get_string("untrigger")) or {}
			untrigger[v] = true
			meta:set_string("untrigger", core.serialize(untrigger))
			meta:mark_as_private("untrigger")

			mech.send_trigger_to(vector.add(pos, dehash_vector(v)))
		end
	end,

	on_untrigger = function(pos)
		local meta = core.get_meta(pos)
		local untrigger = core.deserialize(meta:get_string("untrigger")) or {}
		for v in pairs(untrigger) do
			mech.send_untrigger_to(vector.add(pos, dehash_vector(v)))
		end
		meta:set_string("triggers", "")
		meta:set_string("untrigger", "")
	end,

	on_reveal = function(name, pos)
		local meta = core.get_meta(pos)
		local offsets = core.deserialize(meta:get_string("offsets")) or {}
		local untrigger = core.deserialize(meta:get_string("untrigger")) or {}

		local total, triggered = 0, 0
		for v in pairs(offsets) do
			total = total + 1
			if untrigger[v] then
				triggered = triggered + 1
			end
		end

		core.chat_send_player(name, core.colorize(
			"#88ff44", S("> triggered @1 of @2 connections", triggered, total)))
	end,
})

local function lamp_save_state(pos, node)
	local meta = core.get_meta(pos)
	meta:set_string("prev_name", node.name)
	meta:set_int("prev_param2", node.param2 or 0)
end

local function lamp_bar_off(pos)
	local meta = core.get_meta(pos)
	local node = core.get_node(pos)

	lamp_save_state(pos, node)

	node.name = "mech:lamp_bar_0"
	core.swap_node(pos, node)
end

local function lamp_bar_on(pos)
	local meta = core.get_meta(pos)
	local node = core.get_node(pos)

	local new_name = meta:get_string("prev_name")

	if new_name ~= "" then
		node.name = new_name
		node.param2 = meta:get_int("prev_param2")
		core.swap_node(pos, node)

		if string.find(new_name, "broken") then
			core.get_node_timer(pos):start(math.random(50) / 10)
		end
	end

	core.sound_play("lamp_on", {
		pos = pos,
		max_hear_distance = 16,
		gain = 0.2
	})
end

for _, v in ipairs({14, 11, 8, 0}) do
	local on_trigger, on_untrigger

	if v == 0 then
		on_trigger = lamp_bar_on
		on_untrigger = nil
	else
		on_trigger = function(pos) end
		on_untrigger = lamp_bar_off
	end

	core.register_node("mech:lamp_bar_" .. v, {
		description = S("Wall lamp (@1)", v),
		light_source = v,
		sunlight_propagates = true,
		tiles = {"lamp_bar.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		walkable = false,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {-1, 1/4, 1/4, 1, 1/2, 1/2},
		},
		groups = {node = 1, cracky = 2},
		sounds = default.node_sound_glass_defaults(),
		on_trigger = on_trigger,
		on_untrigger = on_untrigger,
		after_dig_node = mech.after_dig,
		on_rotate = screwdriver.rotate_simple,
	})
end

local function lamp_block_off(pos)
	local meta = core.get_meta(pos)
	local node = core.get_node(pos)

	lamp_save_state(pos, node)

	node.name = "mech:lamp_block_0"
	core.swap_node(pos, node)
end

local function lamp_block_on(pos)
	local meta = core.get_meta(pos)
	local node = core.get_node(pos)

	local new_name = meta:get_string("prev_name")

	if new_name ~= "" then
		node.name = new_name
		node.param2 = meta:get_int("prev_param2")
		core.swap_node(pos, node)
	end

	core.sound_play("lamp_on", {
		pos = pos,
		max_hear_distance = 16,
		gain = 0.2
	})
end

for _, v in ipairs({14, 11, 8, 0}) do
	local on_trigger, on_untrigger
	local tiles

	if v == 0 then
		on_trigger = lamp_block_on
		on_untrigger = nil
		tiles = {"lamp_block_off.png"}
	else
		on_trigger = function(pos) end
		on_untrigger = lamp_block_off
		tiles = {"lamp_block_on.png"}
	end

	core.register_node("mech:lamp_block_" .. v, {
		description = S("Lamp block (@1)", v),
		tiles = tiles,
		light_source = v,
		groups = {node = 1, cracky = 2},
		sounds = default.node_sound_glass_defaults(),
		on_trigger = on_trigger,
		on_untrigger = on_untrigger,
		after_dig_node = mech.after_dig,
	})
end