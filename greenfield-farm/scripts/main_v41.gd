extends "res://scripts/main_v40.gd"

const HIGHLANDS_V41 := preload("res://scripts/farm_highlands_v41.gd")
const V41_WORLD_SIZE := Vector2(3800, 3600)

var highlands_v41: FarmHighlandsV41

var v41_blooms: Dictionary = {}
var v41_crystals: Dictionary = {}
var v41_chests: Dictionary = {}
var v41_daily: Dictionary = {}
var v41_discovered: Dictionary = {}

var v41_day := 0
var v41_ivy_stage := 0
var v41_ivy_progress := 0
var v41_garrick_stage := 0
var v41_garrick_progress := 0
var v41_hot_spring_day := 0
var v41_shrine_day := 0
var v41_lookout_claimed := false
var v41_discovery_bonus_claimed := false

const V41_DISCOVERIES := [
	{"id":"highland_gate","name":"Pinewatch Gate","pos":Vector2(3040, 2420)},
	{"id":"hot_spring","name":"Pinewatch Hot Spring","pos":Vector2(3520, 2850)},
	{"id":"crystal_hollow","name":"Crystal Hollow","pos":Vector2(3400, 3300)},
	{"id":"skylook","name":"Skylook Point","pos":Vector2(3680, 2520)}
]

func _ready() -> void:
	super()
	_install_v41_highlands()
	if v41_day <= 0:
		v41_day = farm.current_day
	_apply_v41_layering_and_camera()
	_sync_v41_state()
	ui.show_message("v4.1 Highlands Update: grey void fixed, Pinewatch Highlands + Crystal Hollow added, 2 new quest lines, 4 discoveries, 3 daily finds, 3 chests, hot spring, Sky Shrine and more fast travel.")

func _process(delta: float) -> void:
	super(delta)
	if interiors.active_room == "outside":
		_check_v41_discoveries()

func _install_v41_highlands() -> void:
	if highlands_v41:
		return
	highlands_v41 = HIGHLANDS_V41.new()
	highlands_v41.name = "HighlandsV41"
	add_child(highlands_v41)
	highlands_v41.set_active(interiors.active_room == "outside")

func _apply_v41_layering_and_camera() -> void:
	var outside := interiors.active_room == "outside"
	if south_grove_v33:
		south_grove_v33.z_index = 0
		south_grove_v33.set_active(outside)
	if expansion_v40:
		expansion_v40.z_index = 0
		expansion_v40.set_active(outside)
	if highlands_v41:
		highlands_v41.z_index = 0
		highlands_v41.set_active(outside)
	if painted_world_v28:
		painted_world_v28.z_index = 0
	if player:
		player.z_index = 3
		if outside:
			player.set_world_bounds(V41_WORLD_SIZE, 0.98)
			player.camera.position_smoothing_speed = 8.0
			player.camera.reset_smoothing()
	if focus_overlay:
		focus_overlay.z_index = 2

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if highlands_v41:
		highlands_v41.set_active(room == "outside")
	_apply_v41_layering_and_camera()

func _get_near_interaction() -> Dictionary:
	if interiors.active_room == "outside" and highlands_v41:
		var highland_interaction := highlands_v41.get_interaction(player.position)
		if not highland_interaction.is_empty():
			return highland_interaction
	return super._get_near_interaction()

func _handle_interaction(data: Dictionary) -> void:
	var kind := String(data.get("type", ""))
	match kind:
		"v41_sign":
			ui.show_message("Pinewatch Highlands: botanist lodge north, hot spring east, Crystal Hollow south and Skylook Point on the far ridge.")
			return
		"v41_cart":
			_v41_fast_travel(Vector2(1440, 2440), "South Crossroads")
			return
		"v41_ivy":
			_handle_v41_ivy()
			return
		"v41_garrick":
			_handle_v41_garrick()
			return
		"v41_bloom":
			_handle_v41_bloom(String(data.get("id", "")))
			return
		"v41_crystal":
			_handle_v41_crystal(String(data.get("id", "")))
			return
		"v41_daily":
			_handle_v41_daily(String(data.get("id", "")))
			return
		"v41_chest":
			_handle_v41_chest(String(data.get("id", "")))
			return
		"v41_hot_spring":
			_handle_v41_hot_spring()
			return
		"v41_lookout":
			_handle_v41_lookout()
			return
		"v41_sky_shrine":
			_handle_v41_sky_shrine()
			return
	super._handle_interaction(data)

func _v41_fast_travel(destination: Vector2, label: String) -> void:
	player.set_virtual_move(Vector2.ZERO)
	player.position = destination
	player.facing = Vector2.DOWN
	minute_of_day = mini(23 * 60 + 30, minute_of_day + 20)
	farm.set_time(minute_of_day)
	if player.camera:
		player.camera.reset_smoothing()
	_update_ui()
	ui.show_message("Trail Cart → %s. Travel time: 20 minutes." % label)

func _handle_v41_ivy() -> void:
	if v41_ivy_stage == 0:
		v41_ivy_stage = 1
		v41_ivy_progress = v41_blooms.size()
		if v41_ivy_progress >= 4:
			v41_ivy_stage = 2
			ui.show_message("Ivy: You already found all four rare blooms. Talk to me once more for your field-study reward.")
		else:
			ui.show_message("Ivy: Pinewatch has four rare flowers. Bring me Silverleaf, Suncrest, Cloudbell and Moonpetal.")
	elif v41_ivy_stage == 1:
		ui.show_message("Ivy: Rare bloom study %d/4. Search the lodge slope, upper ridge, hot-spring trail and lower meadow." % v41_ivy_progress)
	elif v41_ivy_stage == 2:
		v41_ivy_stage = 3
		money += 900
		seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 2
		seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 2
		energy = mini(100, energy + 15)
		inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
		_update_ui()
		ui.show_message("Ivy: Complete field study! +900g, +2 Carrot Seeds, +2 Corn Seeds and +15 Energy.")
	else:
		ui.show_message("Ivy: Highland forage returns every morning. The rare flowers themselves only needed documenting once.")

func _handle_v41_bloom(id: String) -> void:
	if id.is_empty() or v41_blooms.has(id):
		return
	v41_blooms[id] = true
	money += 45
	if v41_ivy_stage == 1:
		v41_ivy_progress = mini(4, v41_ivy_progress + 1)
		if v41_ivy_progress >= 4:
			v41_ivy_stage = 2
			ui.show_message("Rare bloom 4/4 documented. +45g. Return to Ivy for the research reward.")
		else:
			ui.show_message("Rare bloom documented. +45g · Ivy %d/4." % v41_ivy_progress)
	else:
		ui.show_message("You document a rare Pinewatch bloom. +45g.")
	_sync_v41_state()
	_update_ui()

func _handle_v41_garrick() -> void:
	if v41_garrick_stage == 0:
		v41_garrick_stage = 1
		v41_garrick_progress = v41_crystals.size()
		if v41_garrick_progress >= 5:
			v41_garrick_stage = 2
			ui.show_message("Garrick: You've already mapped every crystal vein. Talk to me again and I'll pay the survey bonus.")
		else:
			ui.show_message("Garrick: Crystal Hollow has 5 exposed veins. Mark all five and I'll share the prospecting payout.")
	elif v41_garrick_stage == 1:
		ui.show_message("Garrick: Crystal survey %d/5. Search both cave walls and the deep southern pocket." % v41_garrick_progress)
	elif v41_garrick_stage == 2:
		v41_garrick_stage = 3
		money += 1100
		seed_inventory["turnip"] = int(seed_inventory.get("turnip", 0)) + 3
		seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 1
		energy = mini(100, energy + 25)
		inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
		_update_ui()
		ui.show_message("Garrick: Survey complete. +1100g, +3 Turnip Seeds, +1 Corn Seed and +25 Energy.")
	else:
		ui.show_message("Garrick: The hollow is stable now. Check the Sky Shrine after both highland studies are finished.")

func _handle_v41_crystal(id: String) -> void:
	if id.is_empty() or v41_crystals.has(id):
		return
	v41_crystals[id] = true
	money += 55
	if v41_garrick_stage == 1:
		v41_garrick_progress = mini(5, v41_garrick_progress + 1)
		if v41_garrick_progress >= 5:
			v41_garrick_stage = 2
			ui.show_message("Crystal vein 5/5 mapped. +55g. Return to Garrick for the survey reward.")
		else:
			ui.show_message("Crystal vein mapped. +55g · Garrick %d/5." % v41_garrick_progress)
	else:
		ui.show_message("You map a valuable Pinewatch crystal vein. +55g.")
	_sync_v41_state()
	_update_ui()

func _handle_v41_daily(id: String) -> void:
	if id.is_empty() or v41_daily.has(id):
		return
	v41_daily[id] = true
	match id:
		"pinecone":
			money += 55
			seed_inventory["turnip"] = int(seed_inventory.get("turnip", 0)) + 1
			ui.show_message("Pinecone cache: +55g and +1 Turnip Seed.")
		"dew":
			energy = mini(100, energy + 14)
			money += 35
			ui.show_message("Crystal dew: +14 Energy and +35g.")
		"herbs":
			energy = mini(100, energy + 10)
			seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 1
			ui.show_message("Highland herbs: +10 Energy and +1 Carrot Seed.")
		_:
			money += 25
			ui.show_message("Highland forage: +25g.")
	_sync_v41_state()
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _handle_v41_chest(id: String) -> void:
	if id.is_empty() or v41_chests.has(id):
		return
	v41_chests[id] = true
	match id:
		"lookout":
			money += 420
			seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 2
			ui.show_message("Lookout cache: +420g and +2 Carrot Seeds.")
		"cave":
			money += 520
			seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 2
			ui.show_message("Crystal Hollow chest: +520g and +2 Corn Seeds.")
		"spring":
			money += 300
			energy = mini(100, energy + 25)
			ui.show_message("Hot spring chest: +300g and +25 Energy.")
		_:
			money += 200
			ui.show_message("Hidden cache: +200g.")
	_sync_v41_state()
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _handle_v41_hot_spring() -> void:
	if v41_hot_spring_day == farm.current_day:
		ui.show_message("You already rested in the hot spring today.")
		return
	v41_hot_spring_day = farm.current_day
	energy = mini(100, energy + 35)
	minute_of_day = mini(23 * 60 + 30, minute_of_day + 40)
	farm.set_time(minute_of_day)
	_update_ui()
	ui.show_message("Pinewatch Hot Spring: +35 Energy. 40 minutes pass.")

func _handle_v41_lookout() -> void:
	if not v41_lookout_claimed:
		v41_lookout_claimed = true
		money += 180
		energy = mini(100, energy + 8)
		_update_ui()
		ui.show_message("Skylook Point discovered! +180g and +8 Energy. You can see all of Greenfield from here.")
	else:
		ui.show_message("Skylook Point: farm, coast, ruins and Willow Grove are all visible below.")

func _handle_v41_sky_shrine() -> void:
	if v41_ivy_stage < 3 or v41_garrick_stage < 3:
		ui.show_message("The Sky Shrine is dormant. Complete Ivy's flower study and Garrick's crystal survey first.")
		return
	if v41_shrine_day == farm.current_day:
		ui.show_message("The Sky Shrine has already answered today.")
		return
	v41_shrine_day = farm.current_day
	money += 120
	energy = mini(100, energy + 12)
	var crops: Array[String] = ["turnip", "carrot", "corn"]
	var crop := crops[(farm.current_day + v41_crystals.size()) % crops.size()]
	seed_inventory[crop] = int(seed_inventory.get(crop, 0)) + 1
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()
	ui.show_message("Sky Shrine blessing: +120g, +12 Energy and +1 %s Seed." % crop.capitalize())

func _check_v41_discoveries() -> void:
	for item in V41_DISCOVERIES:
		var id := String(item["id"])
		if v41_discovered.has(id):
			continue
		var pos: Vector2 = item["pos"]
		if player.position.distance_to(pos) > 125.0:
			continue
		v41_discovered[id] = true
		money += 40
		if v41_discovered.size() >= V41_DISCOVERIES.size() and not v41_discovery_bonus_claimed:
			v41_discovery_bonus_claimed = true
			money += 350
			seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 2
			seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 1
			inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
			_update_ui()
			ui.show_message("Pinewatch Journal complete 4/4! +350g, +2 Carrot Seeds and +1 Corn Seed.")
		else:
			_update_ui()
			ui.show_message("Discovered: %s · +40g · Pinewatch Journal %d/4." % [String(item["name"]), v41_discovered.size()])
		break

func _start_next_day(from_midnight: bool) -> void:
	super._start_next_day(from_midnight)
	v41_day = farm.current_day
	v41_daily.clear()
	_apply_v41_layering_and_camera()
	_sync_v41_state()

func _quest_text() -> String:
	var parts: Array[String] = []
	if v41_ivy_stage == 1:
		parts.append("Blooms %d/4" % v41_ivy_progress)
	elif v41_ivy_stage == 2:
		parts.append("Return to Ivy")
	if v41_garrick_stage == 1:
		parts.append("Crystals %d/5" % v41_garrick_progress)
	elif v41_garrick_stage == 2:
		parts.append("Return to Garrick")
	if not parts.is_empty():
		var joined := ""
		for part in parts:
			if not joined.is_empty():
				joined += " · "
			joined += part
		return "Pinewatch · " + joined
	return super._quest_text()

func _sync_v41_state() -> void:
	if highlands_v41:
		highlands_v41.set_state(v41_blooms, v41_crystals, v41_chests, v41_daily, farm.current_day)

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
	parsed["save_version"] = maxi(41, int(parsed.get("save_version", 0)))
	parsed["v41_highlands"] = {
		"blooms": v41_blooms,
		"crystals": v41_crystals,
		"chests": v41_chests,
		"daily": v41_daily,
		"discovered": v41_discovered,
		"day": v41_day,
		"ivy_stage": v41_ivy_stage,
		"ivy_progress": v41_ivy_progress,
		"garrick_stage": v41_garrick_stage,
		"garrick_progress": v41_garrick_progress,
		"hot_spring_day": v41_hot_spring_day,
		"shrine_day": v41_shrine_day,
		"lookout": v41_lookout_claimed,
		"discovery_bonus": v41_discovery_bonus_claimed
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
	var data = parsed.get("v41_highlands", {})
	if typeof(data) == TYPE_DICTIONARY:
		var a = data.get("blooms", {})
		var b = data.get("crystals", {})
		var c = data.get("chests", {})
		var d = data.get("daily", {})
		var e = data.get("discovered", {})
		v41_blooms = a.duplicate(true) if typeof(a) == TYPE_DICTIONARY else {}
		v41_crystals = b.duplicate(true) if typeof(b) == TYPE_DICTIONARY else {}
		v41_chests = c.duplicate(true) if typeof(c) == TYPE_DICTIONARY else {}
		v41_daily = d.duplicate(true) if typeof(d) == TYPE_DICTIONARY else {}
		v41_discovered = e.duplicate(true) if typeof(e) == TYPE_DICTIONARY else {}
		v41_day = int(data.get("day", farm.current_day))
		v41_ivy_stage = int(data.get("ivy_stage", 0))
		v41_ivy_progress = int(data.get("ivy_progress", 0))
		v41_garrick_stage = int(data.get("garrick_stage", 0))
		v41_garrick_progress = int(data.get("garrick_progress", 0))
		v41_hot_spring_day = int(data.get("hot_spring_day", 0))
		v41_shrine_day = int(data.get("shrine_day", 0))
		v41_lookout_claimed = bool(data.get("lookout", false))
		v41_discovery_bonus_claimed = bool(data.get("discovery_bonus", false))

	if v41_day != farm.current_day:
		v41_day = farm.current_day
		v41_daily.clear()
	_apply_v41_layering_and_camera()
	_sync_v41_state()
	_update_ui()
