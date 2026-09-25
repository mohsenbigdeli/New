extends CanvasLayer
class_name GameUI

signal tool_selected(index: int)
signal action_pressed
signal move_changed(dir: Vector2)
signal save_pressed
signal load_pressed
signal buy_seed_pressed(crop: String)
signal sell_all_pressed
signal close_shop_pressed

var day_label: Label
var time_label: Label
var money_label: Label
var weather_label: Label
var energy_label: Label
var inventory_label: Label
var message_label: Label
var quest_label: Label
var tool_buttons: Array[Button] = []
var movement_state := {"left": false, "right": false, "up": false, "down": false}

var shop_panel: ColorRect
var shop_money_label: Label
var shop_inventory_label: Label
var shop_open := false

func _ready() -> void:
	layer = 10
	_build_top_bar()
	_build_quest_panel()
	_build_hotbar()
	_build_mobile_controls()
	_build_shop()

func _make_panel(rect: Rect2, alpha := 0.84) -> ColorRect:
	var panel := ColorRect.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.color = Color(0.075,0.085,0.075,alpha)
	add_child(panel)
	return panel

func _make_label(parent: Node, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _build_top_bar() -> void:
	var p := _make_panel(Rect2(18,14,820,96), 0.86)
	day_label = _make_label(p, Vector2(16,10), 21)
	time_label = _make_label(p, Vector2(128,10), 21)
	money_label = _make_label(p, Vector2(252,10), 21)
	weather_label = _make_label(p, Vector2(376,10), 20)
	energy_label = _make_label(p, Vector2(530,10), 20)
	inventory_label = _make_label(p, Vector2(16,42), 16)
	message_label = _make_label(p, Vector2(16,68), 14)
	message_label.size = Vector2(780,24)

	var save := Button.new()
	save.text = "SAVE"
	save.position = Vector2(1088,18)
	save.size = Vector2(80,48)
	add_child(save)
	save.pressed.connect(_on_save_button_pressed)

	var load := Button.new()
	load.text = "LOAD"
	load.position = Vector2(1176,18)
	load.size = Vector2(80,48)
	add_child(load)
	load.pressed.connect(_on_load_button_pressed)

func _build_quest_panel() -> void:
	var p := _make_panel(Rect2(850,14,220,96), 0.80)
	var title := _make_label(p, Vector2(12,8), 15)
	title.text = "TOWN REQUEST"
	quest_label = _make_label(p, Vector2(12,34), 14)
	quest_label.size = Vector2(198,54)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_hotbar() -> void:
	var names := ["Hoe", "Turnip", "Carrot", "Corn", "Water", "Harvest"]
	var p := _make_panel(Rect2(284,638,770,72), 0.88)
	for i in range(names.size()):
		var b := Button.new()
		b.text = "%d %s" % [i+1, names[i]]
		b.position = Vector2(8 + i*127, 8)
		b.size = Vector2(119,56)
		b.add_theme_font_size_override("font_size",15)
		b.pressed.connect(_on_tool_button_pressed.bind(i))
		p.add_child(b)
		tool_buttons.append(b)

func _build_mobile_controls() -> void:
	_add_move_button("↑", Vector2(102,532), "up")
	_add_move_button("↓", Vector2(102,644), "down")
	_add_move_button("←", Vector2(22,588), "left")
	_add_move_button("→", Vector2(182,588), "right")

	var action := Button.new()
	action.text = "USE"
	action.position = Vector2(1110,568)
	action.size = Vector2(130,112)
	action.add_theme_font_size_override("font_size",26)
	add_child(action)
	action.pressed.connect(_on_action_button_pressed)

func _add_move_button(text: String, pos: Vector2, key: String) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(78,68)
	b.add_theme_font_size_override("font_size",28)
	add_child(b)
	b.button_down.connect(_set_move.bind(key, true))
	b.button_up.connect(_set_move.bind(key, false))

func _build_shop() -> void:
	shop_panel = ColorRect.new()
	shop_panel.position = Vector2(345,125)
	shop_panel.size = Vector2(590,470)
	shop_panel.color = Color(0.10,0.11,0.09,0.97)
	shop_panel.visible = false
	add_child(shop_panel)

	var title := _make_label(shop_panel, Vector2(28,20), 30)
	title.text = "Willow General Store"
	var sub := _make_label(shop_panel, Vector2(28,61), 15)
	sub.text = "Seeds, supplies and produce trading"
	shop_money_label = _make_label(shop_panel, Vector2(430,28), 22)
	shop_inventory_label = _make_label(shop_panel, Vector2(28,104), 17)
	shop_inventory_label.size = Vector2(530,60)
	shop_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_add_shop_buy_button("Turnip Seed", "turnip", Vector2(28,182))
	_add_shop_buy_button("Carrot Seed", "carrot", Vector2(208,182))
	_add_shop_buy_button("Corn Seed", "corn", Vector2(388,182))

	var sell := Button.new()
	sell.text = "SELL ALL HARVEST"
	sell.position = Vector2(28,286)
	sell.size = Vector2(532,64)
	sell.add_theme_font_size_override("font_size",20)
	shop_panel.add_child(sell)
	sell.pressed.connect(_on_sell_all_pressed)

	var hint := _make_label(shop_panel, Vector2(28,365), 14)
	hint.text = "Tip: the shipping bin near the farm sells produce too."

	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(390,402)
	close.size = Vector2(170,48)
	shop_panel.add_child(close)
	close.pressed.connect(_on_close_shop_pressed)

func _add_shop_buy_button(label_text: String, crop: String, pos: Vector2) -> void:
	var b := Button.new()
	b.name = "Buy_%s" % crop
	b.text = label_text
	b.position = pos
	b.size = Vector2(164,78)
	b.add_theme_font_size_override("font_size",16)
	shop_panel.add_child(b)
	b.pressed.connect(_on_buy_pressed.bind(crop))

func _set_move(key: String, pressed: bool) -> void:
	if shop_open:
		return
	movement_state[key] = pressed
	var x := int(movement_state["right"]) - int(movement_state["left"])
	var y := int(movement_state["down"]) - int(movement_state["up"])
	move_changed.emit(Vector2(x,y).normalized())

func _on_tool_button_pressed(index: int) -> void:
	if not shop_open:
		tool_selected.emit(index)

func _on_action_button_pressed() -> void:
	if not shop_open:
		action_pressed.emit()

func _on_save_button_pressed() -> void:
	if not shop_open:
		save_pressed.emit()

func _on_load_button_pressed() -> void:
	if not shop_open:
		load_pressed.emit()

func _on_buy_pressed(crop: String) -> void:
	buy_seed_pressed.emit(crop)

func _on_sell_all_pressed() -> void:
	sell_all_pressed.emit()

func _on_close_shop_pressed() -> void:
	close_shop_pressed.emit()

func open_shop(current_money: int, seed_prices: Dictionary, sell_prices: Dictionary, produce: Dictionary) -> void:
	shop_open = true
	shop_panel.visible = true
	refresh_shop(current_money, seed_prices, sell_prices, produce)
	show_message("Store opened.")

func close_shop() -> void:
	shop_open = false
	shop_panel.visible = false
	for key in movement_state.keys():
		movement_state[key] = false
	move_changed.emit(Vector2.ZERO)
	show_message("Back to Greenfield.")

func refresh_shop(current_money: int, seed_prices: Dictionary, sell_prices: Dictionary, produce: Dictionary) -> void:
	shop_money_label.text = "%dg" % current_money
	shop_inventory_label.text = "Harvest: Turnip %d · Carrot %d · Corn %d\nSell prices: %dg / %dg / %dg" % [
		int(produce.get("turnip",0)), int(produce.get("carrot",0)), int(produce.get("corn",0)),
		int(sell_prices.get("turnip",0)), int(sell_prices.get("carrot",0)), int(sell_prices.get("corn",0))
	]
	for crop in ["turnip","carrot","corn"]:
		var b := shop_panel.get_node_or_null("Buy_%s" % crop) as Button
		if b:
			b.text = "%s Seed\n%dg" % [crop.capitalize(), int(seed_prices.get(crop,0))]

func update_status(day: int, minute_of_day: int, current_money: int, current_weather: String, seeds: Dictionary, produce: Dictionary, selected: int, energy: int, quest_started: bool, quest_complete: bool, quest_turnips: int) -> void:
	var hour := int(minute_of_day / 60)
	var minute := int(minute_of_day % 60)
	day_label.text = "Day %d" % day
	time_label.text = "%02d:%02d" % [hour, minute]
	money_label.text = "%dg" % current_money
	weather_label.text = current_weather
	energy_label.text = "Energy %d" % energy
	inventory_label.text = "Seeds  T:%d C:%d Corn:%d    Harvest  T:%d C:%d Corn:%d" % [
		int(seeds.get("turnip",0)), int(seeds.get("carrot",0)), int(seeds.get("corn",0)),
		int(produce.get("turnip",0)), int(produce.get("carrot",0)), int(produce.get("corn",0))
	]
	if not quest_started:
		quest_label.text = "Talk to Mayor Rowan in town."
	elif quest_complete:
		quest_label.text = "Rowan: Complete!\nReward received: 300g"
	else:
		quest_label.text = "Harvest 5 turnips\nProgress: %d / 5" % quest_turnips
	for i in range(tool_buttons.size()):
		tool_buttons[i].modulate = Color("#ffe78a") if i == selected else Color.WHITE

func show_message(text: String) -> void:
	if message_label:
		message_label.text = text
