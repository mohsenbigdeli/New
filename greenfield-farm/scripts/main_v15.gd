extends "res://scripts/main_v14.gd"

var painted_world_v15: FarmPaintedWorldV15Active

func _ready() -> void:
	super()
	# FarmWorld remains alive for gameplay, collisions and save data, but its old
	# vector renderer is replaced outside by the authored watercolor renderer.
	farm.visible = false
	painted_world_v15 = FarmPaintedWorldV15Active.new()
	painted_world_v15.name = "PaintedWorldV15"
	add_child(painted_world_v15)
	painted_world_v15.setup(farm)
	painted_world_v15.set_active(interiors.active_room == "outside")
	_apply_v15_parchment_ui()
	if player and player.camera:
		player.camera.zoom = Vector2(1.02,1.02)
		player.camera.reset_smoothing()
	ui.show_message("v1.5 Watercolor Farm: the outdoor world now uses the new hand-painted renderer and parchment HUD.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if farm:
		farm.visible = false
	if painted_world_v15:
		painted_world_v15.set_active(room == "outside")
	if room == "outside" and player and player.camera:
		player.camera.zoom = Vector2(1.02,1.02)
		player.camera.reset_smoothing()

func _process(delta: float) -> void:
	super(delta)
	if painted_world_v15 and painted_world_v15.active:
		painted_world_v15.queue_redraw()

func _apply_v15_parchment_ui() -> void:
	if not ui:
		return
	var paper: Color = Color(0.96,0.89,0.72,0.92)
	var paper_soft: Color = Color(0.95,0.87,0.69,0.86)
	var edge: Color = Color(0.39,0.28,0.17,0.72)
	var ink: Color = Color("#493626")
	var accent: Color = Color("#785332")

	ui.info_panel.add_theme_stylebox_override("panel",_v15_panel(paper,edge,15,4))
	ui.energy_panel.add_theme_stylebox_override("panel",_v15_panel(paper,edge,15,4))
	ui.quest_panel.add_theme_stylebox_override("panel",_v15_panel(paper,edge,15,4))
	ui.hotbar_panel.add_theme_stylebox_override("panel",_v15_panel(Color(0.28,0.23,0.16,0.82),Color(0.75,0.59,0.34,0.72),17,4))
	ui.context_panel.add_theme_stylebox_override("panel",_v15_panel(Color(0.20,0.18,0.13,0.78),Color(0.75,0.62,0.40,0.52),14,3))

	for label: Label in [ui.day_label,ui.time_label,ui.weather_label,ui.energy_label,ui.inventory_label,ui.quest_label,ui.shipping_label]:
		if label:
			label.add_theme_color_override("font_color",ink)
			label.add_theme_color_override("font_shadow_color",Color(1,1,1,0))
	if ui.money_label:
		ui.money_label.add_theme_color_override("font_color",Color("#8b5b20"))
		ui.money_label.add_theme_color_override("font_shadow_color",Color(1,1,1,0))

	ui.save_button.add_theme_stylebox_override("normal",_v15_button(paper_soft,edge,11))
	ui.load_button.add_theme_stylebox_override("normal",_v15_button(paper_soft,edge,11))
	ui.save_button.add_theme_color_override("font_color",ink)
	ui.load_button.add_theme_color_override("font_color",ink)
	ui.save_button.modulate = Color.WHITE
	ui.load_button.modulate = Color.WHITE

	if inventory_ui and inventory_ui.bag_button:
		inventory_ui.bag_button.add_theme_stylebox_override("normal",_v15_button(paper_soft,edge,11))
		inventory_ui.bag_button.add_theme_color_override("font_color",ink)
		inventory_ui.bag_button.modulate = Color.WHITE

	ui.action_button.add_theme_stylebox_override("normal",_v15_button(Color(0.31,0.26,0.18,0.68),Color(0.83,0.70,0.48,0.62),34))
	ui.action_button.add_theme_stylebox_override("pressed",_v15_button(Color(0.22,0.20,0.15,0.82),Color(0.94,0.82,0.58,0.82),34))
	ui.action_button.modulate = Color(1,1,1,0.78)

	for button: Button in ui.tool_buttons:
		button.add_theme_stylebox_override("normal",_v15_button(Color(0.22,0.18,0.13,0.76),Color(0.74,0.58,0.36,0.60),11))
		button.add_theme_stylebox_override("hover",_v15_button(Color(0.34,0.27,0.17,0.84),Color(0.90,0.74,0.47,0.75),11))
		button.add_theme_stylebox_override("pressed",_v15_button(Color(0.40,0.30,0.17,0.90),Color(0.97,0.83,0.55,0.88),11))

	# Green energy on cream paper, matching the visual reference.
	if ui.energy_bar:
		var bg: StyleBoxFlat = StyleBoxFlat.new()
		bg.bg_color = Color(0.36,0.29,0.19,0.25)
		bg.corner_radius_top_left = 8
		bg.corner_radius_top_right = 8
		bg.corner_radius_bottom_left = 8
		bg.corner_radius_bottom_right = 8
		ui.energy_bar.add_theme_stylebox_override("background",bg)
	if ui.energy_fill_style:
		ui.energy_fill_style.bg_color = Color("#75b954")

func _v15_panel(fill: Color,border: Color,radius: int,shadow: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.shadow_color = Color(0.16,0.10,0.05,0.22)
	box.shadow_size = shadow
	box.content_margin_left = 5
	box.content_margin_right = 5
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box

func _v15_button(fill: Color,border: Color,radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.shadow_color = Color(0.10,0.07,0.04,0.23)
	box.shadow_size = 3
	return box
