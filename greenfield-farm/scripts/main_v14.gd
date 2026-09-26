extends "res://scripts/main_v13.gd"

var cinematic_v14: FarmCinematicV14

func _ready() -> void:
	super()
	player.z_index = 5
	cinematic_v14 = FarmCinematicV14.new()
	cinematic_v14.name = "CinematicV14"
	add_child(cinematic_v14)
	cinematic_v14.setup(farm)
	cinematic_v14.set_active(interiors.active_room == "outside")
	_apply_v14_art_direction()
	ui.show_message("v1.4 Cinematic Storybook: warmer light, layered foliage, repainted farmhouse, trees and characters.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if cinematic_v14:
		cinematic_v14.set_active(room == "outside")
	if room == "outside" and player and player.camera:
		player.camera.zoom = Vector2(1.04,1.04)
		player.camera.reset_smoothing()

func _apply_v14_art_direction() -> void:
	if farm:
		farm.modulate = Color(1.0,0.985,0.94,1.0)
	if storybook_art:
		storybook_art.modulate = Color(1.0,0.985,0.95,1.0)
	if painterly_v13:
		painterly_v13.modulate = Color(1.0,0.98,0.93,1.0)
	if not ui:
		return

	var dark_paper := Color(0.105,0.095,0.072,0.68)
	var dark_paper_soft := Color(0.11,0.10,0.075,0.58)
	var edge := Color(0.76,0.62,0.40,0.42)
	var edge_soft := Color(0.71,0.60,0.42,0.30)

	ui.info_panel.add_theme_stylebox_override("panel",_v14_panel(dark_paper,edge,15,4))
	ui.energy_panel.add_theme_stylebox_override("panel",_v14_panel(dark_paper,edge,15,4))
	ui.quest_panel.add_theme_stylebox_override("panel",_v14_panel(dark_paper,edge,15,4))
	ui.hotbar_panel.add_theme_stylebox_override("panel",_v14_panel(dark_paper_soft,edge_soft,16,4))
	ui.context_panel.add_theme_stylebox_override("panel",_v14_panel(Color(0.10,0.09,0.07,0.58),edge_soft,13,3))
	ui.toast_panel.add_theme_stylebox_override("panel",_v14_panel(Color(0.11,0.09,0.07,0.66),edge_soft,13,4))

	ui.action_button.add_theme_stylebox_override("normal",_v14_button(Color(0.29,0.23,0.17,0.70),Color(0.80,0.67,0.44,0.52),30))
	ui.action_button.add_theme_stylebox_override("hover",_v14_button(Color(0.34,0.27,0.19,0.78),Color(0.92,0.77,0.50,0.66),30))
	ui.action_button.add_theme_stylebox_override("pressed",_v14_button(Color(0.21,0.18,0.14,0.84),Color(0.96,0.82,0.56,0.78),30))
	ui.action_button.modulate = Color(1,1,1,0.84)

	ui.save_button.add_theme_stylebox_override("normal",_v14_button(Color(0.24,0.20,0.15,0.66),edge_soft,9))
	ui.load_button.add_theme_stylebox_override("normal",_v14_button(Color(0.24,0.20,0.15,0.66),edge_soft,9))
	ui.save_button.modulate = Color(1,1,1,0.85)
	ui.load_button.modulate = Color(1,1,1,0.85)

	for button: Button in ui.tool_buttons:
		button.add_theme_stylebox_override("normal",_v14_button(Color(0.19,0.16,0.12,0.72),edge_soft,11))
		button.add_theme_stylebox_override("hover",_v14_button(Color(0.28,0.22,0.15,0.78),Color(0.89,0.72,0.45,0.52),11))
		button.add_theme_stylebox_override("pressed",_v14_button(Color(0.36,0.27,0.16,0.84),Color(0.96,0.78,0.44,0.72),11))

	if inventory_ui and inventory_ui.bag_button:
		inventory_ui.bag_button.add_theme_stylebox_override("normal",_v14_button(Color(0.24,0.20,0.15,0.66),edge_soft,9))
		inventory_ui.bag_button.modulate = Color(1,1,1,0.85)

	if player and player.camera and interiors.active_room == "outside":
		player.camera.zoom = Vector2(1.04,1.04)
		player.camera.reset_smoothing()

func _v14_panel(fill: Color,border: Color,radius: int,shadow: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.shadow_color = Color(0.04,0.035,0.025,0.28)
	box.shadow_size = shadow
	box.content_margin_left = 5
	box.content_margin_right = 5
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box

func _v14_button(fill: Color,border: Color,radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.shadow_color = Color(0.04,0.03,0.02,0.24)
	box.shadow_size = 3
	return box
