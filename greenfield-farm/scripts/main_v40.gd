extends "res://scripts/main_v33.gd"

const EXPANSION_V40 := preload("res://scripts/farm_expansion_v40.gd")
const V40_WORLD_SIZE := Vector2(3000, 3300)

var expansion_v40: FarmExpansionV40

var v40_debris: Dictionary = {}
var v40_relics: Dictionary = {}
var v40_chests: Dictionary = {}
var v40_daily: Dictionary = {}
var v40_discovered: Dictionary = {}

var v40_daily_day := 0
var v40_market_day := 0
var v40_tide_day := 0
var v40_shrine_day := 0

var v40_oren_stage := 0
var v40_oren_progress := 0
var v40_mira_stage := 0
var v40_mira_progress := 0
var v40_nora_stage := 0
var v40_nora_progress := 0
var v40_discovery_bonus_claimed := false

const V40_DISCOVERIES := [
	{"id":"south_crossroads","name":"South Crossroads","pos":Vector2(1085,2420)},
	{"id":"sunset_coast","name":"Sunset Coast","pos":Vector2(620,2820)},
	{"id":"tidepools","name":"Glasswater Tide Pools","pos":Vector2(1250,3070)},
	{"id":"cedar_ruins","name":"Cedar Ruins","pos":Vector2(2240,2700)},
	{"id":"moon_shrine","name":"Moon Shrine","pos":Vector2(2500,3140)}
]

func _ready() -> void:
	super()
	_install_v40_expansion()
	if v40_daily_day <= 0:
		v40_daily_day = farm.current_day
	_apply_v40_world_camera()
	_sync_v40_state()
	ui.show_message("v4.0 Expedition Update: Sunset Coast + Cedar Ridge, 3 quest lines, relic hunt, coast cleanup, discoveries, treasure, daily shrine/tide pool, market trader and trail carts.")

func _process(delta: float) -> void:
	super(delta)
	if interiors.active_room == "outside":
		_check_v40_discoveries()

func _install_v40_expansion() -> void:
	if expansion_v40:
		return
	expansion_v40 = EXPANSION_V40.new()
	expansion_v40.name = "ExpansionV40"
	add_child(expansion_v40)
	expansion_v40.set_active(interiors.active_room == "outside")

func _apply_v40_world_camera() -> void:
	if player and interiors.active_room == "outside":
		player.set_world_bounds(V40_WORLD_SIZE, 0.92)
		player.camera.position_smoothing_speed = 7.8
		player.camera.reset_smoothing()

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if expansion_v40:
		expansion_v40.set_active(room == "outside")
	if room == "outside":
		_apply_v40_world_camera()

func _get_near_interaction() -> Dictionary:
	if interiors.active_room == "outside" and expansion_v40:
		var v40_interaction := expansion_v40.get_interaction(player.position)
		if not v40_interaction.is_empty():
			return v40_interaction
	return super._get_near_interaction()

func _handle_interaction(data: Dictionary) -> void:
	var kind := String(data.get("type", ""))
	match kind:
		"v40_sign":
			ui.show_message("South Trail: west leads to Sunset Coast, east climbs toward Cedar Ridge. Trail carts connect both regions back to Willow Grove.")
			return
		"v40_cart_grove":
			_v40_fast_travel(Vector2(610, 3000), "Sunset Coast")
			return
		"v40_cart_coast", "v40_cart_ridge":
			_v40_fast_travel(Vector2(1085, 2205), "Willow Grove")
			return
		"v40_theo":
			_handle_v40_theo()
			return
		"v40_oren":
			_handle_v40_oren()
			return
		"v40_mira":
			_handle_v40_mira()
			return
		"v40_debris":
			_handle_v40_debris(String(data.get("id", "")))
			return
		"v40_relic":
			_handle_v40_relic(String(data.get("id", "")))
			return
		"v40_chest":
			_handle_v40_chest(String(data.get("id", "")))
			return
		"v40_tidepool":
			_handle_v40_tidepool()
			return
		"v40_shrine":
			_handle_v40_shrine()
			return
	super._handle_interaction(data)

func _v40_fast_travel(destination: Vector2, label: String) -> void:
	player.set_virtual_move(Vector2.ZERO)
	player.position = destination
	player.facing = Vector2.DOWN
	if player.camera:
		player.camera.reset_smoothing()
	minute_of_day = mini(23 * 60 + 30, minute_of_day + 20)
	farm.set_time(minute_of_day)
	_update_ui()
	ui.show_message("Trail Cart → %s. Travel time: 20 minutes." % label)

func _handle_v40_theo() -> void:
	if v40_market_day == farm.current_day:
		ui.show_message("Theo: That's all I packed for today. I'll restock the bundle tomorrow.")
		return
	if money < 140:
		ui.show_message("Theo: Today's expedition bundle costs 140g: one of each seed plus a trail snack.")
		return
	money -= 140
	seed_inventory["turnip"] = int(seed_inventory.get("turnip", 0)) + 1
	seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 1
	seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 1
	energy = mini(100, energy + 12)
	v40_market_day = farm.current_day
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()
	ui.show_message("Theo's bundle: -140g, +1 Turnip Seed, +1 Carrot Seed, +1 Corn Seed and +12 Energy.")

func _handle_v40_oren() -> void:
	if v40_oren_stage == 0:
		v40_oren_stage = 1
		v40_oren_progress = v40_debris.size()
		if v40_oren_progress >= 5:
			v40_oren_stage = 2
			ui.show_message("Oren: You already cleared the whole shoreline. Talk to me again and I'll settle the reward.")
		else:
			ui.show_message("Oren: Storm debris washed onto the coast. Clear all 5 marked piles and I'll pay for the help.")
	elif v40_oren_stage == 1:
		ui.show_message("Oren: Coast cleanup %d/5. Check the sand, tide pools and lower trail." % v40_oren_progress)
	elif v40_oren_stage == 2:
		v40_oren_stage = 3
		money += 520
		seed_inventory["turnip"] = int(seed_inventory.get("turnip", 0)) + 2
		energy = mini(100, energy + 15)
		inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
		_update_ui()
		ui.show_message("Oren: Coast restored. +520g, +2 Turnip Seeds and +15 Energy.")
	else:
		ui.show_message("Oren: The tide pool changes every morning. It's worth checking once a day.")

func _handle_v40_debris(id: String) -> void:
	if id.is_empty() or v40_debris.has(id):
		return
	v40_debris[id] = true
	money += 22
	if v40_oren_stage == 1:
		v40_oren_progress = mini(5, v40_oren_progress + 1)
		if v40_oren_progress >= 5:
			v40_oren_stage = 2
			ui.show_message("Shoreline cleared 5/5. +22g. Return to Oren for the full reward.")
		else:
			ui.show_message("Cleared storm debris. +22g · Coast cleanup %d/5." % v40_oren_progress)
	else:
		ui.show_message("You clear useful salvage from the shoreline. +22g.")
	_sync_v40_state()
	_update_ui()

func _handle_v40_mira() -> void:
	if v40_mira_stage == 0:
		v40_mira_stage = 1
		v40_mira_progress = v40_relics.size()
		if v40_mira_progress >= 4:
			v40_mira_stage = 2
			ui.show_message("Mira: You already found every fragment. Bring them here and we'll restore the inscription.")
		else:
			ui.show_message("Mira: Four relic fragments are scattered through Cedar Ridge. Find all 4 before the moss swallows them again.")
	elif v40_mira_stage == 1:
		ui.show_message("Mira: Relic fragments %d/4. Search pillars, pond edge, lower ruins and the eastern cliff." % v40_mira_progress)
	elif v40_mira_stage == 2:
		v40_mira_stage = 3
		money += 760
		seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 2
		seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 1
		inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
		_update_ui()
		ui.show_message("Mira: The inscription is whole again. +760g, +2 Corn Seeds, +1 Carrot Seed. The Moon Shrine is awake now.")
	else:
		ui.show_message("Mira: The Moon Shrine responds once each day now. Try it when you need a little luck.")

func _handle_v40_relic(id: String) -> void:
	if id.is_empty() or v40_relics.has(id):
		return
	v40_relics[id] = true
	money += 35
	if v40_mira_stage == 1:
		v40_mira_progress = mini(4, v40_mira_progress + 1)
		if v40_mira_progress >= 4:
			v40_mira_stage = 2
			ui.show_message("Relic fragment 4/4 recovered. +35g. Return to Mira at the ruins camp.")
		else:
			ui.show_message("Relic fragment recovered. +35g · Mira %d/4." % v40_mira_progress)
	else:
		ui.show_message("You recover an old Cedar Ridge fragment. +35g.")
	_sync_v40_state()
	_update_ui()

func _handle_v40_chest(id: String) -> void:
	if id.is_empty() or v40_chests.has(id):
		return
	v40_chests[id] = true
	if id == "coast":
		money += 260
		seed_inventory["turnip"] = int(seed_inventory.get("turnip", 0)) + 2
		ui.show_message("Sunset Coast chest: +260g and +2 Turnip Seeds.")
	else:
		money += 320
		seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 1
		energy = mini(100, energy + 20)
		ui.show_message("Cedar Ridge chest: +320g, +1 Corn Seed and +20 Energy.")
	_sync_v40_state()
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()

func _handle_v40_tidepool() -> void:
	if v40_tide_day == farm.current_day:
		ui.show_message("The tide pool has been searched today. New shells and small catches return tomorrow.")
		return
	v40_tide_day = farm.current_day
	money += 70
	energy = mini(100, energy + 6)
	v40_daily["tidepool"] = true
	_sync_v40_state()
	_update_ui()
	ui.show_message("Tide pool find: +70g in shells and +6 Energy.")

func _handle_v40_shrine() -> void:
	if v40_mira_stage < 3:
		ui.show_message("The Moon Shrine is silent. Mira may know how to restore the old inscription.")
		return
	if v40_shrine_day == farm.current_day:
		ui.show_message("The Moon Shrine's glow has faded for today.")
		return
	v40_shrine_day = farm.current_day
	var crops: Array[String] = ["turnip", "carrot", "corn"]
	var crop := crops[(farm.current_day + v40_relics.size()) % crops.size()]
	seed_inventory[crop] = int(seed_inventory.get(crop, 0)) + 1
	energy = mini(100, energy + 10)
	v40_daily["shrine"] = true
	_sync_v40_state()
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()
	ui.show_message("Moon Shrine blessing: +1 %s Seed and +10 Energy." % crop.capitalize())

func _handle_v33_nora() -> void:
	# Keep Nora's original Willow Grove quest intact. After it is complete she
	# becomes the guide for the larger v4.0 expedition survey.
	if v33_quest_stage < 3:
		super._handle_v33_nora()
		return
	if v40_nora_stage == 0:
		v40_nora_stage = 1
		v40_nora_progress = _v40_required_survey_count()
		if v40_nora_progress >= 3:
			v40_nora_stage = 2
			ui.show_message("Nora: You've already mapped the three key regions. Talk to me once more for the survey reward.")
		else:
			ui.show_message("Nora: The south trail has opened. Discover South Crossroads, Sunset Coast and Cedar Ruins, then report back.")
	elif v40_nora_stage == 1:
		v40_nora_progress = _v40_required_survey_count()
		if v40_nora_progress >= 3:
			v40_nora_stage = 2
			ui.show_message("Nora: Survey 3/3 complete. Talk to me again and I'll fund your next expedition.")
		else:
			ui.show_message("Nora: Expedition survey %d/3. Crossroads, Coast, Cedar Ruins." % v40_nora_progress)
	elif v40_nora_stage == 2:
		v40_nora_stage = 3
		money += 620
		seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 2
		seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 2
		inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
		_update_ui()
		ui.show_message("Nora: Excellent field map. +620g, +2 Carrot Seeds and +2 Corn Seeds.")
	else:
		ui.show_message("Nora: Greenfield is larger than the farm now. Keep checking the coast, ruins and daily landmarks.")

func _check_v40_discoveries() -> void:
	for item in V40_DISCOVERIES:
		var id := String(item["id"])
		if v40_discovered.has(id):
			continue
		var pos: Vector2 = item["pos"]
		if player.position.distance_to(pos) > 130.0:
			continue
		v40_discovered[id] = true
		money += 30
		v40_nora_progress = _v40_required_survey_count()
		if v40_nora_stage == 1 and v40_nora_progress >= 3:
			v40_nora_stage = 2
		if v40_discovered.size() >= V40_DISCOVERIES.size() and not v40_discovery_bonus_claimed:
			v40_discovery_bonus_claimed = true
			money += 250
			seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 2
			inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
			_update_ui()
			ui.show_message("Discovery Journal complete 5/5! +250g and +2 Corn Seeds.")
		else:
			_update_ui()
			ui.show_message("Discovered: %s · +30g · Journal %d/5." % [String(item["name"]), v40_discovered.size()])
		break

func _v40_required_survey_count() -> int:
	var count := 0
	for id in ["south_crossroads", "sunset_coast", "cedar_ruins"]:
		if v40_discovered.has(id):
			count += 1
	return count

func _start_next_day(from_midnight: bool) -> void:
	super._start_next_day(from_midnight)
	v40_daily_day = farm.current_day
	v40_daily.clear()
	_sync_v40_state()

func _quest_text() -> String:
	var text := ""
	if v40_nora_stage == 1:
		text = "Survey %d/3" % _v40_required_survey_count()
	if v40_oren_stage == 1:
		text += (" · " if not text.is_empty() else "") + "Coast %d/5" % v40_oren_progress
	if v40_mira_stage == 1:
		text += (" · " if not text.is_empty() else "") + "Relics %d/4" % v40_mira_progress
	if not text.is_empty():
		return "Expedition · " + text
	if v40_oren_stage == 2:
		return "Expedition · Return to Oren"
	if v40_mira_stage == 2:
		return "Expedition · Return to Mira"
	if v40_nora_stage == 2:
		return "Expedition · Return to Nora"
	return super._quest_text()

func _sync_v40_state() -> void:
	if expansion_v40:
		expansion_v40.set_state(v40_debris, v40_relics, v40_chests, v40_daily)

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
	parsed["save_version"] = maxi(40, int(parsed.get("save_version", 0)))
	parsed["v40_expedition"] = {
		"debris": v40_debris,
		"relics": v40_relics,
		"chests": v40_chests,
		"daily": v40_daily,
		"discovered": v40_discovered,
		"daily_day": v40_daily_day,
		"market_day": v40_market_day,
		"tide_day": v40_tide_day,
		"shrine_day": v40_shrine_day,
		"oren_stage": v40_oren_stage,
		"oren_progress": v40_oren_progress,
		"mira_stage": v40_mira_stage,
		"mira_progress": v40_mira_progress,
		"nora_stage": v40_nora_stage,
		"nora_progress": v40_nora_progress,
		"discovery_bonus": v40_discovery_bonus_claimed
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
	var data = parsed.get("v40_expedition", {})
	if typeof(data) == TYPE_DICTIONARY:
		var a = data.get("debris", {})
		var b = data.get("relics", {})
		var c = data.get("chests", {})
		var d = data.get("daily", {})
		var e = data.get("discovered", {})
		v40_debris = a.duplicate(true) if typeof(a) == TYPE_DICTIONARY else {}
		v40_relics = b.duplicate(true) if typeof(b) == TYPE_DICTIONARY else {}
		v40_chests = c.duplicate(true) if typeof(c) == TYPE_DICTIONARY else {}
		v40_daily = d.duplicate(true) if typeof(d) == TYPE_DICTIONARY else {}
		v40_discovered = e.duplicate(true) if typeof(e) == TYPE_DICTIONARY else {}
		v40_daily_day = int(data.get("daily_day", farm.current_day))
		v40_market_day = int(data.get("market_day", 0))
		v40_tide_day = int(data.get("tide_day", 0))
		v40_shrine_day = int(data.get("shrine_day", 0))
		v40_oren_stage = int(data.get("oren_stage", 0))
		v40_oren_progress = int(data.get("oren_progress", 0))
		v40_mira_stage = int(data.get("mira_stage", 0))
		v40_mira_progress = int(data.get("mira_progress", 0))
		v40_nora_stage = int(data.get("nora_stage", 0))
		v40_nora_progress = int(data.get("nora_progress", 0))
		v40_discovery_bonus_claimed = bool(data.get("discovery_bonus", false))

	if v40_daily_day != farm.current_day:
		v40_daily_day = farm.current_day
		v40_daily.clear()
	_apply_v40_world_camera()
	_sync_v40_state()
	_update_ui()
