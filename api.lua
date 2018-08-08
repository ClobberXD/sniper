sniper = {}
sniper.rifles = {}   -- Stores the rifle definition tables
local scope_hud = {} -- Stores the ID of the scope overlay HUD element
local hud_flags = {} -- Stores the player's HUD flags before disabling them
local interval = {}  -- Interval between each shot, depends on rifle's fire-rate
local base_dmg = 6   -- Base damage, used for calculating damage dealt

minetest.register_on_joinplayer(function(player)
	scope_hud[player:get_player_name()] = nil
end)

minetest.register_on_wielditem_change(function(player, old, new)
	hide_scope(player)
end)

-- Show scope
function show_scope(player, fov, style)
	if not player then
		return
	end

	local name = player:get_player_name()

	-- Disable all default HUD elements
	hud_flags[name] = player:hud_get_flags()
	player:hud_set_flags({
		hotbar    = false,
		healthbar = false,
		breathbar = false,
		crosshair = false,
		wielditem = false
	})

	player:set_fov(fov)

	scope_hud[name] = player:hud_add({
		hud_elem_type = "image",
		scale = {x = -100, y = -100},
		position = {x = 0.5, y = 0.5},
		alignment = {x = 0, y = 0},
		text = "sniper_scope_style_" .. style .. ".png"
	})
end

-- Hide scope
function hide_scope(player)
	local name = player:get_player_name()
	player:clear_fov()
	player:hud_remove(scope_hud[name])
	player:hud_set_flags(hud_flags[name])
	scope_hud[name] = nil
end

-- Handle a left-click
function left_click(itemstack, player, pointed_thing)
	local name = player:get_player_name()
	local rifle = sniper.rifles[itemstack:get_name()]

	-- Return if player isn't viewing through the scope
	if not scope_hud[name] then
		return
	end

	-- Return if player fires before interval expires
	if interval[name] and os.time() < interval[name] then
		return
	end

	-- Fire!

	-- Calculate and set damage dealt
	local damage = math.floor(base_dmg * rifle.damage_mult)
	-- target:set_hp(damage)

	-- Simulate recoil, intensity depends on rifle.stab_mult
	local recoil = 0.05 * rifle.stab_mult
	player:set_look_vertical(player:get_look_vertical() - recoil)

	-- Set interval, depends on fire_rate
	-- If fire_rate == 2 shots/sec, interval = os.time() + 0.5s
	interval[name] = os.time() + (1 / rifle.fire_rate)

	-- Play shot-fired sound
	minetest.sound_play("sniper_shoot", {to_player = name})

	return itemstack
end

-- Handle a right-click
function right_click(itemstack, player, pointed_thing)
	local name = player:get_player_name()
	local rifle = sniper.rifles[itemstack:get_name()]

	-- Play a click sound for indicating scope toggle
	minetest.sound_play("sniper_scope_toggle", {to_player = name})

	-- Check if player is looking through the scope
	if not scope_hud[name] then
		local speed_mult = 0.2 + (1 - rifle.stab_mult)
		player:set_physics_override({
			speed = speed_mult,
			jump = 0,
			sneak = false
		})
		show_scope(player, rifle.scope_fov, rifle.scope_style)
	else
		player:set_physics_override({
			speed = 1,
			jump = 1,
			sneak = true
		})
		hide_scope(player)
	end

	return itemstack
end

-- Verify of given rifle definition table
function verify_def(def)
	-- Check for missing fields
	def.display_name = def.display_name and def.display_name
		or "Sniper Rifle #" .. (#sniper.rifles + 1)
	def.scope_fov   = def.scope_fov and def.scope_fov or 60
	def.scope_style = def.scope_style and def.scope_style or 1
	def.damage_mult = def.damage_mult and def.damage_mult or 1.0
	def.stab_mult   = def.stab_mult and def.stab_mult or 1.0
	def.fire_rate   = def.fire_rate and def.fire_rate or 1.0

	-- Check for invalid field values
	def.scope_fov = (def.scope_fov >= 20 and def.scope_fov <= 80)
						and def.scope_fov or 60
	def.scope_style = (def.scope_style >= 1 and def.scope_style <= 4)
						and def.scope_style or 1
	def.damage_mult = (def.damage_mult >= 0.1 and def.damage_mult <= 5)
						and def.damage_mult or 1.0
	def.stab_mult = (def.stab_mult >= 0.1 and def.stab_mult <= 5)
						and def.stab_mult or 1.0
	def.fire_rate = (def.fire_rate >= 0.5 and def.fire_rate <=5)
						and def.fire_rate or 1.0
	return def
end

-- Register rifle
function sniper.register_rifle(name, def)
	if sniper.rifles[name] then
		minetest.log("warning",
			"[sniper] Attempting to register new rifle with pre-existing name")
		return
	end

	sniper.rifles[name] = verify_def(def)

	minetest.register_tool(name, {
		description = def.display_name,
		inventory_image = def.inventory_image,
		wield_image = def.wield_image,
		stack_max = 1,
		range = 0.0,

		on_use = left_click,
		on_secondary_use = right_click
	})
end
