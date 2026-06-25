local function dehash_vector(s)
	return {
		x = 256 * string.byte(s, 1) + string.byte(s, 2) - 32768,
		y = 256 * string.byte(s, 3) + string.byte(s, 4) - 32768,
		z = 256 * string.byte(s, 5) + string.byte(s, 6) - 32768,
	}
end

local function particlestream(p, o, name)
	local d = vector.length(o)
	local c = 0
	while c < d - 0.5 do
		core.add_particle({
			texture = "glowblock.png",
			pos = vector.add(p, vector.multiply(o, c / d)),
			velocity = vector.divide(o, d * 3),
			expirationtime = 3,
			size = 2,
			glow = 14,
			playername = name,
		})
		c = c + 0.5
	end
end

core.register_tool("mech:reveal", {
	description = "Reveal tool".."\n"..
		"Reveal breakable nodes and placeholder nodes".."\n"..
		"Punch a node to see its connections",
	inventory_image = "reveal_tool.png",
	on_use = function(itemstack, digger, pointed_thing)
		if not digger then
			return
		end
		local name = digger:get_player_name()

		local off = {
			{ x = 0, y = 0, z = -9/16},
			{ x = 0, y = 0, z =  9/16},
			{ x = 0, y = -9/16, z = 0},
			{ x = 0, y =  9/16, z = 0},
			{ x = -9/16, y = 0, z = 0},
			{ x =  9/16, y = 0, z = 0},
		}

		if pointed_thing.under then
			local p = pointed_thing.under
			local meta = core.get_meta(p)
			local offsets = core.deserialize(meta:get_string("offsets")) or {}
			for v, _ in pairs(offsets) do
				local o = dehash_vector(v)
				particlestream(p, o, name)
			end
			local roffsets = core.deserialize(meta:get_string("roffsets")) or {}
			for v, _ in pairs(roffsets) do
				local o = dehash_vector(v)
				particlestream(vector.add(p, o), {x=-o.x, y=-o.y, z=-o.z}, name)
			end

			local dn = digger:get_player_name()

			local n = core.get_node(p)
			if n and n.name and core.registered_nodes[n.name] then
				local def = core.registered_nodes[n.name]
				core.chat_send_player(dn, core.colorize("#ff8888", "Detailed info for \"" .. def.description:gsub("\n.*", "") .. "\" at " .. core.pos_to_string(p) .. ":"))

				for so, _ in pairs(offsets) do
					local offs = dehash_vector(so)
					local npos = vector.add(p, offs)
					local nname = core.get_node(npos).name
					core.chat_send_player(dn, core.colorize("#44ff88", "> triggers " .. nname .. " at " .. core.pos_to_string(npos) ..  " (offset is " .. core.pos_to_string(offs) .. ")"))
				end

				for so, _ in pairs(roffsets) do
					local offs = dehash_vector(so)
					local npos = vector.add(p, offs)
					local nname = core.get_node(npos).name
					core.chat_send_player(dn, core.colorize("#8888ff", "> triggered by " .. nname .. " at " .. core.pos_to_string(npos) ..  " (offset is " .. core.pos_to_string(offs) .. ")"))
				end

				local cb = def.on_reveal
				if cb then
					cb(dn, p)
				end
			end
		end

		local limit = 32
		local ppos = vector.floor(digger:get_pos())
		local nodeslist = {}
		local needle = {"group:axe", "group:shovel", "group:pickaxe", "group:hand", "nodes:placeholder", "group:torch"}
		for d = 3, 6 do
			if limit > 0 then
				local poslist, _ = core.find_nodes_in_area(vector.subtract(ppos, d),
						vector.add(ppos, d),
						needle)

				for _, v in pairs(poslist) do
					if limit > 0 then
						nodeslist[core.pos_to_string(v)] = 1
						limit = limit - 1
					end
				end
			end
		end

		for k, _ in pairs(nodeslist) do
			local pos = core.string_to_pos(k)
			local node = core.get_node(pos)
			local groups = core.registered_nodes[node.name] and core.registered_nodes[node.name].groups

			local texture
			if groups.axe then
				texture = "axe.png"
			elseif groups.shovel then
				texture = "shovel.png"
			elseif groups.pickaxe then
				texture = "pickaxe.png"
			elseif groups.hand then
				texture = "wieldhand.png"
			end
			if texture and vector.distance(pos, digger:get_pos()) < 8 and
				node.name ~= "nodes:snow_ledge" then
				for _, v in ipairs(off) do
					core.add_particle({
						pos = vector.add(pos, v),
						expirationtime = 8,
						size = 3,
						texture = texture,
						playername = name,
						glow = 13,
					})
				end
			end

			if node.name == "nodes:placeholder" or node.name == "torches:torch" or node.name == "torches:torch_wall" then
				local meta = core.get_meta(pos)
				local placeable = meta:get_string("placeable")
				if placeable ~= "" then
					local nodelist = core.parse_json(placeable)
					local n, _ = next(nodelist)
					core.add_particle({
						pos = pos,
						expirationtime = 8,
						size = 3,
						texture = nodes.get_tiles(n),
						glow = 14,
						playername = name,
					})
				end
			end
		end

		return itemstack
	end,
})