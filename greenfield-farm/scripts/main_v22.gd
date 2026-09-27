extends "res://scripts/main_v19.gd"

var painted_world_v22: FarmPaintedWorldV22

func _ready() -> void:
	super()
	if painted_world_v17:
		painted_world_v17.set_active(false)
	if painted_world_v18:
		painted_world_v18.set_active(false)
	if painted_world_v19:
		painted_world_v19.set_active(false)
	painted_world_v22 = FarmPaintedWorldV22.new()
	painted_world_v22.name = "PaintedWorldV22"
	add_child(painted_world_v22)
	painted_world_v22.setup(farm)
	painted_world_v22.set_active(interiors.active_room == "outside")
	_apply_v22_composition()
	_apply_v22_controls()
	call_deferred("_apply_v22_controls")
	ui.show_message("v2.2 Motion + Controls: visible walking legs, five watercolor tree silhouettes and a much larger mobile joystick.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painted_world_v17:
		painted_world_v17.set_active(false)
	if painted_world_v18:
		painted_world_v18.set_active(false)
	if painted_world_v19:
		painted_world_v19.set_active(false)
	if painted_world_v22:
		painted_world_v22.set_active(room == "outside")
	if room == "outside":
		if farm:
			farm.visible = false
		if player and player.camera:
			player.camera.zoom = Vector2(0.80,0.80)
			player.camera.position_smoothing_speed = 7.5
			player.camera.reset_smoothing()
	_apply_v22_controls()

func _process(delta: float) -> void:
	super(delta)
	_apply_v22_controls()

# These overrides intercept the older v1.8/v1.9 per-frame farmer scaling so the
# watercolor walk shader stays active and its stronger leg motion is not overwritten.
func _apply_v18_farmer() -> void:
	_apply_v22_farmer()

func _apply_v19_farmer() -> void:
	_apply_v22_farmer()

func _apply_v22_farmer() -> void:
	if not player:
		return
	player.set_custom_character_texture(FARMER_V17,Vector2(1.18,1.18))
	if player.character_sprite:
		player.character_sprite.modulate = Color(1.0,0.99,0.96,1.0)

func _apply_v22_composition() -> void:
	if player and player.camera and interiors.active_room == "outside":
		player.camera.zoom = Vector2(0.80,0.80)
		player.camera.position_smoothing_speed = 7.5
		player.camera.reset_smoothing()
	_apply_v22_farmer()

func _apply_v22_controls() -> void:
	if not ui:
		return
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	if ui.joystick:
		ui.joystick.size = Vector2(184,184)
		ui.joystick.position = Vector2(20.0,view_size.y-204.0)
		ui.joystick.modulate = Color(1.0,0.98,0.91,0.92)
	if ui.action_button:
		ui.action_button.size = Vector2(98,98)
		ui.action_button.position = Vector2(view_size.x-118.0,view_size.y-118.0)
		ui.action_button.add_theme_font_size_override("font_size",17)
