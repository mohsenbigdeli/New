extends "res://scripts/main_v12.gd"

var painterly_v13: FarmPainterlyV13

func _ready() -> void:
	super()
	painterly_v13 = FarmPainterlyV13.new()
	painterly_v13.name = "PainterlyV13"
	add_child(painterly_v13)
	painterly_v13.setup(farm)
	painterly_v13.set_active(interiors.active_room == "outside")
	_apply_v13_ui_finish()
	ui.show_message("v1.3 Hand-Painted Art: organic soil, softer meadow, painted farmer, dappled light and storybook world polish.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painterly_v13:
		painterly_v13.set_active(room == "outside")

func _apply_v13_ui_finish() -> void:
	# Keep the compact v1.1 layout, but soften the hard prototype boxes.
	if not ui:
		return
	ui.info_panel.add_theme_stylebox_override("panel",_v13_box(Color(0.17,0.15,0.11,0.82),Color(0.78,0.63,0.38,0.72),13))
	ui.energy_panel.add_theme_stylebox_override("panel",_v13_box(Color(0.16,0.16,0.11,0.80),Color(0.67,0.61,0.36,0.66),13))
	ui.quest_panel.add_theme_stylebox_override("panel",_v13_box(Color(0.19,0.15,0.11,0.80),Color(0.76,0.61,0.39,0.66),13))
	ui.hotbar_panel.add_theme_stylebox_override("panel",_v13_box(Color(0.15,0.13,0.10,0.78),Color(0.72,0.57,0.35,0.68),13))
	ui.context_panel.add_theme_stylebox_override("panel",_v13_box(Color(0.14,0.13,0.10,0.73),Color(0.65,0.55,0.36,0.58),12))
	ui.action_button.add_theme_stylebox_override("normal",_v13_box(Color(0.30,0.24,0.18,0.78),Color(0.76,0.61,0.38,0.74),26))
	ui.action_button.add_theme_stylebox_override("pressed",_v13_box(Color(0.22,0.19,0.15,0.88),Color(0.92,0.76,0.48,0.88),26))
	if inventory_ui and inventory_ui.bag_button:
		inventory_ui.bag_button.add_theme_stylebox_override("normal",_v13_box(Color(0.28,0.23,0.17,0.84),Color(0.75,0.61,0.39,0.72),10))

func _v13_box(fill: Color,border: Color,radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0.05,0.04,0.02,0.24)
	s.shadow_size = 3
	return s
