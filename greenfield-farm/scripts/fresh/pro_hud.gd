extends CanvasLayer
class_name FarmProHUD
signal command(action: String)
signal setting_changed(key: String, value: Variant)
const INK = Color("243e35")
const CREAM = Color("fff3d7")
const GOLD = Color("e9bc69")
var root: Control
var overlay: Control
var menu_panel: PanelContainer
var menu_stack: VBoxContainer
var stats: Label
var objective: Label
var hint: Label
var toast: Label
var status: Label
var use_button: Button
var joystick: Control
var dock: HBoxContainer
var stats_card: Panel
var quest_card: Panel
var prompt_card: Panel
var toast_card: Panel
var menu_button: Button
var started := false
var has_save := false
var toast_clock := 0.0
var settings := {"touch":false, "effects":true, "sound":true, "zoom":1.15}

func style(fill: Color, border: Color = Color("516750"), radius: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.04, 0.1, 0.07, 0.22)
	s.shadow_size = 5
	return s

func label(text: String, size_value: int, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size_value)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func button(text: String, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", INK if primary else CREAM)
	b.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", style(GOLD if primary else Color("345246")))
	b.add_theme_stylebox_override("hover", style(Color("f3d293") if primary else Color("46695a")))
	b.add_theme_stylebox_override("pressed", style(Color("c1d79b")))
	b.add_theme_stylebox_override("focus", style(Color(0,0,0,0), GOLD))
	b.pressed.connect(action)
	return b

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	stats_card = _card(root)
	stats = label("", 18)
	stats.position = Vector2(18, 12)
	stats_card.add_child(stats)
	quest_card = _card(root)
	objective = label("", 16)
	objective.position = Vector2(18, 12)
	quest_card.add_child(objective)
	menu_button = button("II  Menu", func(): show_menu("pause"))
	root.add_child(menu_button)
	prompt_card = _card(root)
	hint = label("", 17)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_card.add_child(hint)
	toast_card = _card(root)
	toast = label("", 17)
	toast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_card.add_child(toast)
	toast_card.hide()
	dock = HBoxContainer.new()
	dock.add_theme_constant_override("separation", 10)
	root.add_child(dock)
	for entry in [["J  Journal", "journal"], ["F5  Save", "save"], ["?  Guide", "guide"]]:
		var key: String = entry[1]
		var b := button(entry[0], func(): command.emit(key))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dock.add_child(b)
	joystick = load("res://scripts/fresh/joystick.gd").new()
	root.add_child(joystick)
	use_button = button("USE", func(): command.emit("use"), true)
	root.add_child(use_button)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.055, 0.12, 0.1, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	menu_panel = PanelContainer.new()
	menu_panel.add_theme_stylebox_override("panel", style(Color("203f35f5"), Color("829466"), 20))
	overlay.add_child(menu_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	menu_panel.add_child(margin)
	menu_stack = VBoxContainer.new()
	menu_stack.add_theme_constant_override("separation", 12)
	margin.add_child(menu_stack)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _card(parent: Node) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", style(Color("243f35ed"), Color("768567")))
	parent.add_child(p)
	return p

func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	stats_card.position = Vector2(22, 20)
	stats_card.size = Vector2(282, 78)
	quest_card.position = Vector2(s.x - 304, 82)
	quest_card.size = Vector2(282, 75)
	menu_button.position = Vector2(s.x - 152, 20)
	menu_button.size = Vector2(130, 48)
	dock.position = Vector2(s.x * 0.5 - 230, s.y - 72)
	dock.size = Vector2(460, 50)
	prompt_card.position = Vector2(s.x * 0.5 - 215, s.y - 127)
	prompt_card.size = Vector2(430, 40)
	toast_card.position = Vector2(s.x * 0.5 - 290, 24)
	toast_card.size = Vector2(580, 56)
	joystick.position = Vector2(24, s.y - 190)
	joystick.size = Vector2(160, 160)
	use_button.position = Vector2(s.x - 162, s.y - 152)
	use_button.size = Vector2(136, 106)
	menu_panel.size = Vector2(520, 0)
	menu_panel.position = Vector2(58, maxf(24, (s.y - menu_panel.size.y) * 0.5))

func _process(delta: float) -> void:
	if toast_clock > 0:
		toast_clock -= delta
		toast_card.visible = toast_clock > 0 and not overlay.visible
	if overlay.visible:
		var s := get_viewport().get_visible_rect().size
		menu_panel.position.y = maxf(24, (s.y - menu_panel.size.y) * 0.5)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if overlay.visible and started:
				command.emit("resume")
			else:
				show_menu("pause" if started else "title")
			get_viewport().set_input_as_handled()

func update_status(day: int, minute: int, harvest: int, ready: int) -> void:
	stats.text = "SPRING  %02d      %02d:%02d\nHarvest  %d    ·    Ready  %d" % [day, minute / 60, minute % 60, harvest, ready]
	objective.text = "FIRST HARVEST\nGather crops  %d / 5" % mini(5, harvest) if harvest < 5 else "A GROWING FARM\nFirst harvest complete!"

func show_toast(text: String) -> void:
	toast.text = text
	toast_clock = 3.4
	toast_card.visible = not overlay.visible

func set_target(text: String) -> void:
	prompt_card.visible = not text.is_empty() and not overlay.visible
	hint.text = ("A  ·  " if settings.touch else "E  ·  ") + text
	use_button.text = text.to_upper() if text.length() < 15 else "USE"
	use_button.disabled = text.is_empty()

func apply_settings(data: Dictionary) -> void:
	settings = data.duplicate()
	var texts := ["Journal", "Save", "Guide"] if settings.touch else ["J  Journal", "F5  Save", "?  Guide"]
	for i in range(dock.get_child_count()): dock.get_child(i).text = texts[i]
	joystick.visible = bool(settings.touch) and not overlay.visible
	use_button.visible = bool(settings.touch) and not overlay.visible

func close_menu() -> void:
	overlay.hide()
	for item in [stats_card, quest_card, dock, menu_button]: item.show()
	apply_settings(settings)
	get_tree().paused = false
	joystick.release()

func _clear_menu(title: String, subtitle: String) -> void:
	for child in menu_stack.get_children():
		menu_stack.remove_child(child)
		child.queue_free()
	menu_panel.size.y = 0
	menu_stack.add_child(label("GREENFIELD  /  FARM LIFE", 12, GOLD))
	menu_stack.add_child(label(title, 42))
	var desc := label(subtitle, 16, Color("c5d5bd"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 464
	menu_stack.add_child(desc)

func show_menu(page := "title") -> void:
	get_tree().paused = true
	joystick.release()
	overlay.show()
	for item in [stats_card, quest_card, dock, menu_button, prompt_card, joystick, use_button]: item.hide()
	toast_card.hide()
	match page:
		"title", "pause":
			_clear_menu("Greenfield Farm" if page == "title" else "Take a breath.", "Small beginnings. A place to grow." if page == "title" else "Your farm is paused. Pick up where you left off.")
			if started:
				menu_stack.add_child(button("Return to farm", func(): command.emit("resume"), true))
				menu_stack.add_child(button("Save progress", func(): command.emit("save")))
			elif has_save:
				menu_stack.add_child(button("Continue your farm", func(): command.emit("load"), true))
			menu_stack.add_child(button("Start a new farm", func(): show_menu("confirm") if started or has_save else command.emit("new"), not has_save and not started))
			menu_stack.add_child(button("Settings", func(): show_menu("settings")))
			menu_stack.add_child(button("Field guide", func(): show_menu("guide")))
			menu_stack.add_child(label("PRO EDITION  0.2     ·     A quiet day in the country", 12, Color("a8bda2")))
		"confirm":
			_clear_menu("A fresh start?", "This replaces this edition's saved farm. Your previous save is retained as a backup.")
			menu_stack.add_child(button("Start new farm", func(): command.emit("new"), true))
			menu_stack.add_child(button("Keep my farm", func(): show_menu("pause" if started else "title")))
		"settings":
			_clear_menu("Make it yours.", "Changes are saved automatically.")
			for item in [["Touch controls", "touch"], ["Ambient effects", "effects"], ["Sound effects", "sound"]]:
				var key: String = item[1]
				var toggle := CheckButton.new()
				toggle.text = item[0]
				toggle.custom_minimum_size.y = 46
				toggle.add_theme_font_size_override("font_size", 18)
				toggle.button_pressed = bool(settings[key])
				toggle.toggled.connect(func(value): settings[key] = value; setting_changed.emit(key, value))
				menu_stack.add_child(toggle)
			menu_stack.add_child(label("Camera zoom", 16))
			var zoom := HSlider.new()
			zoom.min_value = 0.9
			zoom.max_value = 1.5
			zoom.step = 0.05
			zoom.value = settings.zoom
			zoom.custom_minimum_size.y = 36
			zoom.value_changed.connect(func(value): settings.zoom = value; setting_changed.emit("zoom", value))
			menu_stack.add_child(zoom)
			menu_stack.add_child(button("Done", func(): show_menu("pause" if started else "title"), true))
		"guide":
			_clear_menu("The field guide", "A small routine, a rewarding harvest.")
			var guide := label("01   Prepare a garden bed\n02   Plant your seeds\n03   Water and watch it grow\n04   Harvest when the gold mark appears\n\nMove: WASD / arrows / touch stick\nInteract: E / Space / action button\nJournal: J    Save: F5    Pause: Esc\n\nYour farm autosaves every 30 seconds.", 18)
			menu_stack.add_child(guide)
			menu_stack.add_child(button("Back", func(): show_menu("pause" if started else "title"), true))
	_layout()

func show_journal(harvest: int, planted: int, ready: int) -> void:
	show_menu("journal")
	_clear_menu("Farm journal", "Keep growing, one bed at a time.")
	menu_stack.add_child(label("TOTAL HARVEST             %d\nGROWING BEDS               %d\nREADY TO PICK                  %d\n\nFirst harvest: %d / 5\n\nMarnie's advice\nWater each planted bed. The gold marker\nmeans your crop is ready to harvest." % [harvest, planted, ready, mini(harvest,5)], 20))
	menu_stack.add_child(button("Return to farm", func(): command.emit("resume"), true))
