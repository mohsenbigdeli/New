extends "res://scripts/main_v08.gd"

var fishing_panel: FarmFishingPanel
var mine_interior: FarmMineInterior
var mining: FarmMiningSystem
var landmarks: FarmAdventureLandmarks
var crafting_panel: FarmCraftingPanel
var reel_upgraded := false

const MINE_RETURN := Vector2(1900,1390)
const KITCHEN_WORKBENCH := Vector2(1045,210)

func _ready() -> void:
	super()

	for key in ["fish","stone","copper","bait"]:
		produce_inventory[key] = int(produce_inventory.get(key,0))
		shipping_pending[key] = int(shipping_pending.get(key,0))
		storage_inventory[key] = int(storage_inventory.get(key,0))
	sell_prices["fish"] = 120
	sell_prices["stone"] = 8
	sell_prices["copper"] = 70
	sell_prices["bait"] = 6

	landmarks = FarmAdventureLandmarks.new()
	landmarks.name = "AdventureLandmarks"
	add_child(landmarks)

	mine_interior = FarmMineInterior.new()
	mine_interior.name = "MineInterior"
	add_child(mine_interior)

	mining = FarmMiningSystem.new()
	mining.name = "MiningSystem"
	add_child(mining)
	mining.set_active(false)

	fishing_panel = FarmFishingPanel.new()
	fishing_panel.name = "FishingPanel"
	add_child(fishing_panel)
	fishing_panel.open_state_changed.connect(_on_fishing_panel_state_changed)
	fishing_panel.fishing_finished.connect(_on_fishing_finished)

	crafting_panel = FarmCraftingPanel.new()
	crafting_panel.name = "CraftingPanel"
	add_child(crafting_panel)
	crafting_panel.open_state_changed.connect(_on_crafting_panel_state_changed)
	crafting_panel.craft_requested.connect(_on_craft_requested)

	landmarks.set_active(interiors.active_room == "outside")
	inventory_ui.refresh_data(_bag_snapshot(),storage_inventory)
	ui.show_message("v0.9: Fishing, the old mine and kitchen crafting are now open. Fish, mine Stone/Copper, and upgrade your reel.")

func _get_near_interaction() -> Dictionary:
	if interiors.active_room == "mine":
		var rock_interaction := mining.get_interaction(player.position)
		if not rock_interaction.is_empty():
			return rock_interaction
		return mine_interior.get_interaction(player.position)

	if interiors.active_room == "home" and player.position.distance_to(KITCHEN_WORKBENCH) < 82.0:
		return {"type":"crafting_bench", "name":"Kitchen Workbench"}

	if interiors.active_room == "outside":
		if player.position.distance_to(FarmAdventureLandmarks.MINE_ENTRANCE) < 118.0:
			return {"type":"mine_entry", "name":"Enter Old Mine"}
		if player.position.distance_to(FarmAdventureLandmarks.POND_FISH_SPOT) < 105.0:
			return {"type":"fishing_spot", "name":"Fish at Pond", "spot":"pond"}
		if player.position.distance_to(FarmAdventureLandmarks.RIVER_FISH_SPOT) < 105.0:
			return {"type":"fishing_spot", "name":"Fish at River", "spot":"river"}

	return super._get_near_interaction()

func _handle_interaction(data: Dictionary) -> void:
	var kind := String(data.get("type",""))
	match kind:
		"mine_entry":
			_enter_interior("mine")
		"mine_exit":
			_exit_interior()
		"mine_sign":
			ui.show_message("Miner's note: Rocks return each morning. Copper veins are uncommon but valuable at the workbench.")
		"mine_rock":
			_break_mine_rock(int(data.get("index",-1)))
		"fishing_spot":
			_start_fishing(String(data.get("spot","pond")))
		"crafting_bench":
			_open_crafting_panel()
		_:
			super._handle_interaction(data)

func _enter_interior(room: String) -> void:
	if room != "mine":
		super._enter_interior(room)
		return
	inventory_ui.close_panel()
	ui.close_shop()
	if animal_panel and animal_panel.is_open:
		animal_panel.close_panel()
	if crafting_panel and crafting_panel.is_open:
		crafting_panel.close_panel()
	outside_return_position = MINE_RETURN
	_set_room_state("mine")
	player.position = FarmMineInterior.SPAWN
	player.facing = Vector2.UP
	ui.show_message("Entered the Old Mine. Break rocks for Stone and Copper Ore.")

func _set_room_state(room: String) -> void:
	if room != "mine":
		if mine_interior:
			mine_interior.set_active(false)
		if mining:
			mining.set_active(false)
		super._set_room_state(room)
		if landmarks:
			landmarks.set_active(room == "outside")
		return

	interiors.active_room = "mine"
	interiors.visible = false
	if barn_interior:
		barn_interior.visible = false
	if animals:
		animals.set_active(false)
	mine_interior.set_active(true)
	mining.set_active(true)
	farm.visible = false
	storage_chest.visible = false
	ambient_fx.visible = false
	focus_overlay.visible = false
	if landmarks:
		landmarks.set_active(false)
	_set_farm_collision_enabled(false)
	player.set_world_bounds(FarmMineInterior.ROOM_SIZE,1.04)

func _break_mine_rock(index: int) -> void:
	if energy < 3:
		ui.show_message("Not enough energy to swing the pickaxe. Sleep or return tomorrow.")
		return
	var result := mining.break_rock(index)
	if result.is_empty():
		return
	var stone := int(result.get("stone",0))
	var copper := int(result.get("copper",0))
	produce_inventory["stone"] = int(produce_inventory.get("stone",0)) + stone
	produce_inventory["copper"] = int(produce_inventory.get("copper",0)) + copper
	energy = maxi(0,energy-3)
	if copper > 0:
		ui.show_message("Rock broken: +%d Stone, +%d Copper Ore. Energy -3." % [stone,copper])
	else:
		ui.show_message("Rock broken: +%d Stone. Energy -3." % stone)
	inventory_ui.refresh_data(_bag_snapshot(),storage_inventory)
	_update_ui()

func _start_fishing(spot: String) -> void:
	if energy < 2:
		ui.show_message("You're too tired to fish. Rest first.")
		return
	var use_bait := int(produce_inventory.get("bait",0)) > 0
	inventory_ui.close_panel()
	inventory_ui.bag_button.disabled = true
	player.set_controls_locked(true)
	fishing_panel.start_fishing(use_bait,farm.weather,minute_of_day,reel_upgraded)
	if spot == "river":
		ui.show_message("You cast into the river...")
	else:
		ui.show_message("You cast into the pond...")

func _on_fishing_panel_state_changed(open: bool) -> void:
	inventory_ui.bag_button.disabled = open or ui.shop_open
	if not ui.shop_open and not inventory_ui.is_open:
		player.set_controls_locked(open)
	if not open:
		player.set_virtual_move(Vector2.ZERO)

func _on_fishing_finished(success: bool, bait_was_used: bool) -> void:
	if bait_was_used:
		produce_inventory["bait"] = maxi(0,int(produce_inventory.get("bait",0))-1)
	energy = maxi(0,energy-2)
	if not success:
		ui.show_message("The fish escaped. Energy -2%s." % (" · 1 bait used" if bait_was_used else ""))
		inventory_ui.refresh_data(_bag_snapshot(),storage_inventory)
		_update_ui()
		return

	var species := "Carp"
	var bonus_fish := 0
	var roll := randi() % 100
	if farm.weather == "Rain" and roll < 30:
		species = "Catfish"
		bonus_fish = 1 if roll < 10 else 0
	elif minute_of_day >= 18*60 and roll < 40:
		species = "River Bass"
	elif roll < 45:
		species = "Sunfish"
	produce_inventory["fish"] = int(produce_inventory.get("fish",0)) + 1 + bonus_fish
	ui.show_message("Caught %s%s! +%d Fish to your bag. Energy -2." % [species," with a bonus catch" if bonus_fish > 0 else "",1+bonus_fish])
	inventory_ui.refresh_data(_bag_snapshot(),storage_inventory)
	_update_ui()

func _open_crafting_panel() -> void:
	inventory_ui.close_panel()
	inventory_ui.bag_button.disabled = true
	player.set_controls_locked(true)
	crafting_panel.open_panel(_bag_snapshot(),reel_upgraded,animals.feed_stock)

func _on_crafting_panel_state_changed(open: bool) -> void:
	inventory_ui.bag_button.disabled = open or ui.shop_open
	if not ui.shop_open and not inventory_ui.is_open:
		player.set_controls_locked(open)
	if not open:
		player.set_virtual_move(Vector2.ZERO)

func _on_craft_requested(recipe: String) -> void:
	match recipe:
		"bait":
			if int(produce_inventory.get("carrot",0)) < 1 or int(produce_inventory.get("corn",0)) < 1:
				ui.show_message("Need 1 Carrot + 1 Corn to craft 5 Bait.")
				return
			produce_inventory["carrot"] = int(produce_inventory["carrot"]) - 1
			produce_inventory["corn"] = int(produce_inventory["corn"]) - 1
			produce_inventory["bait"] = int(produce_inventory.get("bait",0)) + 5
			ui.show_message("Crafted 5 Fishing Bait.")
		"feed":
			if int(produce_inventory.get("corn",0)) < 2:
				ui.show_message("Need 2 Corn to mix 5 Animal Feed.")
				return
			produce_inventory["corn"] = int(produce_inventory["corn"]) - 2
			animals.feed_stock += 5
			ui.show_message("Mixed 5 Animal Feed. Barn feed stock: %d." % animals.feed_stock)
		"reel_upgrade":
			if reel_upgraded:
				ui.show_message("The Copper Reel upgrade is already installed.")
				return
			if int(produce_inventory.get("stone",0)) < 12 or int(produce_inventory.get("copper",0)) < 5:
				ui.show_message("Need 12 Stone + 5 Copper Ore for the Copper Reel upgrade.")
				return
			produce_inventory["stone"] = int(produce_inventory["stone"]) - 12
			produce_inventory["copper"] = int(produce_inventory["copper"]) - 5
			reel_upgraded = true
			ui.show_message("Copper Reel installed! Fishing timing is permanently easier.")
		_:
			return
	crafting_panel.refresh(_bag_snapshot(),reel_upgraded,animals.feed_stock)
	inventory_ui.refresh_data(_bag_snapshot(),storage_inventory)
	if animal_panel:
		animal_panel.refresh(animals.summary_text())
	_update_ui()

func _start_next_day(from_midnight: bool) -> void:
	if mining:
		mining.next_day()
	super._start_next_day(from_midnight)

func _bag_snapshot() -> Dictionary:
	var bag := super._bag_snapshot()
	for key in ["fish","stone","copper","bait"]:
		bag[key] = int(produce_inventory.get(key,0))
	return bag

func _bag_item_count(item_key: String) -> int:
	if item_key in ["fish","stone","copper","bait"]:
		return int(produce_inventory.get(item_key,0))
	return super._bag_item_count(item_key)

func _set_bag_item_count(item_key: String, value: int) -> void:
	if item_key in ["fish","stone","copper","bait"]:
		produce_inventory[item_key] = maxi(0,value)
		return
	super._set_bag_item_count(item_key,value)

func save_game() -> void:
	super.save_game()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	parsed["save_version"] = 9
	parsed["mining_state"] = mining.get_save_data()
	parsed["reel_upgraded"] = reel_upgraded
	parsed["room"] = interiors.active_room
	parsed["player_x"] = player.position.x
	parsed["player_y"] = player.position.y
	var out := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(parsed))
		ui.show_message("Game saved with fishing, mine and crafting progress.")

func load_game() -> void:
	super.load_game()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	for key in ["fish","stone","copper","bait"]:
		produce_inventory[key] = int(produce_inventory.get(key,0))
		shipping_pending[key] = int(shipping_pending.get(key,0))
		storage_inventory[key] = int(storage_inventory.get(key,0))
	sell_prices["fish"] = 120
	sell_prices["stone"] = 8
	sell_prices["copper"] = 70
	sell_prices["bait"] = 6

	mining.load_save_data(parsed.get("mining_state",{}))
	reel_upgraded = bool(parsed.get("reel_upgraded",false))
	var saved_room := String(parsed.get("room","outside"))
	if saved_room == "mine":
		_set_room_state("mine")
		player.position = Vector2(float(parsed.get("player_x",FarmMineInterior.SPAWN.x)),float(parsed.get("player_y",FarmMineInterior.SPAWN.y)))
	else:
		mine_interior.set_active(false)
		mining.set_active(false)
		landmarks.set_active(saved_room == "outside")
	inventory_ui.refresh_data(_bag_snapshot(),storage_inventory)
	crafting_panel.refresh(_bag_snapshot(),reel_upgraded,animals.feed_stock)
	ui.show_message("Game loaded. Fishing, mine resources and Copper Reel progress restored.")
	_update_ui()
