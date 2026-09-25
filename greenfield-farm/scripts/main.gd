extends Node2D

const SAVE_PATH := "user://greenfield_save_v02.json"
const SEASONS := ["Spring", "Summer", "Fall", "Winter"]

var farm: FarmWorld
var player: FarmPlayer
var ui: GameUI
var ambient_fx: FarmAmbientFX
var focus_overlay: FarmFocusOverlay
var storage_chest: FarmStorageChest
var inventory_ui: FarmInventoryPanel

var selected_tool := 0
var energy := 100
var money := 350
var minute_of_day := 6 * 60
var clock_accumulator := 0.0
var minute_step_seconds := 0.75
var warned_late := false

var seed_inventory := {"turnip": 8, "carrot": 4, "corn": 2}
var produce_inventory := {"turnip": 0, "carrot": 0, "corn": 0}
var shipping_pending := {"turnip": 0, "carrot": 0, "corn": 0}
var storage_inventory := {
	"seed_turnip": 0,
	"seed_carrot": 0,
	"seed_corn": 0,
	"turnip": 0,
	"carrot": 0,
	"corn": 0
}
var seed_prices := {"turnip": 20, "carrot": 35, "corn": 60}
var sell_prices := {"turnip": 55, "carrot": 80, "corn": 130}

# Quest chain:
# 0 talk Rowan, 1 harvest turnips, 2 talk Lina,
# 3 harvest carrots, 4 talk Marnie, 5 harvest corn, 6 complete.
var quest_stage := 0
var quest_progress := 0

func _ready() -> void:
	randomize()
	farm = FarmWorld.new()
	farm.name = "FarmWorld"
	add_child(farm)

	ambient_fx = FarmAmbientFX.new()
	ambient_fx.name = "AmbientFX"
	add_child(ambient_fx)

	focus_overlay = FarmFocusOverlay.new()
	focus_overlay.name = "FocusOverlay"
	add_child(focus_overlay)

	storage_chest = FarmStorageChest.new()
	storage_chest.name = "StorageChest"
	add_child(storage_chest)

	player = FarmPlayer.new()
	player.name = "Player"
	player.position = Vector2(370, 420)
	player.world_size = FarmWorld.WORLD_SIZE
	add_child(player)
	player.action_requested.connect(_on_player_action)
	player.set_equipped_tool(selected_tool)

	ui = GameUI.new()
	ui.name = "GameUI"
	add_child(ui)
	ui.tool_selected.connect(_select_tool)
	ui.action_pressed.connect(player.request_action)
	ui.move_changed.connect(player.set_virtual_move)
	ui.save_pressed.connect(save_game)
	ui.load_pressed.connect(load_game)
	ui.buy_seed_pressed.connect(_buy_seed)
	ui.sell_all_pressed.connect(_sell_all_produce)
	ui.close_shop_pressed.connect(_close_shop)

	inventory_ui = FarmInventoryPanel.new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)
	inventory_ui.open_state_changed.connect(_on_inventory_open_changed)
	inventory_ui.transfer_requested.connect(_on_inventory_transfer)
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)

	ambient_fx.update_environment(farm.current_day, farm.weather, minute_of_day)
	ui.show_message("Welcome to Greenfield. Your BAG is ready, and a storage chest sits beside the farmhouse.")
	_update_ui()

func _process(delta: float) -> void:
	if not ui.shop_open and not inventory_ui.is_open:
		clock_accumulator += delta
		if clock_accumulator >= minute_step_seconds:
			clock_accumulator -= minute_step_seconds
			minute_of_day += 10
			if minute_of_day >= 22 * 60 and not warned_late:
				warned_late = true
				ui.show_message("It's getting late. Head home before midnight.")
			if minute_of_day >= 24 * 60:
				_start_next_day(true)
			farm.set_time(minute_of_day)
			_update_ui()

	ambient_fx.update_environment(farm.current_day, farm.weather, minute_of_day)
	_update_context_target()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I and not ui.shop_open:
			if inventory_ui.is_open:
				inventory_ui.close_panel()
			else:
				inventory_ui.open_bag(_bag_snapshot())
			return
		if inventory_ui.is_open or ui.shop_open:
			return
		if event.keycode == KEY_Q:
			_select_tool((selected_tool + 1) % 6)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			_select_tool(int(event.keycode - KEY_1))

func _select_tool(index: int) -> void:
	if inventory_ui.is_open or ui.shop_open:
		return
	selected_tool = clampi(index, 0, 5)
	player.set_equipped_tool(selected_tool)
	var names := ["Hoe", "Turnip Seeds", "Carrot Seeds", "Corn Seeds", "Watering Can", "Harvest"]
	ui.show_message("%s selected." % names[selected_tool])
	_update_ui()

func _get_near_interaction() -> Dictionary:
	var chest_interaction := storage_chest.get_interaction(player.position)
	if not chest_interaction.is_empty():
		return chest_interaction
	return farm.get_interaction_near(player.position)

func _on_player_action(target_position: Vector2) -> void:
	if ui.shop_open or inventory_ui.is_open:
		return

	var interaction := _get_near_interaction()
	if not interaction.is_empty():
		_handle_interaction(interaction)
		return

	var cell := farm.world_to_cell(target_position)
	if not farm.is_valid_cell(cell):
		ui.show_message("Walk closer to a field tile or town location.")
		return
	if energy <= 0:
		ui.show_message("You're exhausted. Go to the farmhouse and sleep.")
		return

	var worked := false
	var cost := 1
	match selected_tool:
		0:
			worked = farm.till(cell)
			cost = 2
			if worked:
				ui.show_message("Soil tilled.")
		1, 2, 3:
			var crop := _crop_for_tool(selected_tool)
			if int(seed_inventory[crop]) <= 0:
				ui.show_message("No %s seeds. Buy more at the General Store." % crop.capitalize())
			else:
				worked = farm.plant(cell, crop)
				if worked:
					seed_inventory[crop] = int(seed_inventory[crop]) - 1
					ui.show_message("%s planted." % crop.capitalize())
		4:
			worked = farm.water(cell)
			if worked:
				ui.show_message("Watered.")
		5:
			var harvested := farm.harvest(cell)
			worked = harvested != ""
			if worked:
				produce_inventory[harvested] = int(produce_inventory.get(harvested, 0)) + 1
				ui.show_message("Harvested %s!" % harvested.capitalize())
				_register_quest_harvest(harvested)

	if worked:
		energy = maxi(0, energy - cost)
	else:
		ui.show_message("That action doesn't work on this tile yet.")
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _crop_for_tool(tool: int) -> String:
	match tool:
		1: return "turnip"
		2: return "carrot"
		3: return "corn"
	return "turnip"

func _handle_interaction(data: Dictionary) -> void:
	match String(data.get("type", "")):
		"shop":
			inventory_ui.close_panel()
			inventory_ui.bag_button.disabled = true
			ui.open_shop(money, seed_prices, sell_prices, produce_inventory)
			player.set_controls_locked(true)
		"home":
			if minute_of_day < 17 * 60:
				ui.show_message("It's still early, but sleeping will pass the whole day.")
			_start_next_day(false)
		"shipping":
			_queue_shipping()
		"chest":
			inventory_ui.open_chest(_bag_snapshot(), storage_inventory)
		"npc":
			_talk_to_npc(String(data.get("id", "")))

func _talk_to_npc(id: String) -> void:
	match id:
		"mayor":
			if quest_stage == 0:
				quest_stage = 1
				quest_progress = 0
				ui.show_message("Rowan: Harvest 5 turnips. I'll pay 300g when you're done.")
			elif quest_stage == 1:
				ui.show_message("Rowan: Turnip progress %d/5." % quest_progress)
			elif quest_stage >= 2:
				ui.show_message("Rowan: Lina near the south path may have more work for you.")
		"lina":
			if quest_stage < 2:
				ui.show_message("Lina: Rowan usually has the first town request for new farmers.")
			elif quest_stage == 2:
				quest_stage = 3
				quest_progress = 0
				ui.show_message("Lina: Grow 4 carrots for the market. Reward: 450g.")
			elif quest_stage == 3:
				ui.show_message("Lina: Carrot progress %d/4." % quest_progress)
			else:
				ui.show_message("Lina: The market stall looks much better already.")
		"marnie":
			if quest_stage < 4:
				ui.show_message("Marnie: Come see me after you've helped Lina with the market.")
			elif quest_stage == 4:
				quest_stage = 5
				quest_progress = 0
				ui.show_message("Marnie: Harvest 3 corn for the barn. Reward: 700g.")
			elif quest_stage == 5:
				ui.show_message("Marnie: Corn progress %d/3." % quest_progress)
			else:
				ui.show_message("Marnie: The barn is stocked. Greenfield owes you one!")
	_update_ui()

func _register_quest_harvest(crop: String) -> void:
	if quest_stage == 1 and crop == "turnip":
		quest_progress += 1
		if quest_progress >= 5:
			quest_stage = 2
			quest_progress = 0
			money += 300
			ui.show_message("Rowan's request complete! +300g. Now visit Lina.")
	elif quest_stage == 3 and crop == "carrot":
		quest_progress += 1
		if quest_progress >= 4:
			quest_stage = 4
			quest_progress = 0
			money += 450
			ui.show_message("Lina's request complete! +450g. Go talk to Marnie.")
	elif quest_stage == 5 and crop == "corn":
		quest_progress += 1
		if quest_progress >= 3:
			quest_stage = 6
			quest_progress = 0
			money += 700
			ui.show_message("Marnie's request complete! +700g. Town request chain complete.")

func _buy_seed(crop: String) -> void:
	if not seed_prices.has(crop):
		return
	var price := int(seed_prices[crop])
	if money < price:
		ui.show_message("Not enough gold.")
		return
	money -= price
	seed_inventory[crop] = int(seed_inventory.get(crop, 0)) + 1
	ui.show_message("Bought 1 %s seed for %dg." % [crop.capitalize(), price])
	ui.refresh_shop(money, seed_prices, sell_prices, produce_inventory)
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _sell_all_produce() -> void:
	var earned := 0
	for crop in produce_inventory.keys():
		earned += int(produce_inventory[crop]) * int(sell_prices[crop])
		produce_inventory[crop] = 0
	if earned <= 0:
		ui.show_message("You don't have any harvested crops to sell.")
	else:
		money += earned
		ui.show_message("Sold directly to the store for %dg." % earned)
	if ui.shop_open:
		ui.refresh_shop(money, seed_prices, sell_prices, produce_inventory)
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _queue_shipping() -> void:
	var queued_value := 0
	var queued_count := 0
	for crop in produce_inventory.keys():
		var amount := int(produce_inventory[crop])
		if amount > 0:
			shipping_pending[crop] = int(shipping_pending.get(crop, 0)) + amount
			queued_value += amount * int(sell_prices[crop])
			queued_count += amount
			produce_inventory[crop] = 0
	if queued_count <= 0:
		ui.show_message("The shipping bin is empty. Harvest something first.")
	else:
		ui.show_message("Shipped %d items. Estimated payout tomorrow: %dg." % [queued_count, queued_value])
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _shipping_value() -> int:
	var value := 0
	for crop in shipping_pending.keys():
		value += int(shipping_pending[crop]) * int(sell_prices[crop])
	return value

func _settle_shipping() -> int:
	var earned := _shipping_value()
	if earned > 0:
		money += earned
	for crop in shipping_pending.keys():
		shipping_pending[crop] = 0
	return earned

func _close_shop() -> void:
	ui.close_shop()
	inventory_ui.bag_button.disabled = false
	player.set_controls_locked(false)

func _on_inventory_open_changed(open: bool) -> void:
	if ui.shop_open:
		return
	player.set_controls_locked(open)
	if not open:
		player.set_virtual_move(Vector2.ZERO)

func _bag_snapshot() -> Dictionary:
	return {
		"seed_turnip": int(seed_inventory.get("turnip", 0)),
		"seed_carrot": int(seed_inventory.get("carrot", 0)),
		"seed_corn": int(seed_inventory.get("corn", 0)),
		"turnip": int(produce_inventory.get("turnip", 0)),
		"carrot": int(produce_inventory.get("carrot", 0)),
		"corn": int(produce_inventory.get("corn", 0))
	}

func _bag_item_count(item_key: String) -> int:
	match item_key:
		"seed_turnip": return int(seed_inventory.get("turnip", 0))
		"seed_carrot": return int(seed_inventory.get("carrot", 0))
		"seed_corn": return int(seed_inventory.get("corn", 0))
		"turnip": return int(produce_inventory.get("turnip", 0))
		"carrot": return int(produce_inventory.get("carrot", 0))
		"corn": return int(produce_inventory.get("corn", 0))
	return 0

func _set_bag_item_count(item_key: String, value: int) -> void:
	value = maxi(0, value)
	match item_key:
		"seed_turnip": seed_inventory["turnip"] = value
		"seed_carrot": seed_inventory["carrot"] = value
		"seed_corn": seed_inventory["corn"] = value
		"turnip": produce_inventory["turnip"] = value
		"carrot": produce_inventory["carrot"] = value
		"corn": produce_inventory["corn"] = value

func _on_inventory_transfer(item_key: String, direction: String) -> void:
	if not storage_inventory.has(item_key):
		return
	var bag_count := _bag_item_count(item_key)
	var chest_count := int(storage_inventory.get(item_key, 0))
	if direction == "to_chest":
		if bag_count <= 0:
			return
		_set_bag_item_count(item_key, bag_count - 1)
		storage_inventory[item_key] = chest_count + 1
	elif direction == "to_bag":
		if chest_count <= 0:
			return
		storage_inventory[item_key] = chest_count - 1
		_set_bag_item_count(item_key, bag_count + 1)
	else:
		return
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _start_next_day(from_midnight: bool) -> void:
	var shipped_gold := _settle_shipping()
	minute_of_day = 6 * 60
	energy = 100
	warned_late = false
	var roll := randi() % 5
	var next_weather := "Rain" if roll == 0 else ("Cloudy" if roll == 1 else "Sunny")
	farm.next_day(next_weather)
	farm.set_time(minute_of_day)
	player.position = Vector2(370, 420)
	ambient_fx.update_environment(farm.current_day, farm.weather, minute_of_day)

	var morning_message := "A new morning begins." if from_midnight else "You wake up refreshed."
	morning_message += " Weather: %s." % next_weather
	if shipped_gold > 0:
		morning_message += " Overnight shipping: +%dg." % shipped_gold
	ui.show_message(morning_message)
	_update_ui()

func _update_context_target() -> void:
	if ui.shop_open or inventory_ui.is_open:
		focus_overlay.clear_target()
		ui.set_context_hint("")
		return

	var interaction := _get_near_interaction()
	if not interaction.is_empty():
		focus_overlay.clear_target()
		ui.set_context_hint("USE  •  %s" % String(interaction.get("name", "Interact")))
		return

	var target_position := player.position + player.facing.normalized() * 67.0
	var cell := farm.world_to_cell(target_position)
	if farm.is_valid_cell(cell):
		focus_overlay.set_target(cell, true, selected_tool)
		var actions := ["Till soil", "Plant turnip", "Plant carrot", "Plant corn", "Water plot", "Harvest crop"]
		ui.set_context_hint("USE  •  %s" % actions[selected_tool])
	else:
		focus_overlay.clear_target()
		ui.set_context_hint("")

func _season_name() -> String:
	var season_index := int(floor(float(farm.current_day - 1) / 28.0)) % SEASONS.size()
	return String(SEASONS[season_index])

func _season_day() -> int:
	return ((farm.current_day - 1) % 28) + 1

func _quest_text() -> String:
	match quest_stage:
		0: return "Find Mayor Rowan in town."
		1: return "Rowan · Turnips  %d / 5" % quest_progress
		2: return "Request done · Visit Lina."
		3: return "Lina · Carrots  %d / 4" % quest_progress
		4: return "Request done · Visit Marnie."
		5: return "Marnie · Corn  %d / 3" % quest_progress
		6: return "Town request chain complete!"
	return "Explore Greenfield."

func _update_ui() -> void:
	ui.update_status(
		_season_name(),
		_season_day(),
		minute_of_day,
		money,
		farm.weather,
		seed_inventory,
		produce_inventory,
		selected_tool,
		energy,
		_quest_text(),
		_shipping_value()
	)

func save_game() -> void:
	var data := {
		"save_version": 6,
		"farm": farm.get_save_data(),
		"player_x": player.position.x,
		"player_y": player.position.y,
		"seeds": seed_inventory,
		"produce": produce_inventory,
		"shipping_pending": shipping_pending,
		"storage_inventory": storage_inventory,
		"money": money,
		"energy": energy,
		"minute": minute_of_day,
		"selected": selected_tool,
		"quest_stage": quest_stage,
		"quest_progress": quest_progress
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		ui.show_message("Game saved, including farm chest storage.")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		ui.show_message("No save file yet.")
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		ui.show_message("Save file is invalid.")
		return
	farm.load_save_data(parsed.get("farm", {}))
	player.position = Vector2(float(parsed.get("player_x", 370)), float(parsed.get("player_y", 420)))
	seed_inventory = parsed.get("seeds", seed_inventory)
	produce_inventory = parsed.get("produce", produce_inventory)
	shipping_pending = parsed.get("shipping_pending", shipping_pending)
	storage_inventory = parsed.get("storage_inventory", storage_inventory)
	money = int(parsed.get("money", 350))
	energy = int(parsed.get("energy", 100))
	minute_of_day = int(parsed.get("minute", 360))
	selected_tool = int(parsed.get("selected", 0))
	player.set_equipped_tool(selected_tool)

	if parsed.has("quest_stage"):
		quest_stage = int(parsed.get("quest_stage", 0))
		quest_progress = int(parsed.get("quest_progress", 0))
	else:
		var old_started := bool(parsed.get("quest_started", false))
		var old_complete := bool(parsed.get("quest_complete", false))
		var old_turnips := int(parsed.get("quest_turnips", 0))
		if old_complete:
			quest_stage = 2
			quest_progress = 0
		elif old_started:
			quest_stage = 1
			quest_progress = old_turnips
		else:
			quest_stage = 0
			quest_progress = 0

	warned_late = minute_of_day >= 22 * 60
	farm.set_time(minute_of_day)
	ambient_fx.update_environment(farm.current_day, farm.weather, minute_of_day)
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	ui.show_message("Game loaded. Inventory and chest restored.")
	_update_ui()
