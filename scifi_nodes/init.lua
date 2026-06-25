-- scifi pot and pot2

minetest.register_node("scifi_nodes:pot_lid", {
	description = "Plant Pot Lid",
	tiles = {
		"scifi_nodes_glass2.png"
	},
	inventory_image = "scifi_nodes_pod_inv.png",
	wield_image = "scifi_nodes_pod_inv.png",
	use_texture_alpha = "blend",
	drawtype = "nodebox",
	paramtype = "light",
	groups = {not_in_creative_inventory = 1},
	is_ground_content = false,
	sunlight_propagates = true,
	diggable = false,
	drop = "",
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -1.5, -0.5, 0.5, -0.25, 0.5}
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -1.5, -0.4375, 0.4375, -0.5, -0.375},
			{-0.4375, -1.5, 0.375, 0.4375, -0.5, 0.4375},
			{-0.4375, -1.5, -0.375, -0.375, -0.5, 0.375},
			{0.375, -1.5, -0.375, 0.4375, -0.5, 0.375},
			{-0.375, -0.5, -0.375, 0.375, -0.4375, 0.375},
			{-0.3125, -0.4375, -0.3125, 0.3125, -0.375, 0.3125},
			{-0.25, -0.375, -0.25, 0.25, -0.3125, 0.25},
			{-0.1875, -0.3125, -0.1875, 0.1875, -0.25, 0.1875}
		}
	},
	sounds = default.node_sound_glass_defaults()
})

local function toggle_lid(pos, node, player, itemstack)
	if not player or core.is_protected(pos, player:get_player_name()) then
		return
	end
	local lid_pos = {x = pos.x, y = pos.y+2 , z = pos.z}
	local lid_node = core.get_node(lid_pos)
	if lid_node.name == "scifi_nodes:pot_lid" then
		core.set_node(lid_pos, {name = "air"})
	elseif lid_node.name == "air" then
		core.set_node(lid_pos, {name = "scifi_nodes:pot_lid"})
	end
end

local function remove_lid(pos)
	local lid_pos = {x = pos.x, y = pos.y+2 , z = pos.z}
	local lid_node = core.get_node(lid_pos)
	if lid_node.name == "scifi_nodes:pot_lid" then
		core.set_node(lid_pos, {name = "air"})
	end
end

minetest.register_node("scifi_nodes:pot", {
	description = "Metal Plant Pot (right-click for lid, sneak + right-click to plant)",
	tiles = {
		"scifi_nodes_dirt.png^scifi_nodes_pot.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	groups = {cracky = 1, soil = 1, sand = 1, dig_generic = 3},
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.25, -0.5, 0.5, 0.5, 0.5},
			{0.1875, -0.5, 0.1875, 0.5, -0.25, 0.5},
			{-0.5, -0.5, -0.5, -0.1875, -0.25, -0.1875},
			{-0.5, -0.5, 0.1875, -0.1875, -0.25, 0.5},
			{0.1875, -0.5, -0.5, 0.5, -0.25, -0.1875}
		}
	},
	on_rightclick = toggle_lid,
	on_destruct = remove_lid,
	sounds = default.node_sound_metal_defaults()
})

minetest.register_node("scifi_nodes:pot2", {
	description = "Metal Plant Pot Wet (right-click for lid, sneak + right-click to plant)",
	tiles = {
		"scifi_nodes_dirt.png^scifi_nodes_pot2.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png",
		"scifi_nodes_greybolts.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	groups = {cracky = 1, soil = 3, wet = 1, dig_generic = 3},
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.25, -0.5, 0.5, 0.5, 0.5},
			{0.1875, -0.5, 0.1875, 0.5, -0.25, 0.5},
			{-0.5, -0.5, -0.5, -0.1875, -0.25, -0.1875},
			{-0.5, -0.5, 0.1875, -0.1875, -0.25, 0.5},
			{0.1875, -0.5, -0.5, 0.5, -0.25, -0.1875}
		}
	},
	on_rightclick = toggle_lid,
	on_destruct = remove_lid,
	sounds = default.node_sound_metal_defaults()
})