extends "res://scripts/main_v19.gd"

var painted_world_v20: FarmPaintedWorldV20

func _ready() -> void:
	super()
	if painted_world_v19:
		painted_world_v19.set_active(false)
	painted_world_v20 = FarmPaintedWorldV20.new()
	painted_world_v20.name = "PaintedWorldV20"
	add_child(painted_world_v20)
	painted_world_v20.setup(farm)
	painted_world_v20.set_active(interiors.active_room == "outside")
	_apply_v20_composition()
	ui.show_message("v2.0 Unique Watercolor World: distinct shop, town hall, barn and mine art with richer meadow composition.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painted_world_v17:
		painted_world_v17.set_active(false)
	if painted_world_v18:
		painted_world_v18.set_active(false)
	if painted_world_v19:
		painted_world_v19.set_active(false)
	if painted_world_v20:
		painted_world_v20.set_active(room == "outside")
	if room == "outside":
		if farm:
			farm.visible = false
		if player and player.camera:
			player.camera.zoom = Vector2(0.80,0.80)
			player.camera.position_smoothing_speed = 7.5
			player.camera.reset_smoothing()

func _process(delta: float) -> void:
	super(delta)
	_apply_v20_farmer()

func _apply_v20_composition() -> void:
	if player and player.camera and interiors.active_room == "outside":
		player.camera.zoom = Vector2(0.80,0.80)
		player.camera.position_smoothing_speed = 7.5
		player.camera.reset_smoothing()
	_apply_v20_farmer()

func _apply_v20_farmer() -> void:
	if not player or not player.character_sprite:
		return
	player.character_sprite.scale = Vector2(1.30,1.30)
	player.character_sprite.modulate = Color(1.0,0.99,0.96,1.0)
	player.character_sprite.flip_h = player.facing.x < -0.15
