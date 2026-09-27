extends "res://scripts/main_v18.gd"

var painted_world_v19: FarmPaintedWorldV19

func _ready() -> void:
	super()
	if painted_world_v18:
		painted_world_v18.set_active(false)
	painted_world_v19 = FarmPaintedWorldV19.new()
	painted_world_v19.name = "PaintedWorldV19"
	add_child(painted_world_v19)
	painted_world_v19.setup(farm)
	painted_world_v19.set_active(interiors.active_room == "outside")
	_apply_v19_composition()
	_apply_v19_ui()
	ui.show_message("v1.9 Composition Pass: wider storybook framing, richer meadow, softer paths and cleaner fishing markers.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painted_world_v17:
		painted_world_v17.set_active(false)
	if painted_world_v18:
		painted_world_v18.set_active(false)
	if painted_world_v19:
		painted_world_v19.set_active(room == "outside")
	if room == "outside":
		if farm:
			farm.visible = false
		if player and player.camera:
			player.camera.zoom = Vector2(0.78,0.78)
			player.camera.position_smoothing_speed = 7.0
			player.camera.reset_smoothing()

func _process(delta: float) -> void:
	super(delta)
	_apply_v19_farmer()

func _apply_v19_composition() -> void:
	if player and player.camera and interiors.active_room == "outside":
		# This is the key framing change: at the starting farm area both cottage and
		# general store now fit the landscape instead of being clipped at the edges.
		player.camera.zoom = Vector2(0.78,0.78)
		player.camera.position_smoothing_speed = 7.0
		player.camera.reset_smoothing()
	_apply_v19_farmer()

func _apply_v19_farmer() -> void:
	if not player or not player.character_sprite:
		return
	# Counter the wider camera with a larger authored watercolor character.
	player.character_sprite.scale = Vector2(1.27,1.27)
	player.character_sprite.modulate = Color(1.0,0.99,0.96,1.0)
	player.character_sprite.flip_h = player.facing.x < -0.15

func _apply_v19_ui() -> void:
	if not ui:
		return
	var paper: Color = Color(0.985,0.945,0.835,0.91)
	var paper_soft: Color = Color(1.0,0.965,0.875,0.91)
	var edge: Color = Color(0.40,0.30,0.19,0.54)
	var ink: Color = Color("#4a3828")
	for panel: Panel in [ui.info_panel,ui.energy_panel,ui.quest_panel,ui.hotbar_panel,ui.context_panel]:
		if panel:
			panel.add_theme_stylebox_override("panel",_v15_panel(paper,edge,16,2))
			panel.modulate = Color.WHITE
	for button: Button in [ui.save_button,ui.load_button,ui.action_button]:
		if button:
			button.add_theme_stylebox_override("normal",_v15_button(paper_soft,edge,16))
			button.add_theme_stylebox_override("pressed",_v15_button(Color(0.89,0.80,0.62,0.96),edge,16))
			button.add_theme_color_override("font_color",ink)
			button.modulate = Color.WHITE
	for button: Button in ui.tool_buttons:
		button.add_theme_stylebox_override("normal",_v15_button(Color(0.98,0.92,0.78,0.94),edge,11))
		button.add_theme_stylebox_override("pressed",_v15_button(Color(0.88,0.76,0.56,0.98),edge,11))
		button.add_theme_color_override("font_color",ink)
	if ui.context_label:
		ui.context_label.add_theme_color_override("font_color",ink)
	if ui.joystick:
		ui.joystick.modulate = Color(1.0,0.98,0.91,0.72)
