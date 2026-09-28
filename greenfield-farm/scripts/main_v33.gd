extends "res://scripts/main_v32.gd"

const SOUTH_GROVE_V33 := preload("res://scripts/farm_south_grove_v33.gd")
const V33_WORLD_SIZE := Vector2(2304, 2300)

var south_grove_v33: FarmSouthGroveV33
var v33_collected: Dictionary = {}
var v33_forage_day := 0
var v33_quest_stage := 0
var v33_quest_progress := 0
var v33_tree_day := 0
var v33_camp_day := 0

func _ready() -> void:
	super()
	_install_v33_south_grove()
	if v33_forage_day <= 0:
		v33_forage_day = farm.current_day
	_apply_v33_world_camera()
	_sync_v33_grove_state()
	ui.show_message("v3.3: Willow Grove is open south of the farm — larger map, new forage loop, Nora, ancient willow, campfire and a closer outdoor camera.")

func _install_v33_south_grove() -> void:
	if south_grove_v33:
		return
	south_grove_v33 = SOUTH_GROVE_V33.new()
	south_grove_v33.name = "SouthGroveV33"
	add_child(south_grove_v33)
	south_grove_v33.set_active(interiors.active_room == "outside")

func _apply_v33_world_camera() -> void:
	if player and interiors.active_room == "outside":
		# v2.2 used 0.80. A slightly closer 0.90 view keeps the larger map readable
		# without returning to the tight early-game camera.
		player.set_world_bounds(V33_WORLD_SIZE, 0.90)
		player.camera.position_smoothing_speed = 7.5
		player.camera.reset_smoothing()

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if south_grove_v33:
		south_grove_v33.set_active(room == "outside")
	if room == "outside":
		_apply_v33_world_camera()

func _get_near_interaction() -> Dictionary:
	if interiors.active_room == "outside" and south_grove_v33:
		var grove_interaction := south_grove_v33.get_interaction(player.position)
		if not grove_interaction.is_empty():
			return grove_interaction
	return super._get_near_interaction()

func _handle_interaction(data: Dictionary) -> void:
	var kind := String(data.get("type", ""))
	match kind:
		"v33_grove_sign":
			ui.show_message("Willow Grove · Forage wild plants, meet Nora at the cabin, rest at the campfire, and visit the ancient willow.")
			return
		"v33_nora":
			_handle_v33_nora()
			return
		"v33_forage":
			_handle_v33_forage(String(data.get("id", "")))
			return
		"v33_ancient_tree":
			_handle_v33_ancient_tree()
			return
		"v33_campfire":
			_handle_v33_campfire()
			return
	super._handle_interaction(data)

func _handle_v33_nora() -> void:
	if v33_quest_stage == 0:
		v33_quest_stage = 1
		v33_quest_progress = v33_collected.size()
		if v33_quest_progress >= 3:
			v33_quest_stage = 2
			ui.show_message("Nora: You already found all three grove samples today. Talk to me once more for your reward.")
		else:
			ui.show_message("Nora: Bring me samples from all 3 forage spots in Willow Grove. I need berries, herbs and mushrooms.")
	elif v33_quest_stage == 1:
		ui.show_message("Nora: Grove samples %d/3. Search the west thicket, central herbs and east mushroom ring." % v33_quest_progress)
	elif v33_quest_stage == 2:
		money += 350
		seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 2
		seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 1
		v33_quest_stage = 3
		ui.show_message("Nora: Perfect. +350g, +2 Carrot Seeds and +1 Corn Seed. Willow Grove is yours to explore.")
		inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
		_update_ui()
	else:
		ui.show_message("Nora: The grove changes a little every morning. Forage spots return each new day.")

func _handle_v33_forage(id: String) -> void:
	if id.is_empty() or v33_collected.has(id):
		return

	v33_collected[id] = true
	var reward_text := ""
	match id:
		"berries":
			money += 35
			reward_text = "+35g from wild berries."
		"herbs":
			energy = mini(100, energy + 8)
			reward_text = "+8 Energy from fresh forest herbs."
		"mushrooms":
			seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 1
			reward_text = "+1 Carrot Seed found near the mushroom ring."
		_:
			reward_text = "You found a useful forest sample."

	if v33_quest_stage == 1:
		v33_quest_progress = mini(3, v33_quest_progress + 1)
		if v33_quest_progress >= 3:
			v33_quest_stage = 2
			reward_text += " Nora's 3/3 samples are complete — return to her cabin."

	_sync_v33_grove_state()
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()
	ui.show_message(reward_text)

func _handle_v33_ancient_tree() -> void:
	if v33_tree_day == farm.current_day:
		ui.show_message("The ancient willow is quiet now. Its blessing returns tomorrow.")
		return
	v33_tree_day = farm.current_day
	var crops: Array[String] = ["turnip", "carrot", "corn"]
	var crop := crops[farm.current_day % crops.size()]
	seed_inventory[crop] = int(seed_inventory.get(crop, 0)) + 1
	energy = mini(100, energy + 5)
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()
	ui.show_message("The ancient willow rustles softly: +1 %s Seed and +5 Energy." % crop.capitalize())

func _handle_v33_campfire() -> void:
	if v33_camp_day == farm.current_day:
		ui.show_message("You already rested here today.")
		return
	v33_camp_day = farm.current_day
	energy = mini(100, energy + 25)
	minute_of_day = mini(23 * 60 + 30, minute_of_day + 30)
	farm.set_time(minute_of_day)
	_update_ui()
	ui.show_message("You rest beside the grove fire for 30 minutes. +25 Energy.")

func _start_next_day(from_midnight: bool) -> void:
	super._start_next_day(from_midnight)
	v33_forage_day = farm.current_day
	v33_collected.clear()
	if v33_quest_stage == 1:
		v33_quest_progress = 0
	_sync_v33_grove_state()

func _quest_text() -> String:
	if v33_quest_stage == 1:
		return "Nora · Grove samples  %d / 3" % v33_quest_progress
	if v33_quest_stage == 2:
		return "Nora · Return to the Grove Keeper"
	return super._quest_text()

func _sync_v33_grove_state() -> void:
	if south_grove_v33:
		south_grove_v33.set_collected_state(v33_collected)

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
	parsed["save_version"] = maxi(33, int(parsed.get("save_version", 0)))
	parsed["v33_south_grove"] = {
		"forage_day": v33_forage_day,
		"collected": v33_collected,
		"quest_stage": v33_quest_stage,
		"quest_progress": v33_quest_progress,
		"tree_day": v33_tree_day,
		"camp_day": v33_camp_day
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
	var grove_data = parsed.get("v33_south_grove", {})
	if typeof(grove_data) == TYPE_DICTIONARY:
		v33_forage_day = int(grove_data.get("forage_day", farm.current_day))
		var loaded_collected = grove_data.get("collected", {})
		v33_collected = loaded_collected.duplicate(true) if typeof(loaded_collected) == TYPE_DICTIONARY else {}
		v33_quest_stage = int(grove_data.get("quest_stage", 0))
		v33_quest_progress = int(grove_data.get("quest_progress", 0))
		v33_tree_day = int(grove_data.get("tree_day", 0))
		v33_camp_day = int(grove_data.get("camp_day", 0))

	if v33_forage_day != farm.current_day:
		v33_forage_day = farm.current_day
		v33_collected.clear()
		if v33_quest_stage == 1:
			v33_quest_progress = 0

	_apply_v33_world_camera()
	_sync_v33_grove_state()
	_update_ui()
