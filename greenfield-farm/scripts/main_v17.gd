extends "res://scripts/main_v16.gd"

const FARMER_V17: Texture2D = preload("res://assets/art/v17/watercolor_farmer.png")

var painted_world_v17: FarmPaintedWorldV17

func _ready() -> void:
	super()
	if painted_world_v16:
		painted_world_v16.set_active(false)
	painted_world_v17 = FarmPaintedWorldV17.new()
	painted_world_v17.name = "PaintedWorldV17"
	add_child(painted_world_v17)
	painted_world_v17.setup(farm)
	painted_world_v17.set_active(interiors.active_room == "outside")
	_apply_v17_ui()
	_apply_v17_farmer()
	ui.show_message("v1.7 Watercolor Asset Pass: painted cottage, trees, pond, farmer and NPCs are now live in-game.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painted_world_v16:
		painted_world_v16.set_active(false)
	if painted_world_v17:
		painted_world_v17.set_active(room == "outside")
	if room == "outside" and farm:
		farm.visible = false
	if room == "outside" and player and player.camera:
		player.camera.zoom = Vector2(0.94,0.94)
		player.camera.reset_smoothing()

func _process(delta: float) -> void:
	super(delta)
	_apply_v17_farmer()

func _apply_v17_farmer() -> void:
	if not player or not player.character_sprite:
		return
	player.character_sprite.texture = FARMER_V17
	player.character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	player.character_sprite.scale = Vector2(0.88,0.88)
	# One authored painted pose is used for this art pass; mirroring at least gives
	# left/right movement a visual response while preserving all gameplay logic.
	player.character_sprite.flip_h = player.facing.x < -0.15

func _apply_v17_ui() -> void:
	if not ui:
		return
	var paper: Color = Color(0.97,0.91,0.76,0.93)
	var paper_soft: Color = Color(0.98,0.93,0.80,0.88)
	var edge: Color = Color(0.46,0.34,0.20,0.66)
	var ink: Color = Color("#4f3b29")

	if ui.hotbar_panel:
		ui.hotbar_panel.add_theme_stylebox_override("panel",_v15_panel(paper,edge,15,3))
		ui.hotbar_panel.modulate = Color.WHITE
	if ui.context_panel:
		ui.context_panel.add_theme_stylebox_override("panel",_v15_panel(paper_soft,edge,13,2))
		ui.context_panel.modulate = Color.WHITE
	if ui.context_label:
		ui.context_label.add_theme_color_override("font_color",ink)
	if ui.action_button:
		ui.action_button.add_theme_stylebox_override("normal",_v15_button(Color(0.96,0.88,0.70,0.86),edge,30))
		ui.action_button.add_theme_stylebox_override("pressed",_v15_button(Color(0.89,0.79,0.59,0.94),edge,30))
		ui.action_button.add_theme_color_override("font_color",ink)
		ui.action_button.modulate = Color.WHITE
	if ui.joystick:
		ui.joystick.modulate = Color(1.0,0.97,0.88,0.88)

	for button: Button in ui.tool_buttons:
		button.add_theme_stylebox_override("normal",_v15_button(Color(0.94,0.86,0.69,0.94),edge,10))
		button.add_theme_stylebox_override("hover",_v15_button(Color(1.0,0.93,0.76,0.98),edge,10))
		button.add_theme_stylebox_override("pressed",_v15_button(Color(0.86,0.74,0.53,0.98),edge,10))
