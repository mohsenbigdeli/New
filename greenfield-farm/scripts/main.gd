extends Node2D

const SAVE_PATH := "user://greenfield_save.json"

var farm: FarmWorld
var player: FarmPlayer
var ui: GameUI
var selected_tool := 0
var seeds := 12
var turnips := 0
var energy := 100
var minute_of_day := 6 * 60
var clock_accumulator := 0.0
var minute_step_seconds := 0.18

func _ready() -> void:
	farm = FarmWorld.new()
	farm.name = "FarmWorld"
	add_child(farm)

	player = FarmPlayer.new()
	player.name = "Player"
	player.position = farm.cell_to_world(Vector2i(8,8))
	add_child(player)
	player.action_requested.connect(_on_player_action)

	ui = GameUI.new()
	ui.name = "GameUI"
	add_child(ui)
	ui.tool_selected.connect(_select_tool)
	ui.action_pressed.connect(player.request_action)
	ui.move_changed.connect(player.set_virtual_move)
	ui.save_pressed.connect(save_game)
	ui.load_pressed.connect(load_game)

	ui.show_message("Till soil, plant seeds, water, then sleep until harvest.")
	_update_ui()

func _process(delta: float) -> void:
	clock_accumulator += delta
	if clock_accumulator >= minute_step_seconds:
		clock_accumulator -= minute_step_seconds
		minute_of_day += 10
		if minute_of_day >= 24 * 60:
			_start_next_day()
		_update_ui()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_select_tool((selected_tool + 1) % 4)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_4:
			_select_tool(int(event.keycode - KEY_1))

func _select_tool(index: int) -> void:
	selected_tool = clampi(index,0,3)
	var names := ["Hoe selected", "Seeds selected", "Watering can selected", "Harvest selected"]
	ui.show_message(names[selected_tool])
	_update_ui()

func _on_player_action(target_position: Vector2) -> void:
	var cell := farm.world_to_cell(target_position)
	if not farm.is_valid_cell(cell):
		ui.show_message("Stand closer to a farm tile.")
		return
	if energy <= 0:
		ui.show_message("Too tired. Save, then wait for the next day.")
		return
	var worked := false
	match selected_tool:
		0:
			worked = farm.till(cell)
			if worked: ui.show_message("Soil tilled.")
		1:
			if seeds <= 0:
				ui.show_message("No seeds left.")
			else:
				worked = farm.plant(cell)
				if worked:
					seeds -= 1
					ui.show_message("Turnip planted.")
		2:
			worked = farm.water(cell)
			if worked: ui.show_message("Watered.")
		3:
			worked = farm.harvest(cell)
			if worked:
				turnips += 1
				ui.show_message("Harvested! +1 turnip")
	if worked:
		energy = maxi(0, energy - 2)
	else:
		ui.show_message("Nothing to do on this tile.")
	_update_ui()

func _start_next_day() -> void:
	minute_of_day = 6 * 60
	energy = 100
	farm.next_day()
	ui.show_message("A new day begins. Watered crops have grown.")

func _update_ui() -> void:
	ui.update_status(farm.current_day, minute_of_day, seeds, turnips, selected_tool, energy)

func save_game() -> void:
	var data := {
		"farm": farm.get_save_data(),
		"player_x": player.position.x,
		"player_y": player.position.y,
		"seeds": seeds,
		"turnips": turnips,
		"energy": energy,
		"minute": minute_of_day,
		"selected": selected_tool
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
	player.position = Vector2(float(parsed.get("player_x", 600)), float(parsed.get("player_y", 500)))
	seeds = int(parsed.get("seeds", 12))
	turnips = int(parsed.get("turnips", 0))
	energy = int(parsed.get("energy", 100))
	minute_of_day = int(parsed.get("minute", 360))
	selected_tool = int(parsed.get("selected", 0))
	ui.show_message("Game loaded.")
	_update_ui()
