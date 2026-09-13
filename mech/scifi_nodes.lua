-- scifi_nodes.lua
--
-- Les nodes que mech reprend du mod scifi_nodes de D00Med
-- (https://content.luanti.org/packages/D00Med/scifi_nodes/), enregistres ici
-- sous le prefixe mech: pour que mech n'ait plus besoin du mod complet.
-- Seule l'API de scifi_nodes reste utilisee lorsqu'elle est necessaire.
--
-- Les alias en fin de fichier convertissent automatiquement les blocs deja
-- poses dans le monde et les objets deja en inventaire : rien n'est perdu.
--
-- Textures et sons d'origine : scifi_nodes, licence CC BY-SA 3.0 (voir
-- license.txt du mod d'origine). Conserver ce credit en cas de redistribution.

-- scifi pot and pot2
core.register_node("mech:pot_lid", {
	description = "Plant Pot Lid",
	tiles = {
		"mech_glass2.png"
	},
	inventory_image = "mech_pod_inv.png",
	wield_image = "mech_pod_inv.png",
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
	if lid_node.name == "mech:pot_lid" then
		core.set_node(lid_pos, {name = "air"})
	elseif lid_node.name == "air" then
		core.set_node(lid_pos, {name = "mech:pot_lid"})
	end
end

local function remove_lid(pos)
	local lid_pos = {x = pos.x, y = pos.y+2 , z = pos.z}
	local lid_node = core.get_node(lid_pos)
	if lid_node.name == "mech:pot_lid" then
		core.set_node(lid_pos, {name = "air"})
	end
end

core.register_node("mech:pot", {
	description = "Metal Plant Pot (right-click for lid, sneak + right-click to plant)",
	tiles = {
		"mech_dirt.png^mech_pot.png",
		"mech_greybolts.png",
		"mech_greybolts.png",
		"mech_greybolts.png",
		"mech_greybolts.png",
		"mech_greybolts.png"
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

core.register_node("mech:pot2", {
	description = "Metal Plant Pot Wet (right-click for lid, sneak + right-click to plant)",
	tiles = {
		"mech_dirt.png^mech_pot2.png",
		"mech_greybolts.png",
		"mech_greybolts.png",
		"mech_greybolts.png",
		"mech_greybolts.png",
		"mech_greybolts.png"
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

-- scifi black sliding door
local closed = "mech:black_door_closed"
local closed_top = "mech:black_door_closed_top"
local opened = "mech:black_door_opened"
local opened_top = "mech:black_door_opened_top"
local base_name = "black"
local base_ingredient = "doors:door_steel"

core.register_craft({
	output = closed .. " 2",
	recipe = {
		{"mech:white2", base_ingredient, "mech:white2"},
		{"mech:black", base_ingredient, "mech:black"}
	}
})

local function onplace(itemstack, placer, pointed_thing)
		local pos1 = pointed_thing.above
		local pos2 = {x=pos1.x, y=pos1.y, z=pos1.z}
			  pos2.y = pos2.y+1

		if
		not core.registered_nodes[core.get_node(pos1).name].buildable_to or
		not core.registered_nodes[core.get_node(pos2).name].buildable_to or
		not placer or
		not placer:is_player() or
		core.is_protected(pos1, placer:get_player_name()) or
		core.is_protected(pos2, placer:get_player_name()) then
			return
		end

		local pt = pointed_thing.above
		local pt2 = {x=pt.x, y=pt.y, z=pt.z}
		pt2.y = pt2.y+1
		-- Player look dir is converted to node rotation ?
		local p2 = core.dir_to_facedir(placer:get_look_dir())
		-- Where to look for another door ?
		local pt3 = {x=pt.x, y=pt.y, z=pt.z}

		-- Door param2 depends of placer's look dir
		local p4 = 0
		if p2 == 0 then
			pt3.x = pt3.x-1
			p4 = 2
		elseif p2 == 1 then
			pt3.z = pt3.z+1
			p4 = 3
		elseif p2 == 2 then
			pt3.x = pt3.x+1
			p4 = 0
		elseif p2 == 3 then
			pt3.z = pt3.z-1
			p4 = 1
		end

		-- First door of a pair is already there
		if core.get_node(pt3).name == closed then
			core.set_node(pt, {name=closed, param2=p4,})
			core.set_node(pt2, {name=closed_top, param2=p4})
		--	Placed door is the first of a pair
		else
			core.set_node(pt, {name=closed, param2=p2,})
			core.set_node(pt2, {name=closed_top, param2=p2})
		end

		itemstack:take_item(1)
		return itemstack;
	end

local function afterdestruct(pos)
	core.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name="air"})
end

local function change_adjacent(target, pos, node)
	local target_opposite, target_top
	if target == opened then
		target_top = opened_top
		target_opposite = closed
	else
		target_top = closed_top
		target_opposite = opened
	end

	for offset = -1,1,2 do
		local x = pos.x
		local y = pos.y
		local z = pos.z

		if node.param2 % 2 == 0 then
			x = x + offset
		else
			z = z + offset
		end

		local adjacent = core.get_node({x=x, y=y, z=z})
		if adjacent.name == target_opposite then
			core.swap_node({x=x, y=y, z=z}, {name=target, param2 = adjacent.param2})
			core.swap_node({x=x, y=y+1, z=z}, {name=target_top, param2 = adjacent.param2})
		end
	end

end

local function open_door(pos, node, player, itemstack)
	-- play sound
	core.sound_play("mech_door_normal",{
		max_hear_distance = 16,
		pos = pos,
		gain = 1.0
	})

	local timer = core.get_node_timer(pos)

	core.swap_node(pos, {name=opened, param2=node.param2})
	core.swap_node({x=pos.x,y=pos.y+1,z=pos.z}, {name=opened_top, param2=node.param2})

	change_adjacent(opened, pos, node)

	timer:start(3)
end

local function afterplace(pos)
	local node = core.get_node(pos)
	core.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name=opened_top,param2=node.param2})
end

local function ontimer(pos)
	-- play sound
	core.sound_play("mech_door_normal",{
		max_hear_distance = 16,
		pos = pos,
		gain = 1.0
	})

	local node = core.get_node(pos)

	core.swap_node(pos, {name=closed, param2=node.param2})
	core.swap_node({x=pos.x,y=pos.y+1,z=pos.z}, {name=closed_top, param2=node.param2})

	change_adjacent(closed, pos, node)
end

local mesecons_doors_rules = {
	-- get signal from pressure plate
	{x=-1, y=0, z=0},
	{x=0,  y=0, z=1},
	{x=0,  y=0, z=-1},
	{x=1,  y=0, z=0},
	-- get signal from wall mounted button
	{x=-1, y=1, z=-1},
	{x=-1, y=1, z=1},
	{x=0, y=1, z=-1},
	{x=0, y=1, z=1},
	{x=1, y=1, z=-1},
	{x=1, y=1, z=1},
	{x=-1, y=1, z=0},
	{x=1, y=1, z=0},
}

local mesecons_doors_def = {
	effector = {
		action_on = open_door,
		rules = mesecons_doors_rules
	},
}

local function nodig()
	return false
end

local doors_rightclick = nil
doors_rightclick = open_door

core.register_node(closed, {
	description = "Black sliding door",
	inventory_image = "mech_door_"..base_name.."_inv.png",
	wield_image = "mech_door_"..base_name.."_inv.png",
	tiles = {
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_rbottom.png",
		"mech_door_"..base_name.."_bottom.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {
		cracky = 3,
		dig_generic = 3,
		mech_door = 1,
		door = 1
	},
	is_ground_content = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625}
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 1.5, 0.0625}
		}
	},
	_open = open_door,
	mesecons = mesecons_doors_def,
	on_place = onplace,
	after_destruct = afterdestruct,
	on_rightclick = doors_rightclick,
	sounds = default.node_sound_metal_defaults(),
})

core.register_node(closed_top, {
	tiles = {
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_rtop.png",
		"mech_door_"..base_name.."_top.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky = 1, dig_generic = 3, door = 1},
	is_ground_content = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625}
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0, 0, 0, 0, 0, 0},
		}
	},
	can_dig = nodig,
	sounds = default.node_sound_metal_defaults(),
})

core.register_node(opened, {
	tiles = {
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_rbottom0.png",
		"mech_door_"..base_name.."_bottom0.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	drop = closed,
	groups = {cracky = 1, dig_generic = 3, door = 2},
	is_ground_content = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, -0.25, 0.5, 0.0625},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, -0.25, 1.5, 0.0625},
		}
	},
	after_place_node = afterplace,
	after_destruct = afterdestruct,
	on_timer = ontimer,
	sounds = default.node_sound_metal_defaults(),
})

core.register_node(opened_top, {
	tiles = {
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_edge.png",
		"mech_door_"..base_name.."_rtopo.png",
		"mech_door_"..base_name.."_topo.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky = 1, dig_generic = 3, door = 2},
	is_ground_content = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.0625, -0.25, 0.5, 0.0625},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{0, 0, 0, 0, 0, 0},
		}
	},
	can_dig = nodig,
	sounds = default.node_sound_metal_defaults(),
})

-- scifi damaged black wall
core.register_craft({
    output = "mech:blackdmg",
    recipe = {
        {"mech:black"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_blackdmg.png"}
local node_def = {
		description = "Damaged black wall",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "none",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:blackdmg"
core.register_node(nodename , node_def)
local has_slats_mod = core.get_modpath("slats")
if has_slats_mod then
	slats.register_slat(
		"blackdmg",
		"mech:blackdmg",
		{cracky=1, dig_generic = 3},
		"mech_blackdmg.png^slats_slat_overlay.png^[makealpha:255,126,126",
		"Damaged black wall Slat",
		sounds
	)
end

-- scifi black wall
core.register_craft({
    output = "mech:black",
    recipe = {
        {"mech:white2", "dye:black"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_black.png"}
local node_def = {
		description = "black wall",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:black"
core.register_node(nodename , node_def)

-- scifi plastic
core.register_craft({
	output = "mech:white2 6",
	recipe = {
		{"homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting"},
		{"homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting"},
		{"homedecor:plastic_sheeting", "homedecor:plastic_sheeting", "homedecor:plastic_sheeting"}
	}
})

local sounds = default.node_sound_stone_defaults()
local tiles = {"mech_white2.png"}
local node_def = {
		description = "plastic",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:white2"
core.register_node(nodename , node_def)

-- scifi black tile 2
core.register_craft({
	output = "mech:blacktile2 4",
	recipe = {
        {"mech:black", "", "mech:black"},
		{"", "", ""},
        {"mech:black", "", "mech:black"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_blacktile2.png"}
local node_def = {
		description = "black tile 2",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "none",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:blacktile2"
core.register_node(nodename , node_def)

-- scifi dented metal block
core.register_craft({
	type = "cooking",
	output = "mech:dent",
	recipe = "mech:lighttop",
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_dent.png"}
local node_def = {
		description = "dented metal block",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:dent"
core.register_node(nodename , node_def)

-- scifi metal block
core.register_craft({
    output = "mech:lighttop 8",
    recipe = {
        {"mech:black", "mech:black", "mech:black"},
        {"mech:black", "default:steel_ingot", "mech:black"},
        {"mech:black", "mech:black", "mech:black"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_lighttop.png"}
local node_def = {
		description = "metal block",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:lighttop"
core.register_node(nodename , node_def)

-- scifi green metal wall
core.register_craft({
    output = "mech:greenmetal 6",
    recipe = {
        {"mech:white2", "dye:green", "mech:white2"},
        {"mech:white2", "mech:dent", "mech:white2"},
        {"mech:white2", "dye:green", "mech:white2"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_greenmetal.png"}
local node_def = {
		description = "green metal wall",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:greenmetal"
core.register_node(nodename , node_def)

-- scifi grey wall
core.register_craft({
    output = "mech:grey",
    recipe = {
        {"mech:white2", "dye:grey"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_grey.png"}
local node_def = {
		description = "grey wall",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:grey"
core.register_node(nodename , node_def)

-- scifi grey metal block
core.register_craft({
    output = "mech:grey_square 4",
    recipe = {
        {"mech:grey", "", "mech:grey"},
        {"", "mech:dent", ""},
        {"mech:grey", "", "mech:grey"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_grey_square.png"}
local node_def = {
		description = "grey metal block",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "none",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:grey_square"
core.register_node(nodename , node_def)

-- scifi green pipe
core.register_craft({
    output = "mech:grnpipe 6",
    recipe = {
        {"mech:greenmetal", "", "mech:greenmetal"},
        {"mech:greenmetal", "mech:vent2", "mech:greenmetal"},
        {"mech:greenmetal", "", "mech:greenmetal"}
    }
})

minetest.register_node("mech:grnpipe", {
	description = "green pipe",
	sunlight_propagates = false,
	tiles = {
		"mech_greenpipe_front.png",
		"mech_greenpipe_front.png",
		"mech_greenpipe_top.png",
		"mech_greenpipe_top.png",
		"mech_greenpipe_top.png",
		"mech_greenpipe_top.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=1, dig_generic = 3},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	on_place = core.rotate_node
})

-- scifi vent
core.register_craft({
    output = "mech:vent2 6",
    recipe = {
        {"mech:dent", "mech:dent", "mech:dent"},
        {"", "", ""},
        {"mech:dent", "mech:dent", "mech:dent"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_vent2.png"}
local node_def = {
		description = "vent",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:vent2"
core.register_node(nodename , node_def)

-- scifi metal ladder
core.register_craft({
    output = "mech:ladder 9",
    recipe = {
        {"mech:dent"}
    }
})

core.register_node("mech:ladder", {
	description = "Metal Ladder",
	tiles = {
		"mech_ladder.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, -0.45, 0.5, 0.5}
	},
	node_box = {
		type = "fixed",
		fixed = {
			{0.3125, -0.5, -0.4375, 0.4375, -0.375, -0.3125}, -- NodeBox12
			{-0.4375, -0.5, -0.4375, -0.3125, -0.375, -0.3125}, -- NodeBox13
			{-0.375, -0.375, -0.4375, 0.375, -0.3125, -0.3125}, -- NodeBox14
			{-0.375, -0.375, 0.3125, 0.375, -0.3125, 0.4375}, -- NodeBox18
			{-0.375, -0.375, 0.0625, 0.375, -0.3125, 0.1875}, -- NodeBox19
			{-0.375, -0.375, -0.1875, 0.375, -0.3125, -0.0625}, -- NodeBox20
			{-0.4375, -0.5, -0.1875, -0.3125, -0.375, -0.0625}, -- NodeBox21
			{-0.4375, -0.5, 0.0625, -0.3125, -0.375, 0.1875}, -- NodeBox22
			{-0.4375, -0.5, 0.3125, -0.3125, -0.375, 0.4375}, -- NodeBox23
			{0.3125, -0.5, 0.3125, 0.4375, -0.375, 0.4375}, -- NodeBox24
			{0.3125, -0.5, 0.0625, 0.4375, -0.375, 0.1875}, -- NodeBox25
			{0.3125, -0.5, -0.1875, 0.4375, -0.375, -0.0625}, -- NodeBox26
		},
	},
	sounds = default.node_sound_metal_defaults(),
	paramtype2 = "wallmounted",
	walkable = false,
	climbable = true,
	groups = {cracky=1, oddly_breakable_by_hand=1},
	is_ground_content = false,
})

-- scifi dark glass
core.register_craft({
    output = "mech:glass",
    recipe = {
        {"default:obsidian_glass", "dye:black"}
    }
})

core.register_node("mech:glass", {
	description = "dark glass",
	drawtype = "glasslike",
	sunlight_propagates = true,
	tiles = {
		"mech_glass.png"
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	groups = {cracky=1, dig_generic = 3},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults()
})

-- scifi ceiling light
core.register_craft({
    output = "mech:lightbar 8",
    recipe = {
        {"mech:white2", "default:meselamp", "mech:white2"}
    }
})

core.register_node("mech:lightbar", {
	description = "ceiling light",
	tiles = {
		"mech_white2.png",
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	light_source = core.LIGHT_MAX,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.125, -0.5, -0.5, 0.125, -0.375, 0.5}, -- NodeBox1
		}
	},
	selection_box = {
		type = "wallmounted",
		wallmounted = {
			{-0.125, -0.5, -0.5, 0.125, -0.375, 0.5}, -- NodeBox1
		}
	},
	groups = {cracky=1, dig_generic = 3},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults()
})

-- scifi grey wall bolts
core.register_craft({
    output = "mech:greybolts 6",
    recipe = {
        {"mech:grey_square", "mech:grey", "mech:grey_square"},
        {"mech:grey", "mech:grey", "mech:grey"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_greybolts.png"}
local node_def = {
		description = "grey wall bolts",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:greybolts"
core.register_node(nodename , node_def)

-- scifi rough metal
core.register_craft({
    output = "mech:rough",
    recipe = {
        {"mech:lighttop", "moreblocks:cobble_compressed"}
    }
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_rough.png"}
local node_def = {
		description = "rough metal",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:rough"
core.register_node(nodename , node_def)

-- scifi rusty metal
core.register_craft({
    output = "mech:rust",
    recipe = {
        {"mech:rough", "bucket:bucket_water"}
    },
    replacements = {{"bucket:bucket_water", "bucket:bucket_empty"}}
})

local sounds = default.node_sound_metal_defaults()
local tiles = {"mech_rust.png"}
local node_def = {
		description = "rusty metal",
		drawtype = "normal",
		sunlight_propagates = false,
		tiles = tiles,
		groups = {cracky=1, dig_generic = 3},
		is_ground_content = false,
		paramtype = "light",
		paramtype2 = "facedir",
		light_source = 0,
		sounds = sounds,
	}
local nodename = "mech:rust"
core.register_node(nodename , node_def)

-- scifi liquid pipe
core.register_craft({
    output = "mech:liquid_pipe 4",
    recipe = {
        {"", "dye:green", ""},
        {"mech:glass", "mech:light_dynamic", "mech:glass"},
        {"", "dye:green", ""}
    }
})

core.register_node("mech:liquid_pipe", {
	description = "Liquid pipe",
	tiles = {{
		name = "mech_liquid.png",
		animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1.00},
	}},
	use_texture_alpha = "blend",
	light_source = core.LIGHT_MAX,
	drawtype = "nodebox",
	sunlight_propagates = true,
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}, -- NodeBox1
		}
	},
	groups = {cracky=1, oddly_breakable_by_hand=1, dig_generic = 3},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults()
})

-- scifi wall light
core.register_craft({
    output = "mech:light_dynamic",
    recipe = {
        {"mech:lightbar", "mech:lightbar"}
    }
})

core.register_node("mech:light_dynamic", {
	description = "Wall light",
	tiles = {
		"mech_lightoverlay.png",
	},
	inventory_image = "mech_lightoverlay.png",
	wield_image = "mech_lightoverlay.png",
	drawtype = "signlike",
	paramtype = "light",
	selection_box = {
		type = "wallmounted",
		fixed = {-0.5, -0.5, -0.5, -0.45, 0.5, 0.5}
	},
	node_box = {
		type = "fixed",
		fixed = {
			fixed = {-0.5, -0.5, -0.5, -0.45, 0.5, 0.5}
		}
	},
	paramtype2 = "wallmounted",
	light_source = core.LIGHT_MAX,
	groups = {cracky=1, oddly_breakable_by_hand=1},
	is_ground_content = false,
	sounds = default.node_sound_glass_defaults()
})

-- scifi alien wall pipe
core.register_craft({
    output = "mech:wallpipe 3",
    recipe = {
        {"default:papyrus","mech:grnpipe", "mech:liquid_pipe"}
    }
})

core.register_node("mech:wallpipe", {
	description = "Alien wall pipe",
	tiles = {
		"mech_wallpipe.png",
		"mech_wallpipe.png",
		"mech_wallpipe.png",
		"mech_wallpipe.png",
		"mech_wallpipe.png",
		"mech_wallpipe.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=1, dig_generic = 3},
	is_ground_content = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, 0.125, 0.5, 0.5, 0.5}, -- NodeBox18
			{-0.1875, -0.5, -0.0625, 0.1875, 0.5, 0.125}, -- NodeBox19
			{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}, -- NodeBox20
			{0.3125, -0.5, 0.0625, 0.4375, 0.5, 0.125}, -- NodeBox21
			{-0.4375, -0.5, 0.0625, -0.3125, 0.5, 0.125}, -- NodeBox22
			{-0.5, 0.0625, 0, 0.5, 0.1875, 0.0625}, -- NodeBox23
			{-0.5, -0.125, 0, 0.5, 0, 0.0625}, -- NodeBox24
		}
	},
	sounds = default.node_sound_wood_defaults()
})

if core.get_modpath("signs_api") then
	signs_api.register_sign("scifi_nodes", "black_banner", {
		depth = 1/16,
		width = 5,
		height = 1,
		entity_fields = {
			maxlines = 1,
			color = "#fff",
		},
		node_fields = {
			visual_scale = 1,
			description = "black banner",
			tiles = tiles,
			inventory_image = "mech_black.png",
			use_texture_alpha = "clip",
		},
	})
	signs_api.register_sign("scifi_nodes", "bluemetal_banner", {
		depth = 1/16,
		width = 5,
		height = 1,
		entity_fields = {
			maxlines = 1,
			color = "#fff",
		},
		node_fields = {
			visual_scale = 1,
			description = "bluemetal banner",
			tiles = tiles,
			inventory_image = "mech_bluemetal.png",
			use_texture_alpha = "clip",
		},
	})
	signs_api.register_sign("scifi_nodes", "greenmetal_banner", {
		depth = 1/16,
		width = 5,
		height = 1,
		entity_fields = {
			maxlines = 1,
			color = "#fff",
		},
		node_fields = {
			visual_scale = 1,
			description = "greenmetal banner",
			tiles = tiles,
			inventory_image = "mech_greenmetal.png",
			use_texture_alpha = "clip",
		},
	})
	signs_api.register_sign("scifi_nodes", "grey_banner", {
		depth = 1/16,
		width = 5,
		height = 1,
		entity_fields = {
			maxlines = 1,
			color = "#fff",
		},
		node_fields = {
			visual_scale = 1,
			description = "grey banner",
			tiles = tiles,
			inventory_image = "mech_grey.png",
			use_texture_alpha = "clip",
		},
	})
	signs_api.register_sign("scifi_nodes", "purple_banner", {
		depth = 1/16,
		width = 5,
		height = 1,
		entity_fields = {
			maxlines = 1,
			color = "#fff",
		},
		node_fields = {
			visual_scale = 1,
			description = "purple banner",
			tiles = tiles,
			inventory_image = "mech_purple.png",
			use_texture_alpha = "clip",
		},
	})
	signs_api.register_sign("scifi_nodes", "white2_banner", {
		depth = 1/16,
		width = 5,
		height = 1,
		entity_fields = {
			maxlines = 1,
			color = "#fff",
		},
		node_fields = {
			visual_scale = 1,
			description = "white2 banner",
			tiles = tiles,
			inventory_image = "mech_white2.png",
			use_texture_alpha = "clip",
		},
	})
end


-- Conversion des anciens noms scifi_nodes: vers mech:
core.register_alias("scifi_nodes:pot_lid", "mech:pot_lid")
core.register_alias("scifi_nodes:pot", "mech:pot")
core.register_alias("scifi_nodes:pot2", "mech:pot2")
core.register_alias("scifi_nodes:black_door_closed", "mech:black_door_closed")
core.register_alias("scifi_nodes:black_door_closed_top", "mech:black_door_closed_top")
core.register_alias("scifi_nodes:black_door_opened", "mech:black_door_opened")
core.register_alias("scifi_nodes:black_door_opened_top", "mech:black_door_opened_top")
core.register_alias("scifi_nodes:blackdmg", "mech:blackdmg")
core.register_alias("scifi_nodes:black", "mech:black")
core.register_alias("scifi_nodes:white2", "mech:white2")
core.register_alias("scifi_nodes:blacktile2", "mech:blacktile2")
core.register_alias("scifi_nodes:dent", "mech:dent")
core.register_alias("scifi_nodes:lighttop", "mech:lighttop")
core.register_alias("scifi_nodes:greenmetal", "mech:greenmetal")
core.register_alias("scifi_nodes:grey", "mech:grey")
core.register_alias("scifi_nodes:grey_square", "mech:grey_square")
core.register_alias("scifi_nodes:grnpipe", "mech:grnpipe")
core.register_alias("scifi_nodes:vent2", "mech:vent2")
core.register_alias("scifi_nodes:ladder", "mech:ladder")
core.register_alias("scifi_nodes:glass", "mech:glass")
core.register_alias("scifi_nodes:lightbar", "mech:lightbar")
core.register_alias("scifi_nodes:greybolts", "mech:greybolts")
core.register_alias("scifi_nodes:rough", "mech:rough")
core.register_alias("scifi_nodes:rust", "mech:rust")
core.register_alias("scifi_nodes:liquid_pipe", "mech:liquid_pipe")
core.register_alias("scifi_nodes:light_dynamic", "mech:light_dynamic")
core.register_alias("scifi_nodes:wallpipe", "mech:wallpipe")
