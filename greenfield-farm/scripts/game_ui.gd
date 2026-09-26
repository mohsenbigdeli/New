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
var energy_fill_style: StyleBoxFlat
var inventory_label: Label
var message_label: Label
var quest_label: Label
var shipping_label: Label
var context_label: Label
var context_panel: Panel
var tool_buttons: Array[Button] = []
var joystick: FarmJoystick
var toast_panel: Panel
var toast_timer := 0.0

var info_panel: Panel
var energy_panel: Panel
var quest_panel: Panel
var hotbar_panel: Panel
var save_button: Button
var load_button: Button
var action_button: Button
var shop_panel: Panel
var shop_money_label: Label
var shop_inventory_label: Label
var shop_open := false

func _ready() -> void:
	layer = 10
	_build_compact_hud()
	_build_hotbar()
	_build_mobile_controls()
	_build_context_prompt()
	_build_shop()
	get_viewport().size_changed.connect(_layout_for_viewport)
	call_deferred("_layout_for_viewport")

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
	var style: StyleBoxFlat = _panel_style(fill, border, radius, 2)
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
	button.add_theme_stylebox_override("normal", _button_style(Color("#514031df"), Color("#c49a62"), radius))
	button.add_theme_stylebox_override("hover", _button_style(Color("#66503bec"), Color("#eed08e"), radius))
	button.add_theme_stylebox_override("pressed", _button_style(accent.darkened(0.18), Color("#ffe3a8"), radius))
	button.add_theme_color_override("font_color", Color("#fff3d2"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0,0,0,0.45))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)

func _build_compact_hud() -> void:
	info_panel = _make_panel(Rect2(12,10,350,58), Color("#2a2119d4"), Color("#b9894d"), 12)
	var title := _make_label(info_panel, Vector2(12,5), 10, Color("#d9b870"))
	title.text = "GREENFIELD FARM"
	day_label = _make_label(info_panel, Vector2(12,20), 17)
	time_label = _make_label(info_panel, Vector2(111,20), 17)
	money_label = _make_label(info_panel, Vector2(199,20), 17, Color("#ffd46c"))
	weather_label = _make_label(info_panel, Vector2(273,22), 12)
	inventory_label = _make_label(info_panel, Vector2(12,42), 9, Color("#ead7b3"))
	inventory_label.size = Vector2(330,14)

	energy_panel = _make_panel(Rect2(372,10,300,58), Color("#2a2119d4"), Color("#907647"), 12)
	energy_label = _make_label(energy_panel, Vector2(14,6), 10, Color("#f0d7a2"))
	shipping_label = _make_label(energy_panel, Vector2(212,6), 10, Color("#f6c96f"))
	energy_bar = ProgressBar.new()
	energy_bar.position = Vector2(14,29)
	energy_bar.size = Vector2(272,17)
	energy_bar.min_value = 0
	energy_bar.max_value = 100
	energy_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#17130f")
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	energy_fill_style = StyleBoxFlat.new()
	energy_fill_style.bg_color = Color("#78b85c")
	energy_fill_style.corner_radius_top_left = 8
	energy_fill_style.corner_radius_top_right = 8
	energy_fill_style.corner_radius_bottom_left = 8
	energy_fill_style.corner_radius_bottom_right = 8
	energy_bar.add_theme_stylebox_override("background", bg)
	energy_bar.add_theme_stylebox_override("fill", energy_fill_style)
	energy_panel.add_child(energy_bar)

	quest_panel = _make_panel(Rect2(684,10,260,58), Color("#33271dd8"), Color("#a98250"), 12)
	var qtitle := _make_label(quest_panel, Vector2(11,5), 10, Color("#f3ca79"))
	qtitle.text = "REQUEST"
	quest_label = _make_label(quest_panel, Vector2(11,21), 10, Color("#f3e1c2"))
	quest_label.size = Vector2(238,30)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	save_button = Button.new()
	save_button.text = "SAVE"
	save_button.size = Vector2(62,30)
	save_button.add_theme_font_size_override("font_size",10)
	_style_button(save_button)
	add_child(save_button)
	save_button.pressed.connect(_on_save_button_pressed)

	load_button = Button.new()
	load_button.text = "LOAD"
	load_button.size = Vector2(62,30)
	load_button.add_theme_font_size_override("font_size",10)
	_style_button(load_button)
	add_child(load_button)
	load_button.pressed.connect(_on_load_button_pressed)

	toast_panel = _make_panel(Rect2(360,78,560,32), Color("#f4dfb7e8"), Color("#795432"), 10)
	message_label = _make_label(toast_panel, Vector2(12,5), 11, Color("#3e2c1f"))
	message_label.size = Vector2(536,21)
	message_label.add_theme_color_override("font_shadow_color", Color(1,1,1,0))
	toast_panel.visible = false

func _build_hotbar() -> void:
	var names: Array[String] = ["HOE", "TURNIP", "CARROT", "CORN", "WATER", "HARVEST"]
	hotbar_panel = _make_panel(Rect2(403,662,474,50), Color("#211a15cc"), Color("#a57d4d"), 12)
	for i in range(names.size()):
		var b := Button.new()
		b.text = names[i]
		b.position = Vector2(5 + i*78, 5)
		b.size = Vector2(74,40)
		b.add_theme_font_size_override("font_size",9)
		_style_button(b, Color("#9b6a3d"), 9)
		b.pressed.connect(_on_tool_button_pressed.bind(i))
		hotbar_panel.add_child(b)
		tool_buttons.append(b)

func _build_mobile_controls() -> void:
	joystick = FarmJoystick.new()
	joystick.size = Vector2(126,126)
	add_child(joystick)
	joystick.vector_changed.connect(_on_joystick_vector)

	action_button = Button.new()
	action_button.text = "USE"
	action_button.size = Vector2(88,88)
	action_button.add_theme_font_size_override("font_size",16)
	_style_button(action_button, Color("#b66f3f"), 40)
	action_button.modulate = Color(1,1,1,0.90)
	add_child(action_button)
	action_button.pressed.connect(_on_action_button_pressed)

func _build_context_prompt() -> void:
	context_panel = _make_panel(Rect2(480,621,320,30), Color("#1b1713c4"), Color("#90734c"), 11)
	context_label = _make_label(context_panel, Vector2(10,5), 11, Color("#f4e4c2"))
	context_label.size = Vector2(300,20)
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_panel.visible = false

func _layout_for_viewport() -> void:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var w: float = view_size.x
	var h: float = view_size.y
	if info_panel:
		info_panel.position = Vector2(12,10)
	if energy_panel:
		energy_panel.position = Vector2(374,10)
	if quest_panel:
		quest_panel.position = Vector2(maxf(688.0, w - 446.0),10)
	if save_button:
		save_button.position = Vector2(w-142.0,11.0)
	if load_button:
		load_button.position = Vector2(w-74.0,11.0)
	if toast_panel:
		toast_panel.position = Vector2((w-toast_panel.size.x)*0.5,76.0)
	if hotbar_panel:
		hotbar_panel.position = Vector2((w-hotbar_panel.size.x)*0.5,h-hotbar_panel.size.y-8.0)
	if joystick:
		joystick.position = Vector2(18.0,h-144.0)
	if action_button:
		action_button.position = Vector2(w-108.0,h-112.0)
	if context_panel:
		context_panel.position = Vector2((w-context_panel.size.x)*0.5,h-96.0)
	if shop_panel:
		shop_panel.position = Vector2((w-shop_panel.size.x)*0.5,(h-shop_panel.size.y)*0.5)

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
	sell.text = "SELL NOW AT STORE"
	sell.position = Vector2(24,286)
	sell.size = Vector2(512,62)
	sell.add_theme_font_size_override("font_size",17)
	_style_button(sell, Color("#6e914e"))
	shop_panel.add_child(sell)
	sell.pressed.connect(_on_sell_all_pressed)

	var hint := _make_label(shop_panel, Vector2(28,366), 13, Color("#62462e"))
	hint.text = "Shipping Bin pays the next morning. Store sales pay instantly."
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
	set_context_hint("")
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
	shop_inventory_label.text = "Harvest  Turnip %d   Carrot %d   Corn %d\nSell      %dg        %dg        %dg" % [int(produce.get("turnip",0)), int(produce.get("carrot",0)), int(produce.get("corn",0)), int(sell_prices.get("turnip",0)), int(sell_prices.get("carrot",0)), int(sell_prices.get("corn",0))]
	for crop in ["turnip","carrot","corn"]:
		var b := shop_panel.get_node_or_null("Buy_%s" % crop) as Button
		if b:
			b.text = "%s Seed\n%dg" % [crop.capitalize(), int(seed_prices.get(crop,0))]

func update_status(season_name: String, season_day: int, minute_of_day: int, current_money: int, current_weather: String, seeds: Dictionary, produce: Dictionary, selected: int, energy: int, quest_text: String, shipping_value: int) -> void:
	var hour := int(minute_of_day / 60)
	var minute := int(minute_of_day % 60)
	day_label.text = "%s %d" % [season_name, season_day]
	time_label.text = "%02d:%02d" % [hour, minute]
	money_label.text = "%dg" % current_money
	weather_label.text = current_weather
	energy_label.text = "ENERGY %d" % energy
	shipping_label.text = "BIN %dg" % shipping_value
	energy_bar.value = energy
	if energy_fill_style:
		if energy <= 20:
			energy_fill_style.bg_color = Color("#d76952")
		elif energy <= 45:
			energy_fill_style.bg_color = Color("#d6a34f")
		else:
			energy_fill_style.bg_color = Color("#78b85c")
	inventory_label.text = "Seeds T:%d  C:%d  Corn:%d   Harvest %d/%d/%d" % [int(seeds.get("turnip",0)), int(seeds.get("carrot",0)), int(seeds.get("corn",0)), int(produce.get("turnip",0)), int(produce.get("carrot",0)), int(produce.get("corn",0))]
	quest_label.text = quest_text
	for i in range(tool_buttons.size()):
		tool_buttons[i].modulate = Color("#ffe39a") if i == selected else Color(1,1,1,0.94)

func set_context_hint(text: String) -> void:
	if not context_panel or not context_label:
		return
	if text == "":
		context_panel.visible = false
	else:
		context_label.text = text
		context_panel.visible = true

func show_message(text: String) -> void:
	if message_label and toast_panel:
		message_label.text = text
		toast_panel.visible = true
		toast_timer = 3.2
