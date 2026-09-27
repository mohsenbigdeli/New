extends "res://scripts/main_v24.gd"

# v2.5: a persistent Town Request Board that turns the existing farming,
# fishing, mining and shipping loops into a longer progression path.
var board_button: Button
var board_panel: Panel
var board_title_label: Label
var board_objective_label: Label
var board_progress_label: Label
var board_reward_label: Label
var board_reputation_label: Label
var board_hint_label: Label
var board_close_button: Button

var board_contract: Dictionary = {}
var board_progress := 0
var board_reputation := 0
var board_completed := 0
var board_started_day := 1
var board_last_completed_day := 0

const BOARD_CONTRACTS := [
	{
		"id":"turnip_order",
		"kind":"harvest",
		"item":"turnip",
		"title":"Willow Kitchen Order",
		"description":"Harvest fresh turnips for the town kitchen.",
		"target":4,
		"reward":220
	},
	{
		"id":"carrot_order",
		"kind":"harvest",
		"item":"carrot",
		"title":"Market Carrot Crate",
		"description":"Harvest carrots for Lina's market stand.",
		"target":3,
		"reward":290
	},
	{
		"id":"corn_order",
		"kind":"harvest",
		"item":"corn",
		"title":"Barn Corn Reserve",
		"description":"Harvest corn for Marnie's winter reserve.",
		"target":2,
		"reward":380
	},
	{
		"id":"angler_order",
		"kind":"fish",
		"item":"fish",
		"title":"Pond & River Catch",
		"description":"Catch fish for the Greenfield supper table.",
		"target":2,
		"reward":340
	},
	{
		"id":"copper_order",
		"kind":"mine",
		"item":"copper",
		"title":"Copper for the Smith",
		"description":"Bring up Copper Ore from the Old Mine.",
		"target":2,
		"reward":420
	},
	{
		"id":"shipping_order",
		"kind":"ship",
		"item":"any",
		"title":"Shipping Bin Challenge",
		"description":"Ship any mix of crops, fish or mine goods.",
		"target":5,
		"reward":310
	}
]

func _ready() -> void:
	super()
	_build_contract_board()
	_ensure_board_contract()
	_refresh_contract_board()
	ui.show_message("v2.5 Town Board: persistent farming, fishing, mining and shipping contracts now build Greenfield Reputation.")

func _process(delta: float) -> void:
	super(delta)
	if board_panel and board_panel.visible and player:
		player.set_controls_locked(true)

func _register_quest_harvest(crop: String) -> void:
	super._register_quest_harvest(crop)
	_advance_board_contract("harvest", crop, 1)

func _on_fishing_finished(success: bool, bait_was_used: bool) -> void:
	var before := int(produce_inventory.get("fish", 0))
	super._on_fishing_finished(success, bait_was_used)
	var gained := maxi(0, int(produce_inventory.get("fish", 0)) - before)
	if gained > 0:
		_advance_board_contract("fish", "fish", gained)

func _break_mine_rock(index: int) -> void:
	var before := int(produce_inventory.get("copper", 0))
	super._break_mine_rock(index)
	var gained := maxi(0, int(produce_inventory.get("copper", 0)) - before)
	if gained > 0:
		_advance_board_contract("mine", "copper", gained)

func _queue_shipping() -> void:
	var before := _pending_shipping_count()
	super._queue_shipping()
	var gained := maxi(0, _pending_shipping_count() - before)
	if gained > 0:
		_advance_board_contract("ship", "any", gained)

func _start_next_day(from_midnight: bool) -> void:
	super._start_next_day(from_midnight)
	_ensure_board_contract()
	_refresh_contract_board()

func _build_contract_board() -> void:
	board_button = Button.new()
	board_button.name = "TownBoardButton"
	board_button.text = "BOARD"
	board_button.focus_mode = Control.FOCUS_NONE
	board_button.add_theme_font_size_override("font_size", 9)
	board_button.add_theme_stylebox_override("normal", _board_style(Color(0.97, 0.90, 0.72, 0.96), Color(0.38, 0.27, 0.17, 0.70), 10))
	board_button.add_theme_stylebox_override("pressed", _board_style(Color(0.86, 0.74, 0.52, 0.98), Color(0.31, 0.22, 0.14, 0.84), 10))
	board_button.add_theme_color_override("font_color", Color("#4a3828"))
	board_button.z_index = 60
	board_button.pressed.connect(_open_contract_board)
	ui.add_child(board_button)

	board_panel = Panel.new()
	board_panel.name = "TownBoardPanel"
	board_panel.visible = false
	board_panel.z_index = 80
	board_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	board_panel.add_theme_stylebox_override("panel", _board_style(Color(0.985, 0.945, 0.835, 0.985), Color(0.34, 0.24, 0.15, 0.92), 22))
	ui.add_child(board_panel)

	board_title_label = Label.new()
	board_title_label.text = "GREENFIELD TOWN BOARD"
	board_title_label.position = Vector2(28, 24)
	board_title_label.size = Vector2(430, 34)
	board_title_label.add_theme_font_size_override("font_size", 22)
	board_title_label.add_theme_color_override("font_color", Color("#4a3828"))
	board_panel.add_child(board_title_label)

	board_objective_label = Label.new()
	board_objective_label.position = Vector2(28, 72)
	board_objective_label.size = Vector2(464, 86)
	board_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_objective_label.add_theme_font_size_override("font_size", 16)
	board_objective_label.add_theme_color_override("font_color", Color("#5a4430"))
	board_panel.add_child(board_objective_label)

	board_progress_label = Label.new()
	board_progress_label.position = Vector2(28, 166)
	board_progress_label.size = Vector2(240, 32)
	board_progress_label.add_theme_font_size_override("font_size", 17)
	board_progress_label.add_theme_color_override("font_color", Color("#4a3828"))
	board_panel.add_child(board_progress_label)

	board_reward_label = Label.new()
	board_reward_label.position = Vector2(28, 204)
	board_reward_label.size = Vector2(440, 30)
	board_reward_label.add_theme_font_size_override("font_size", 14)
	board_reward_label.add_theme_color_override("font_color", Color("#6e4c25"))
	board_panel.add_child(board_reward_label)

	board_reputation_label = Label.new()
	board_reputation_label.position = Vector2(28, 238)
	board_reputation_label.size = Vector2(440, 30)
	board_reputation_label.add_theme_font_size_override("font_size", 14)
	board_reputation_label.add_theme_color_override("font_color", Color("#325741"))
	board_panel.add_child(board_reputation_label)

	board_hint_label = Label.new()
	board_hint_label.position = Vector2(28, 276)
	board_hint_label.size = Vector2(356, 52)
	board_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_hint_label.add_theme_font_size_override("font_size", 11)
	board_hint_label.add_theme_color_override("font_color", Color("#6b5a48"))
	board_panel.add_child(board_hint_label)

	board_close_button = Button.new()
	board_close_button.text = "CLOSE"
	board_close_button.position = Vector2(396, 284)
	board_close_button.size = Vector2(96, 38)
	board_close_button.focus_mode = Control.FOCUS_NONE
	board_close_button.add_theme_font_size_override("font_size", 12)
	board_close_button.add_theme_stylebox_override("normal", _board_style(Color(0.80, 0.67, 0.46, 0.98), Color(0.34, 0.24, 0.15, 0.85), 10))
	board_close_button.add_theme_color_override("font_color", Color("#3b2b1d"))
	board_close_button.pressed.connect(_close_contract_board)
	board_panel.add_child(board_close_button)

	get_viewport().size_changed.connect(_layout_contract_board)
	_layout_contract_board()

func _board_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.08, 0.05, 0.03, 0.24)
	style.shadow_size = 5
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style

func _layout_contract_board() -> void:
	if not board_button or not board_panel:
		return
	var view_size := get_viewport().get_visible_rect().size
	board_button.size = Vector2(76, 23)
	board_button.position = Vector2(view_size.x - 134.0, 34.0)
	board_panel.size = Vector2(520, 342)
	board_panel.position = Vector2((view_size.x - board_panel.size.x) * 0.5, (view_size.y - board_panel.size.y) * 0.5)

func _open_contract_board() -> void:
	if inventory_ui and inventory_ui.is_open:
		inventory_ui.close_panel()
	if ui and ui.shop_open:
		_close_shop()
	if fishing_panel and fishing_panel.is_open:
		fishing_panel.close_panel()
	if crafting_panel and crafting_panel.is_open:
		crafting_panel.close_panel()
	if animal_panel and animal_panel.is_open:
		animal_panel.close_panel()
	board_panel.visible = true
	player.set_virtual_move(Vector2.ZERO)
	player.set_controls_locked(true)
	_refresh_contract_board()

func _close_contract_board() -> void:
	board_panel.visible = false
	if not ui.shop_open and not inventory_ui.is_open:
		player.set_controls_locked(false)
	player.set_virtual_move(Vector2.ZERO)

func _ensure_board_contract() -> void:
	if not board_contract.is_empty():
		return
	if farm.current_day <= board_last_completed_day:
		return
	var index := 0
	if board_completed > 0:
		index = int((farm.current_day * 3 + board_completed * 5 + board_reputation) % BOARD_CONTRACTS.size())
	board_contract = BOARD_CONTRACTS[index].duplicate(true)
	board_contract["reward"] = int(board_contract.get("reward", 200)) + board_reputation * 25
	board_progress = 0
	board_started_day = farm.current_day

func _advance_board_contract(kind: String, item: String, amount: int) -> void:
	if amount <= 0 or board_contract.is_empty():
		return
	if String(board_contract.get("kind", "")) != kind:
		return
	var wanted_item := String(board_contract.get("item", ""))
	if wanted_item != "any" and wanted_item != item:
		return
	var target := int(board_contract.get("target", 1))
	board_progress = mini(target, board_progress + amount)
	if board_progress >= target:
		_complete_board_contract()
	else:
		_refresh_contract_board()

func _complete_board_contract() -> void:
	if board_contract.is_empty():
		return
	var reward := int(board_contract.get("reward", 200))
	money += reward
	board_completed += 1
	board_reputation += 1
	board_last_completed_day = farm.current_day

	var milestone_text := ""
	if board_reputation % 3 == 0:
		seed_inventory["turnip"] = int(seed_inventory.get("turnip", 0)) + 2
		seed_inventory["carrot"] = int(seed_inventory.get("carrot", 0)) + 2
		seed_inventory["corn"] = int(seed_inventory.get("corn", 0)) + 1
		money += 150
		milestone_text = " Reputation milestone: +150g and a mixed seed pack."

	board_contract.clear()
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	_update_ui()
	_refresh_contract_board()
	ui.show_message("Town Board contract complete! +%dg · Reputation %d.%s New request arrives next morning." % [reward, board_reputation, milestone_text])

func _pending_shipping_count() -> int:
	var total := 0
	for key in shipping_pending.keys():
		total += int(shipping_pending.get(key, 0))
	return total

func _refresh_contract_board() -> void:
	if not board_button:
		return
	if board_contract.is_empty():
		board_button.text = "BOARD ✓"
		board_objective_label.text = "All current work is complete.\nA new town request will be posted the next morning."
		board_progress_label.text = "Progress: complete"
		board_reward_label.text = "Completed contracts: %d" % board_completed
	else:
		var target := int(board_contract.get("target", 1))
		board_button.text = "BOARD %d/%d" % [board_progress, target]
		board_objective_label.text = "%s\n%s" % [
			String(board_contract.get("title", "Town Request")),
			String(board_contract.get("description", "Help Greenfield."))
		]
		board_progress_label.text = "Progress: %d / %d" % [board_progress, target]
		board_reward_label.text = "Reward: %dg · Started on farm day %d" % [int(board_contract.get("reward", 0)), board_started_day]
	board_reputation_label.text = "Greenfield Reputation: %d   ·   Contracts completed: %d" % [board_reputation, board_completed]
	board_hint_label.text = "Contracts persist across days and saves. Every 3 Reputation grants +150g and a mixed Turnip/Carrot/Corn seed pack."

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
	parsed["save_version"] = maxi(25, int(parsed.get("save_version", 0)))
	parsed["v25_town_board"] = {
		"contract": board_contract,
		"progress": board_progress,
		"reputation": board_reputation,
		"completed": board_completed,
		"started_day": board_started_day,
		"last_completed_day": board_last_completed_day
	}
	var output := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify(parsed))
		ui.show_message("Game saved with Town Board contract and Reputation progress.")

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
	var board_data = parsed.get("v25_town_board", {})
	if typeof(board_data) == TYPE_DICTIONARY:
		var saved_contract = board_data.get("contract", {})
		if typeof(saved_contract) == TYPE_DICTIONARY:
			board_contract = saved_contract.duplicate(true)
		else:
			board_contract = {}
		board_progress = int(board_data.get("progress", 0))
		board_reputation = int(board_data.get("reputation", 0))
		board_completed = int(board_data.get("completed", 0))
		board_started_day = int(board_data.get("started_day", farm.current_day))
		board_last_completed_day = int(board_data.get("last_completed_day", 0))
	else:
		board_contract = {}
		board_progress = 0
		board_reputation = 0
		board_completed = 0
		board_started_day = farm.current_day
		board_last_completed_day = 0

	if not board_contract.is_empty():
		board_progress = clampi(board_progress, 0, int(board_contract.get("target", 1)))
	_ensure_board_contract()
	_refresh_contract_board()
	ui.show_message("Game loaded with Greenfield Town Board progress restored.")
