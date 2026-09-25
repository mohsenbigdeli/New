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
var joystick: FarmJoystick
var toast_panel: Panel
var toast_timer := 0.0

var shop_panel: Panel
var shop_money_label: Label
var shop_inventory_label: Label
var shop_open := false

func _ready() -> void:
	layer = 10
	_build_compact_hud()
	_build_hotbar()
	_build_mobile_controls()
	_build_shop()

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and toast_panel:
			toast_panel.visible = false

func _panel_style(fill: Color, border: Color, radius: int = 12, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.06,0.04,0.03,0.24)
	style.shadow_size = 5
	return style

func _button_style(fill: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
	var style := _panel_style(fill, border, radius, 2)
	style.shadow_size = 3
	return style

func _make_panel(rect: Rect2, fill := Color(0.13,0.10,0.07,0.88), border := Color("#c79858"), radius := 12) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _panel_style(fill, border, radius, 2))
	add_child(panel)
	return panel

func _make_label(parent: Node, pos: Vector2, font_size: int, color := Color("#fff1cf")) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.05,0.03,0.02,0.70))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func _style_button(button: Button, accent := Color("#a76c3f"), radius := 10) -> void:
	button.add_theme_stylebox_override("normal", _button_style(Color("#60442fdd"), Color("#d3a25f"), radius))
	button.add_theme_stylebox_override("hover", _button_style(Color("#77543aee"), Color("#f0c97e"), radius))
	button.add_theme_stylebox_override("pressed", _button_style(accent.darkened(0.18), Color("#ffe3a8"), radius))
	button.add_theme_color_override("font_color", Color("#fff3d2"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0,0,0,0.45))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)

func _build_compact_hud() -> void:
	var info := _make_panel(Rect2(16,14,420,78), Color("#2f241bd9"), Color("#b9894d"), 13)
	var title := _make_label(info, Vector2(14,7), 12, Color("#d9b870"))
	title.text = "GREENFIELD FARM"
	day_label = _make_label(info, Vector2(14,27), 19)
	time_label = _make_label(info, Vector2(100,27), 19)
	money_label = _make_label(info, Vector2(205,27), 19, Color("#ffd46c"))
	weather_label = _make_label(info, Vector2(305,27), 16)
	inventory_label = _make_label(info, Vector2(14,54), 11, Color("#ead7b3"))
	inventory_label.size = Vector2(395,18)

	var energy_panel := _make_panel(Rect2(450,14,388,78), Color("#2f241bd9"), Color("#9d7b49"), 13)
	energy_label = _make_label(energy_panel, Vector2(18,11), 13, Color("#f0d7a2"))
	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(18,36)
	energy_bar.size = Vector2(352,22)
	energy_bar.min_value = 0
	energy_bar.max_value = 100
	energy_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#1c1712")
	bg.corner_radius_top_left = 9
	bg.corner_radius_top_right = 9
	bg.corner_radius_bottom_left = 9
	bg.corner_radius_bottom_right = 9
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#78b85c")
	fill.corner_radius_top_left = 9
	fill.corner_radius_top_right = 9
	fill.corner_radius_bottom_left = 9
	fill.corner_radius_bottom_right = 9
	energy_bar.add_theme_stylebox_override("background", bg)
	energy_bar.add_theme_stylebox_override("fill", fill)
	energy_panel.add_child(energy_bar)

	var quest := _make_panel(Rect2(852,14,250,78), Color("#3e2c20dc"), Color("#bd9155"), 13)
	var qtitle := _make_label(quest, Vector2(12,8), 12, Color("#f3ca79"))
	qtitle.text = "TOWN REQUEST"
	quest_label = _make_label(quest, Vector2(12,29), 12, Color("#f3e1c2"))
	quest_label.size = Vector2(225,40)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var save := Button.new()
	save.text = "SAVE"
	save.position = Vector2(1115,17)
	save.size = Vector2(70,36)
	save.add_theme_font_size_override("font_size",12)
	_style_button(save)
	add_child(save)
	save.pressed.connect(_on_save_button_pressed)

	var load := Button.new()
	load.text = "LOAD"
	load.position = Vector2(1192,17)
	load.size = Vector2(70,36)
	load.add_theme_font_size_override("font_size",12)
	_style_button(load)
	add_child(load)
	load.pressed.connect(_on_load_button_pressed)

	toast_panel = _make_panel(Rect2(340,104,600,38), Color("#f3dfb4e8"), Color("#795432"), 11)
	message_label = _make_label(toast_panel, Vector2(15,7), 13, Color("#3e2c1f"))
	message_label.size = Vector2(570,24)
	message_label.add_theme_color_override("font_shadow_color", Color(1,1,1,0))
	toast_panel.visible = false

func _build_hotbar() -> void:
	var names := ["HOE", "TURNIP", "CARROT", "CORN", "WATER", "HARVEST"]
	var short := ["H", "T", "C", "C", "W", "+"]
	var p := _make_panel(Rect2(346,651,588,60), Color("#261d17d9"), Color("#aa7d47"), 13)
	for i in range(names.size()):
		var b := Button.new()
		b.text = "%s\n%s" % [short[i], names[i]]
		b.position = Vector2(7 + i*96, 6)
		b.size = Vector2(90,48)
		b.add_theme_font_size_override("font_size",11)
		_style_button(b, Color("#9b6a3d"), 9)
		b.pressed.connect(_on_tool_button_pressed.bind(i))
		p.add_child(b)
		tool_buttons.append(b)

func _build_mobile_controls() -> void:
	joystick = FarmJoystick.new()
	joystick.position = Vector2(22,545)
	joystick.size = Vector2(154,154)
	add_child(joystick)
	joystick.vector_changed.connect(_on_joystick_vector)

	var action := Button.new()
	action.text = "USE"
	action.position = Vector2(1140,574)
	action.size = Vector2(116,116)
	action.add_theme_font_size_override("font_size",20)
	_style_button(action, Color("#b66f3f"), 54)
	action.modulate = Color(1,1,1,0.94)
	add_child(action)
	action.pressed.connect(_on_action_button_pressed)

func _build_shop() -> void:
	shop_panel = Panel.new()
	shop_panel.position = Vector2(360,118)
	shop_panel.size = Vector2(560,486)
	shop_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f0d9ad"), Color("#67452e"), 18, 4))
	shop_panel.visible = false
	add_child(shop_panel)

	var header := Panel.new()
	header.position = Vector2(16,16)
	header.size = Vector2(528,70)
	header.add_theme_stylebox_override("panel", _panel_style(Color("#65462f"), Color("#c89555"), 12, 2))
	shop_panel.add_child(header)
	var title := _make_label(header, Vector2(18,9), 24, Color("#fff0c7"))
	title.text = "Willow General Store"
	var sub := _make_label(header, Vector2(19,41), 12, Color("#eed2a1"))
	sub.text = "Seeds · supplies · produce"
	shop_money_label = _make_label(header, Vector2(438,20), 20, Color("#ffd66d"))

	shop_inventory_label = _make_label(shop_panel, Vector2(26,103), 14, Color("#50351f"))
	shop_inventory_label.size = Vector2(508,58)
	shop_inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_inventory_label.add_theme_color_override("font_shadow_color", Color(1,1,1,0))

	_add_shop_buy_button("Turnip", "turnip", Vector2(24,176))
	_add_shop_buy_button("Carrot", "carrot", Vector2(196,176))
	_add_shop_buy_button("Corn", "corn", Vector2(368,176))

	var sell := Button.new()
	sell.text = "SELL ALL HARVEST"
	sell.position = Vector2(24,286)
	sell.size = Vector2(512,62)
	sell.add_theme_font_size_override("font_size",17)
	_style_button(sell, Color("#6e914e"))
	shop_panel.add_child(sell)
	sell.pressed.connect(_on_sell_all_pressed)

	var hint := _make_label(shop_panel, Vector2(28,366), 13, Color("#62462e"))
	hint.text = "Shipping bin beside the field also sells produce."
	hint.add_theme_color_override("font_shadow_color", Color(1,1,1,0))

	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(368,418)
	close.size = Vector2(168,46)
	_style_button(close)
	shop_panel.add_child(close)
	close.pressed.connect(_on_close_shop_pressed)

func _add_shop_buy_button(label_text: String, crop: String, pos: Vector2) -> void:
	var b := Button.new()
	b.name = "Buy_%s" % crop
	b.text = label_text
	b.position = pos
	b.size = Vector2(152,82)
	b.add_theme_font_size_override("font_size",15)
	_style_button(b, Color("#9f693f"))
	shop_panel.add_child(b)
	b.pressed.connect(_on_buy_pressed.bind(crop))

func _on_joystick_vector(dir: Vector2) -> void:
	if shop_open:
		move_changed.emit(Vector2.ZERO)
	else:
		move_changed.emit(dir)

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
	if joystick:
		joystick.force_release()
	shop_panel.visible = true
	refresh_shop(current_money, seed_prices, sell_prices, produce)
	show_message("Store opened. Buy seeds or sell today's harvest.")

func close_shop() -> void:
	shop_open = false
	shop_panel.visible = false
	if joystick:
		joystick.force_release()
	move_changed.emit(Vector2.ZERO)
	show_message("Back to Greenfield.")

func refresh_shop(current_money: int, seed_prices: Dictionary, sell_prices: Dictionary, produce: Dictionary) -> void:
	shop_money_label.text = "%dg" % current_money
	shop_inventory_label.text = "Harvest  Turnip %d   Carrot %d   Corn %d\nSell      %dg        %dg        %dg" % [
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
	energy_label.text = "ENERGY  %d / 100" % energy
	energy_bar.value = energy
	inventory_label.text = "Seeds  T:%d  C:%d  Corn:%d     Harvest  %d / %d / %d" % [
		int(seeds.get("turnip",0)), int(seeds.get("carrot",0)), int(seeds.get("corn",0)),
		int(produce.get("turnip",0)), int(produce.get("carrot",0)), int(produce.get("corn",0))
	]
	if not quest_started:
		quest_label.text = "Find Mayor Rowan in town."
	elif quest_complete:
		quest_label.text = "Completed · reward 300g"
	else:
		quest_label.text = "Harvest turnips  %d / 5" % quest_turnips
	for i in range(tool_buttons.size()):
		if i == selected:
			tool_buttons[i].modulate = Color("#ffe39a")
		else:
			tool_buttons[i].modulate = Color(1,1,1,0.94)

func show_message(text: String) -> void:
	if message_label and toast_panel:
		message_label.text = text
		toast_panel.visible = true
		toast_timer = 3.0
