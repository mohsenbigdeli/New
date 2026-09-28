extends "res://scripts/main_v32.gd"

const V50_WORLD := preload("res://scripts/farm_vertical_slice_v50.gd")

var v50_world: FarmVerticalSliceV50
var v50_well_day := 0
var v50_bench_day := 0
var v50_garden_day := 0

func _ready() -> void:
	super()
	_disable_legacy_world_layers_v50()
	_install_v50_world()
	_apply_v50_game_feel()
	ui.show_message("Greenfield Farm v5.0 Rebuild: one focused farm-town slice, grounded movement, clean watercolor world and tighter exploration.")

func _install_v50_world() -> void:
	if v50_world:
		return
	v50_world = V50_WORLD.new()
	v50_world.name = "VerticalSliceV50"
	add_child(v50_world)
	v50_world.setup(farm)
	v50_world.set_active(interiors.active_room == "outside")

func _disable_legacy_world_layers_v50() -> void:
	# Keep FarmWorld alive for farming data and collisions, but replace every
	# older presentation layer with the curated v5.0 slice.
	if farm:
		farm.visible = false
	if painted_world_v17:
		painted_world_v17.set_active(false)
	if painted_world_v18:
		painted_world_v18.set_active(false)
	if painted_world_v19:
		painted_world_v19.set_active(false)
	if painted_world_v22:
		painted_world_v22.set_active(false)
	if painted_world_v28:
		painted_world_v28.set_active(false)

func _apply_v50_game_feel() -> void:
	if not player or interiors.active_room != "outside":
		return
	# The huge-map builds felt floaty. Slow the farmer slightly and use a
	# closer camera so movement and collisions read clearly on a phone.
	player.speed = 220.0
	player.set_world_bounds(FarmWorld.WORLD_SIZE, 1.02)
	if player.camera:
		player.camera.position_smoothing_speed = 6.4
		player.camera.reset_smoothing()

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if v50_world:
		v50_world.set_active(room == "outside")
	if room == "outside":
		_disable_legacy_world_layers_v50()
		_apply_v50_game_feel()

func _get_near_interaction() -> Dictionary:
	if interiors.active_room == "outside" and v50_world:
		var interaction := v50_world.get_interaction(player.position)
		if not interaction.is_empty():
			return interaction
	return super._get_near_interaction()

func _handle_interaction(data: Dictionary) -> void:
	var kind := String(data.get("type", ""))
	match kind:
		"v50_welcome_board":
			ui.show_message("Greenfield · Farm west of the lane · Pond and bench east · General Store north-east · Town Hall south-east. Start with Rowan near the square.")
			return
		"v50_well":
			_handle_v50_well()
			return
		"v50_bench":
			_handle_v50_bench()
			return
		"v50_garden":
			_handle_v50_garden()
			return
	super._handle_interaction(data)

func _handle_v50_well() -> void:
	if v50_well_day == farm.current_day:
		ui.show_message("The village well is quiet now. Come back tomorrow.")
		return
	v50_well_day = farm.current_day
	energy = mini(100, energy + 8)
	_update_ui()
	ui.show_message("Cool water from the village well restores +8 Energy.")

func _handle_v50_bench() -> void:
	if v50_bench_day == farm.current_day:
		ui.show_message("You've already taken a proper pond break today.")
		return
	v50_bench_day = farm.current_day
	energy = mini(100, energy + 12)
	minute_of_day = mini(23 * 60 + 30, minute_of_day + 20)
	farm.set_time(minute_of_day)
	_update_ui()
	ui.show_message("You sit by the pond for 20 minutes. +12 Energy.")

func _handle_v50_garden() -> void:
	if v50_garden_day == farm.current_day:
		ui.show_message("The community herb garden has already been tended today.")
		return
	v50_garden_day = farm.current_day
	seed_inventory["turnip"] = int(seed_inventory.get("turnip", 0)) + 1
	energy = mini(100, energy + 4)
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()
	ui.show_message("You help with the herb garden and find +1 Turnip Seed · +4 Energy.")

func _start_next_day(from_midnight: bool) -> void:
	super._start_next_day(from_midnight)
	_disable_legacy_world_layers_v50()
	_apply_v50_game_feel()

func save_game() -> void:
	super.save_game()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	parsed["save_version"] = maxi(50, int(parsed.get("save_version", 0)))
	parsed["v50_rebuild"] = {
		"well_day": v50_well_day,
		"bench_day": v50_bench_day,
		"garden_day": v50_garden_day
	}
	var output := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify(parsed))

func load_game() -> void:
	super.load_game()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data = parsed.get("v50_rebuild", {})
	if typeof(data) == TYPE_DICTIONARY:
		v50_well_day = int(data.get("well_day", 0))
		v50_bench_day = int(data.get("bench_day", 0))
		v50_garden_day = int(data.get("garden_day", 0))
	_disable_legacy_world_layers_v50()
	if v50_world:
		v50_world.set_active(interiors.active_room == "outside")
	_apply_v50_game_feel()
	_update_ui()
