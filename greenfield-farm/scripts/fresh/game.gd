extends Node2D

@onready var player: FreshPlayer = $World/Player
@onready var joystick = $HUD/Joystick
@onready var use_button: Button = $HUD/UseButton
@onready var message_box: Panel = $HUD/MessageBox
@onready var message_label: Label = $HUD/MessageBox/Message
@onready var title_label: Label = $HUD/TitleCard/Title
@onready var resource_label: Label = $HUD/ResourceCard/Resources
@onready var energy_bar: ProgressBar = $HUD/EnergyCard/EnergyBar
@onready var energy_text: Label = $HUD/EnergyCard/EnergyText
@onready var objective_label: Label = $HUD/ObjectiveCard/Objective
@onready var fade: ColorRect = $HUD/ScreenFade
@onready var day_tint: CanvasModulate = $World/DayTint

const SAVE_PATH := "user://greenfield_farm_v1.json"
const MAX_ENERGY := 100
const DAY_START := 8 * 60
const DAY_END := 22 * 60
const TIME_RATE := 2.0
const SEED_PACK_PRICE := 50
const SEED_PACK_SIZE := 5
const CROP_PRICE := 55

var day := 1
var time_minutes := float(DAY_START)
var money := 180
var seeds := 8
var harvested_crops := 0
var pending_shipping := 0
var shipped_total := 0
var energy := MAX_ENERGY
var well_used_day := 0
var quest_rewarded := false
var message_serial := 0
var sleeping := false
var hud_tick := 0.0

func _ready() -> void:
	joystick.move_changed.connect(player.set_touch_move)
	use_button.pressed.connect(player.interact)
	player.interaction_result.connect(_on_interaction_result)
	_load_game()
	_update_hud()
	_show_message("A new season begins. Till, plant, water, harvest, then ship your crops.", 4.8)

func _process(delta: float) -> void:
	if sleeping:
		return
	time_minutes += delta * TIME_RATE
	if time_minutes >= DAY_END:
		_sleep(true)
		return
	hud_tick += delta
	if hud_tick >= 0.20:
		hud_tick = 0.0
		_update_hud()
		_update_day_tint()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			player.interact()

func _on_interaction_result(data: Dictionary) -> void:
	if data.get("kind", "") == "plot":
		_handle_plot(data.get("target"))
		return

	var action := String(data.get("action", ""))
	match action:
		"shop":
			_buy_seeds()
			return
		"shipping":
			_ship_crops()
			return
		"sleep":
			_sleep(false)
			return
		"well":
			_use_well()
			return
		"marnie":
			_talk_marnie()
			return

	var text := String(data.get("message", ""))
	if not text.is_empty():
		_show_message(text)

func _handle_plot(target) -> void:
	if target == null or not is_instance_valid(target) or not target is FreshPlot:
		return
	var plot: FreshPlot = target
	var action := plot.next_action()
	match action:
		"till":
			if _spend_energy(4):
				plot.apply_action("till")
				_show_message("You tilled the soil. It is ready for seed.")
		"plant":
			if seeds <= 0:
				_show_message("No seeds left. Buy a pack from Rowan by the market tent.")
			elif _spend_energy(2):
				seeds -= 1
				plot.apply_action("plant")
				_show_message("Turnip seed planted.")
		"water":
			if _spend_energy(2):
				plot.apply_action("water")
				_show_message("Watered. Growth advances when you sleep.")
		"wait":
			_show_message("This crop is watered for today. Check it tomorrow.")
		"harvest":
			if _spend_energy(1):
				plot.apply_action("harvest")
				harvested_crops += 1
				_show_message("Harvested a turnip! Put crops in the shipping bin for tomorrow's pay.")
	_update_hud()

func _spend_energy(cost: int) -> bool:
	if energy < cost:
		_show_message("You're exhausted. Rest at the farmhouse or use the well once today.")
		return false
	energy = maxi(0, energy - cost)
	return true

func _buy_seeds() -> void:
	if money < SEED_PACK_PRICE:
		_show_message("Rowan: A seed pack costs %dg. You need a little more gold." % SEED_PACK_PRICE)
		return
	money -= SEED_PACK_PRICE
	seeds += SEED_PACK_SIZE
	_show_message("Rowan: Five turnip seeds for %dg. Good luck out there!" % SEED_PACK_PRICE)
	_update_hud()

func _ship_crops() -> void:
	if harvested_crops <= 0:
		_show_message("The shipping bin is empty. Harvested crops can be placed here.")
		return
	var amount := harvested_crops
	pending_shipping += amount
	harvested_crops = 0
	_show_message("Placed %d crop%s in the shipping bin. Payment arrives tomorrow morning." % [amount, "s" if amount != 1 else ""])
	_update_hud()

func _use_well() -> void:
	if well_used_day == day:
		_show_message("You've already taken a break at the well today.")
		return
	if energy >= MAX_ENERGY:
		_show_message("You feel rested already.")
		return
	well_used_day = day
	energy = mini(MAX_ENERGY, energy + 25)
	_show_message("Cool water and a short rest restore 25 energy.")
	_update_hud()

func _talk_marnie() -> void:
	if shipped_total >= 3 and not quest_rewarded:
		quest_rewarded = true
		money += 150
		_show_message("Marnie: You shipped your first three crops! Here's 150g to help expand the farm.", 4.6)
	elif quest_rewarded:
		_show_message("Marnie: Keep a few seeds in reserve, and water every growth day.")
	elif shipped_total == 0:
		_show_message("Marnie: Your first goal is simple — grow and ship three turnips.")
	else:
		_show_message("Marnie: You're getting there. %d of 3 crops shipped." % mini(shipped_total, 3))
	_update_hud()

func _sleep(forced: bool = false) -> void:
	if sleeping:
		return
	sleeping = true
	player.set_touch_move(Vector2.ZERO)
	player.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.35)
	await tween.finished

	var payout := pending_shipping * CROP_PRICE
	var sold := pending_shipping
	money += payout
	shipped_total += sold
	pending_shipping = 0
	day += 1
	time_minutes = float(DAY_START)
	energy = MAX_ENERGY
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		if plot is FreshPlot:
			plot.new_day()
	player.global_position = Vector2(760, 450)
	_save_game()
	_update_hud()
	_update_day_tint()

	var tween_in := create_tween()
	tween_in.tween_property(fade, "color:a", 0.0, 0.45)
	await tween_in.finished
	player.set_physics_process(true)
	sleeping = false
	if sold > 0:
		_show_message("Day %d. The shipping box earned %dg overnight." % [day, payout], 4.2)
	elif forced:
		_show_message("You made it home late. A full night's rest restores your energy.", 4.2)
	else:
		_show_message("Day %d. A fresh morning on Greenfield Farm." % day, 3.8)

func _update_hud() -> void:
	var total := int(time_minutes)
	var hour := total / 60
	var minute := (total % 60) / 10 * 10
	title_label.text = "SPRING %02d   %02d:%02d" % [day, hour, minute]
	resource_label.text = "%dg   SEED %d   CROP %d   SHIP %d" % [money, seeds, harvested_crops, pending_shipping]
	energy_bar.value = energy
	energy_text.text = "ENERGY  %d/%d" % [energy, MAX_ENERGY]
	if quest_rewarded:
		objective_label.text = "FARM GOAL  •  Grow, sell, and expand"
	else:
		objective_label.text = "FIRST HARVEST  •  Ship 3 turnips  %d/3" % mini(shipped_total, 3)

func _update_day_tint() -> void:
	var tint := Color(1, 1, 1, 1)
	if time_minutes < 10 * 60:
		var morning_t := clampf((time_minutes - DAY_START) / 120.0, 0.0, 1.0)
		tint = Color(0.90, 0.92, 1.0, 1.0).lerp(Color(1, 1, 1, 1), morning_t)
	elif time_minutes > 17 * 60:
		var evening_t := clampf((time_minutes - 17 * 60) / 300.0, 0.0, 1.0)
		tint = Color(1, 1, 1, 1).lerp(Color(0.53, 0.62, 0.82, 1.0), evening_t)
	day_tint.color = tint

func _show_message(text: String, hold_seconds: float = 3.4) -> void:
	if text.is_empty():
		return
	message_serial += 1
	var serial := message_serial
	message_label.text = text
	message_box.visible = true
	message_box.modulate.a = 1.0
	await get_tree().create_timer(hold_seconds).timeout
	if serial != message_serial:
		return
	var tween := create_tween()
	tween.tween_property(message_box, "modulate:a", 0.0, 0.18)
	await tween.finished
	if serial == message_serial:
		message_box.visible = false
		message_box.modulate.a = 1.0

func _save_game() -> void:
	var plot_data := {}
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		if plot is FreshPlot:
			plot_data[String(plot.name)] = plot.get_save_data()
	var data := {
		"day": day,
		"time": time_minutes,
		"money": money,
		"seeds": seeds,
		"harvested": harvested_crops,
		"pending_shipping": pending_shipping,
		"shipped_total": shipped_total,
		"energy": energy,
		"well_used_day": well_used_day,
		"quest_rewarded": quest_rewarded,
		"plots": plot_data
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	day = maxi(1, int(data.get("day", 1)))
	time_minutes = float(data.get("time", DAY_START))
	if time_minutes >= DAY_END:
		time_minutes = float(DAY_START)
	money = int(data.get("money", 180))
	seeds = int(data.get("seeds", 8))
	harvested_crops = int(data.get("harvested", 0))
	pending_shipping = int(data.get("pending_shipping", 0))
	shipped_total = int(data.get("shipped_total", 0))
	energy = int(data.get("energy", MAX_ENERGY))
	well_used_day = int(data.get("well_used_day", 0))
	quest_rewarded = bool(data.get("quest_rewarded", false))
	var saved_plots = data.get("plots", {})
	if saved_plots is Dictionary:
		for plot in get_tree().get_nodes_in_group("farm_plots"):
			if plot is FreshPlot and saved_plots.has(String(plot.name)):
				plot.load_save_data(saved_plots[String(plot.name)])
	_update_day_tint()
