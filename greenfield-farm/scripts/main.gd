extends Node2D

const SAVE_PATH := "user://greenfield_save_v02.json"

var farm: FarmWorld
var player: FarmPlayer
var ui: GameUI

var selected_tool := 0
var energy := 100
var money := 350
var minute_of_day := 6 * 60
var clock_accumulator := 0.0
var minute_step_seconds := 0.75

var seed_inventory := {"turnip": 8, "carrot": 4, "corn": 2}
var produce_inventory := {"turnip": 0, "carrot": 0, "corn": 0}
var seed_prices := {"turnip": 20, "carrot": 35, "corn": 60}
var sell_prices := {"turnip": 55, "carrot": 80, "corn": 130}

var quest_started := false
var quest_complete := false
var quest_turnips := 0

func _ready() -> void:
	randomize()
	farm = FarmWorld.new()
	farm.name = "FarmWorld"
	add_child(farm)

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

	ui.show_message("Welcome to Greenfield. Explore the town and grow your farm.")
	_update_ui()

func _process(delta: float) -> void:
	clock_accumulator += delta
	if clock_accumulator >= minute_step_seconds:
		clock_accumulator -= minute_step_seconds
		minute_of_day += 10
		if minute_of_day >= 24 * 60:
			_start_next_day(true)
		farm.set_time(minute_of_day)
		_update_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_select_tool((selected_tool + 1) % 6)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			_select_tool(int(event.keycode - KEY_1))

func _select_tool(index: int) -> void:
	selected_tool = clampi(index, 0, 5)
	player.set_equipped_tool(selected_tool)
	var names := ["Hoe", "Turnip Seeds", "Carrot Seeds", "Corn Seeds", "Watering Can", "Harvest"]
	ui.show_message("%s selected." % names[selected_tool])
	_update_ui()

func _on_player_action(target_position: Vector2) -> void:
	if ui.shop_open:
		return

	var interaction := farm.get_interaction_near(player.position)
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
				produce_inventory[harvested] = int(produce_inventory[harvested]) + 1
				ui.show_message("Harvested %s!" % harvested.capitalize())
				if harvested == "turnip" and quest_started and not quest_complete:
					quest_turnips += 1
					if quest_turnips >= 5:
						quest_complete = true
						money += 300
						ui.show_message("Rowan's request complete! +300g reward.")

	if worked:
		energy = maxi(0, energy - cost)
	else:
		ui.show_message("That action doesn't work on this tile yet.")
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
			ui.open_shop(money, seed_prices, sell_prices, produce_inventory)
			player.set_controls_locked(true)
		"home":
			if minute_of_day < 17 * 60:
				ui.show_message("It's still early. Sleeping will pass the whole day.")
			_start_next_day(false)
		"shipping":
			_sell_all_produce()
		"npc":
			_talk_to_npc(String(data.get("id", "")))

func _talk_to_npc(id: String) -> void:
	match id:
		"mayor":
			if not quest_started:
				quest_started = true
				ui.show_message("Rowan: Harvest 5 turnips and I'll pay you 300g.")
			elif quest_complete:
				ui.show_message("Rowan: Greenfield is already looking better. Great work!")
			else:
				ui.show_message("Rowan: Turnip progress %d/5." % quest_turnips)
		"lina":
			ui.show_message("Lina: Carrots take longer, but sell for more.")
		"marnie":
			ui.show_message("Marnie: Rain waters tilled plots overnight.")
	_update_ui()

func _buy_seed(crop: String) -> void:
	if not seed_prices.has(crop):
		return
	var price := int(seed_prices[crop])
	if money < price:
		ui.show_message("Not enough gold.")
		return
	money -= price
	seed_inventory[crop] = int(seed_inventory[crop]) + 1
	ui.show_message("Bought 1 %s seed for %dg." % [crop.capitalize(), price])
	ui.refresh_shop(money, seed_prices, sell_prices, produce_inventory)
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
		ui.show_message("Produce sold for %dg." % earned)
	if ui.shop_open:
		ui.refresh_shop(money, seed_prices, sell_prices, produce_inventory)
	_update_ui()

func _close_shop() -> void:
	ui.close_shop()
	player.set_controls_locked(false)

func _start_next_day(from_midnight: bool) -> void:
	minute_of_day = 6 * 60
	energy = 100
	var roll := randi() % 5
	var next_weather := "Rain" if roll == 0 else ("Cloudy" if roll == 1 else "Sunny")
	farm.next_day(next_weather)
	farm.set_time(minute_of_day)
	player.position = Vector2(370, 420)
	if from_midnight:
		ui.show_message("You stayed out too late. A new morning begins.")
	else:
		ui.show_message("You wake up refreshed. Weather: %s." % next_weather)
	_update_ui()

func _update_ui() -> void:
	ui.update_status(
		farm.current_day,
		minute_of_day,
		money,
		farm.weather,
		seed_inventory,
		produce_inventory,
		selected_tool,
		energy,
		quest_started,
		quest_complete,
		quest_turnips
	)

func save_game() -> void:
	var data := {
		"farm": farm.get_save_data(),
		"player_x": player.position.x,
		"player_y": player.position.y,
		"seeds": seed_inventory,
		"produce": produce_inventory,
		"money": money,
		"energy": energy,
		"minute": minute_of_day,
		"selected": selected_tool,
		"quest_started": quest_started,
		"quest_complete": quest_complete,
		"quest_turnips": quest_turnips
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		ui.show_message("Game saved.")

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
	money = int(parsed.get("money", 350))
	energy = int(parsed.get("energy", 100))
	minute_of_day = int(parsed.get("minute", 360))
	selected_tool = int(parsed.get("selected", 0))
	player.set_equipped_tool(selected_tool)
	quest_started = bool(parsed.get("quest_started", false))
	quest_complete = bool(parsed.get("quest_complete", false))
	quest_turnips = int(parsed.get("quest_turnips", 0))
	farm.set_time(minute_of_day)
	ui.show_message("Game loaded.")
	_update_ui()
