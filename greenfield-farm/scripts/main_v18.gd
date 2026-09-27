extends "res://scripts/main_v17.gd"

var painted_world_v18: FarmPaintedWorldV18

func _ready() -> void:
	super()
	if painted_world_v17:
		painted_world_v17.set_active(false)
	painted_world_v18 = FarmPaintedWorldV18.new()
	painted_world_v18.name = "PaintedWorldV18"
	add_child(painted_world_v18)
	painted_world_v18.setup(farm)
	painted_world_v18.set_active(interiors.active_room == "outside")
	_apply_v18_composition()
	_apply_v18_ui()
	ui.show_message("v1.8 Full Watercolor World: all outdoor buildings, farm plots, props and meadow composition refreshed.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painted_world_v17:
		painted_world_v17.set_active(false)
	if painted_world_v18:
		painted_world_v18.set_active(room == "outside")
	if room == "outside":
		if farm:
			farm.visible = false
		if player and player.camera:
			player.camera.zoom = Vector2(0.92,0.92)
			player.camera.reset_smoothing()

func _process(delta: float) -> void:
	super(delta)
	_apply_v18_farmer()

func _apply_v18_composition() -> void:
	if player and player.camera and interiors.active_room == "outside":
		player.camera.zoom = Vector2(0.92,0.92)
		player.camera.reset_smoothing()
	_apply_v18_farmer()

func _apply_v18_farmer() -> void:
	if not player or not player.character_sprite:
		return
	# The authored watercolor farmer is now large enough to match the NPC/building scale.
	player.character_sprite.scale = Vector2(1.06,1.06)
	player.character_sprite.modulate = Color(1.0,0.99,0.96,1.0)
	player.character_sprite.flip_h = player.facing.x < -0.15

func _apply_v18_ui() -> void:
	if not ui:
		return
	var paper: Color = Color(0.98,0.93,0.80,0.92)
	var paper_soft: Color = Color(0.99,0.95,0.84,0.90)
	var edge: Color = Color(0.43,0.31,0.19,0.60)
	var ink: Color = Color("#4d3927")
	for panel: Panel in [ui.info_panel,ui.energy_panel,ui.quest_panel,ui.hotbar_panel,ui.context_panel]:
		if panel:
			panel.add_theme_stylebox_override("panel",_v15_panel(paper,edge,14,2))
			panel.modulate = Color.WHITE
	for button: Button in [ui.save_button,ui.load_button,ui.action_button]:
		if button:
			button.add_theme_stylebox_override("normal",_v15_button(paper_soft,edge,14))
			button.add_theme_stylebox_override("pressed",_v15_button(Color(0.88,0.78,0.58,0.96),edge,14))
			button.add_theme_color_override("font_color",ink)
			button.modulate = Color.WHITE
	for button: Button in ui.tool_buttons:
		button.add_theme_stylebox_override("normal",_v15_button(Color(0.97,0.90,0.74,0.95),edge,10))
		button.add_theme_stylebox_override("pressed",_v15_button(Color(0.86,0.73,0.51,0.98),edge,10))
		button.add_theme_color_override("font_color",ink)
	if ui.context_label:
		ui.context_label.add_theme_color_override("font_color",ink)
	if ui.joystick:
		ui.joystick.modulate = Color(1.0,0.98,0.90,0.84)
