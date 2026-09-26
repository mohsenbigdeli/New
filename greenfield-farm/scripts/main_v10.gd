extends "res://scripts/main_v09.gd"

const TOOL_ICONS: Array[Texture2D] = [
	preload("res://assets/art/icon_hoe.svg"),
	preload("res://assets/art/icon_turnip.svg"),
	preload("res://assets/art/icon_carrot.svg"),
	preload("res://assets/art/icon_corn.svg"),
	preload("res://assets/art/icon_water.svg"),
	preload("res://assets/art/icon_harvest.svg")
]

var visual_polish: FarmVisualPolish

func _ready() -> void:
	super()
	visual_polish = FarmVisualPolish.new()
	visual_polish.name = "VisualPolish"
	add_child(visual_polish)
	visual_polish.setup(farm)
	visual_polish.set_active(interiors.active_room == "outside")
	_apply_v10_ui_skin()
	ui.show_message("v1.1 Art Pass: ultrawide view, compact HUD, refined farmer and denser countryside.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if visual_polish:
		visual_polish.set_active(room == "outside")

func _apply_v10_ui_skin() -> void:
	var tool_count: int = mini(ui.tool_buttons.size(), TOOL_ICONS.size())
	for i in range(tool_count):
		var b: Button = ui.tool_buttons[i]
		b.icon = TOOL_ICONS[i]
		b.text = ""
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 29)
		b.add_theme_stylebox_override("normal", _button_box(Color("#45362bdd"), Color("#b9915a"), 9, 2))
		b.add_theme_stylebox_override("hover", _button_box(Color("#5a4535ee"), Color("#efd18d"), 9, 2))
		b.add_theme_stylebox_override("pressed", _button_box(Color("#30261fee"), Color("#fff0b4"), 9, 3))
	_reskin_buttons(ui)
	_reskin_buttons(inventory_ui)
	if animal_panel:
		_reskin_buttons(animal_panel)
	if crafting_panel:
		_reskin_buttons(crafting_panel)
	if fishing_panel:
		_reskin_buttons(fishing_panel)

func _reskin_buttons(root: Node) -> void:
	for child_variant in root.get_children():
		var child: Node = child_variant as Node
		if not child:
			continue
		if child is Button:
			var b: Button = child as Button
			if not ui.tool_buttons.has(b):
				b.add_theme_stylebox_override("normal", _button_box(Color("#514033e8"), Color("#ae8956"), 9, 2))
				b.add_theme_stylebox_override("hover", _button_box(Color("#66503bec"), Color("#e0bb76"), 9, 2))
				b.add_theme_stylebox_override("pressed", _button_box(Color("#392e27f2"), Color("#f4d795"), 9, 3))
				b.add_theme_color_override("font_color", Color("#fff0d0"))
				b.add_theme_color_override("font_hover_color", Color.WHITE)
				b.add_theme_color_override("font_pressed_color", Color.WHITE)
		_reskin_buttons(child)

func _button_box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_width)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0.05,0.03,0.02,0.32)
	s.shadow_size = 4
	return s
