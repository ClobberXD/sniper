dofile(minetest.get_modpath("sniper") .. "/api.lua")

sniper.register_rifle("sniper:builtin_1", {
	display_name = "Basic Trainer",
	inventory_image = "sniper_builtin_trainer.png",
	wield_image = "sniper_builtin_trainer.png^[transformFYR180",
	scope_style = 1
})
