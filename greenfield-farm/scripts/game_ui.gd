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
var energy_bar: ProgressBar
var inventory_label: Label
var message_label: Label
var quest_label: Label
var tool_buttons: Array[Button] = []
var movement_state := {"left": false, "right": false, "up": false, "down": false}

var shop_panel: Panel
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

func _panel_style(fill: Color, border: Color, radius: int = 12, border_width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.08,0.05,0.03,0.30)
	style.shadow_size = 6
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(fill, border, 10, 2)
	style.shadow_size = 3
	return style

func _make_panel(rect: Rect2, fill := Color(0.16,0.11,0.07,0.92), border := Color("#c89759")) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _panel_style(fill, border))
	add_child(panel)
	return panel

func _make_label(parent: Node, pos: Vector2, font_size: int, color := Color("#fff4d4")) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.08,0.05,0.03,0.72))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func _style_button(button: Button, accent := Color("#c58a4b")) -> void:
	button.add_theme_stylebox_override("normal", _button_style(Color("#6f4b32"), Color("#d7a45f")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#80583a"), Color("#f0c477")))
	button.add_theme_stylebox_override("pressed", _button_style(accent.darkened(0.24), Color("#ffe0a0")))
	button.add_theme_color_override("font_color", Color("#fff2cd"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0,0,0,0.55))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _build_top_bar() -> void:
	var p := _make_panel(Rect2(18,14,820,104), Color("#382719e8"), Color("#c6924f"))
	var title := _make_label(p, Vector2(18,8), 13, Color("#e7bd73"))
	title.text = "GREENFIELD FARM"
	day_label = _make_label(p, Vector2(18,31), 21)
	time_label = _make_label(p, Vector2(127,31), 21)
	money_label = _make_label(p, Vector2(248,31), 21, Color("#ffd66d"))
	weather_label = _make_label(p, Vector2(370,31), 19)
	energy_label = _make_label(p, Vector2(530,29), 15, Color("#ffd9a6"))

	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(530,52)
	energy_bar.size = Vector2(250,18)
	energy_bar.min_value = 0
	energy_bar.max_value = 100
	energy_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#241a13")
	bg.corner_radius_top_left = 7
	bg.corner_radius_top_right = 7
	bg.corner_radius_bottom_left = 7
	bg.corner_radius_bottom_right = 7
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#77b95c")
	fill.corner_radius_top_left = 7
	fill.corner_radius_top_right = 7
	fill.corner_radius_bottom_left = 7
	fill.corner_radius_bottom_right = 7
	energy_bar.add_theme_stylebox_override("background", bg)
	energy_bar.add_theme_stylebox_override("fill", fill)
	p.add_child(energy_bar)

	inventory_label = _make_label(p, Vector2(18,71), 14, Color("#f2dec0"))
	inventory_label.size = Vector2(790,28)

	message_label = _make_label(p, Vector2(18,122), 14, Color("#3f2b1b"))
	message_label.size = Vector2(820,40)
	var toast := _make_panel(Rect2(18,120,820,42), Color("#f4ddb0e8"), Color("#80552f"))
	toast.move_to_front()
	message_label.reparent(toast)
	message_label.position = Vector2(16,9)
	message_label.add_theme_color_override("font_shadow_color", Color(1,1,1,0))

	var save := Button.new()
	save.text = "SAVE"
	save.position = Vector2(1090,18)
	save.size = Vector2(80,50)
	_style_button(save)
	add_child(save)
	save.pressed.connect(_on_save_button_pressed)

	var load := Button.new()
	load.text = "LOAD"
	load.position = Vector2(1178,18)
	load.size = Vector2(80,50)
	_style_button(load)
	add_child(load)
	load.pressed.connect(_on_load_button_pressed)

func _build_quest_panel() -> void:
	var p := _make_panel(Rect2(850,14,222,104), Color("#4a3222ed"), Color("#d1a25f"))
	var title := _make_label(p, Vector2(14,10), 15, Color("#ffd986"))
	title.text = "TOWN REQUEST"
	quest_label = _make_label(p, Vector2(14,36), 14, Color("#f5e2bf"))
	quest_label.size = Vector2(194,58)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_hotbar() -> void:
	var names := ["HOE", "TURNIP", "CARROT", "CORN", "WATER", "HARVEST"]
	var icons := ["#", "T", "C", "C", "~", "+"]
	var p := _make_panel(Rect2(286,628,768,82), Color("#342319ea"), Color("#c38a4c"))
	for i in range(names.size()):
		var b := Button.new()
		b.text = "%s\n%s" % [icons[i], names[i]]
		b.position = Vector2(8 + i*126, 8)
		b.size = Vector2(118,66)
		b.add_theme_font_size_override("font_size",14)
		_style_button(b)
		b.pressed.connect(_on_tool_button_pressed.bind(i))
		p.add_child(b)
		tool_buttons.append(b)

func _build_mobile_controls() -> void:
	_add_move_button("↑", Vector2(105,526), "up")
	_add_move_button("↓", Vector2(105,642), "down")
	_add_move_button("←", Vector2(23,584), "left")
	_add_move_button("→", Vector2(187,584), "right")

	var action := Button.new()
	action.text = "USE"
	action.position = Vector2(1102,566)
	action.size = Vector2(140,116)
	action.add_theme_font_size_override("font_size",24)
	_style_button(action, Color("#c98245"))
	add_child(action)
	action.pressed.connect(_on_action_button_pressed)

func _add_move_button(text: String, pos: Vector2, key: String) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(82,72)
	b.add_theme_font_size_override("font_size",28)
	_style_button(b, Color("#6a8650"))
	b.modulate = Color(1,1,1,0.88)
	add_child(b)
	b.button_down.connect(_set_move.bind(key, true))
	b.button_up.connect(_set_move.bind(key, false))

func _build_shop() -> void:
	shop_panel = Panel.new()
	shop_panel.position = Vector2(338,118)
	shop_panel.size = Vector2(604,486)
	shop_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f1d8a8"), Color("#70492e"), 18, 5))
	shop_panel.visible = false
	add_child(shop_panel)

	var header := Panel.new()
	header.position = Vector2(18,16)
	header.size = Vector2(568,72)
	header.add_theme_stylebox_override("panel", _panel_style(Color("#6b4730"), Color("#c89350"), 12, 3))
	shop_panel.add_child(header)
	var title := _make_label(header, Vector2(20,10), 28, Color("#fff0c7"))
	title.text = "Willow General Store"
	var sub := _make_label(header, Vector2(22,44), 13, Color("#efd5a0"))
	sub.text = "Seeds · supplies · produce trading"
	shop_money_label = _make_label(header, Vector2(460,20), 22, Color("#ffd66d"))

	shop_inventory_label = _make_label(shop_panel, Vector2(32,106), 16, Color("#52351f"))
	shop_inventory_label.size = Vector2(540,58)
	shop_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_inventory_label.add_theme_color_override("font_shadow_color", Color(1,1,1,0))

	_add_shop_buy_button("Turnip Seed", "turnip", Vector2(28,182))
	_add_shop_buy_button("Carrot Seed", "carrot", Vector2(212,182))
	_add_shop_buy_button("Corn Seed", "corn", Vector2(396,182))

	var sell := Button.new()
	sell.text = "SELL ALL HARVEST"
	sell.position = Vector2(28,290)
	sell.size = Vector2(548,64)
	sell.add_theme_font_size_override("font_size",19)
	_style_button(sell, Color("#7a9c52"))
	shop_panel.add_child(sell)
	sell.pressed.connect(_on_sell_all_pressed)

	var hint := _make_label(shop_panel, Vector2(32,372), 14, Color("#61452c"))
	hint.text = "Tip: the shipping bin beside the field sells produce too."
	hint.add_theme_color_override("font_shadow_color", Color(1,1,1,0))

	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(394,416)
	close.size = Vector2(182,48)
	_style_button(close)
	shop_panel.add_child(close)
	close.pressed.connect(_on_close_shop_pressed)

func _add_shop_buy_button(label_text: String, crop: String, pos: Vector2) -> void:
	var b := Button.new()
	b.name = "Buy_%s" % crop
	b.text = label_text
	b.position = pos
	b.size = Vector2(164,84)
	b.add_theme_font_size_override("font_size",16)
	_style_button(b, Color("#a86b43"))
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
	show_message("Store opened. Buy seeds or sell today's harvest.")

func close_shop() -> void:
	shop_open = false
	shop_panel.visible = false
	for key in movement_state.keys():
		movement_state[key] = false
	move_changed.emit(Vector2.ZERO)
	show_message("Back to Greenfield.")

func refresh_shop(current_money: int, seed_prices: Dictionary, sell_prices: Dictionary, produce: Dictionary) -> void:
	shop_money_label.text = "%dg" % current_money
	shop_inventory_label.text = "Harvest   Turnip %d   Carrot %d   Corn %d\nSell price   %dg       %dg       %dg" % [
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
	energy_label.text = "ENERGY  %d" % energy
	energy_bar.value = energy
	inventory_label.text = "Seeds  Turnip:%d  Carrot:%d  Corn:%d      Harvest  T:%d  C:%d  Corn:%d" % [
		int(seeds.get("turnip",0)), int(seeds.get("carrot",0)), int(seeds.get("corn",0)),
		int(produce.get("turnip",0)), int(produce.get("carrot",0)), int(produce.get("corn",0))
	]
	if not quest_started:
		quest_label.text = "Find Mayor Rowan\nin the town square."
	elif quest_complete:
		quest_label.text = "Completed!\nReward: 300g"
	else:
		quest_label.text = "Harvest 5 turnips\nProgress: %d / 5" % quest_turnips
	for i in range(tool_buttons.size()):
		if i == selected:
			tool_buttons[i].modulate = Color("#ffe18a")
		else:
			tool_buttons[i].modulate = Color.WHITE

func show_message(text: String) -> void:
	if message_label:
		message_label.text = text
