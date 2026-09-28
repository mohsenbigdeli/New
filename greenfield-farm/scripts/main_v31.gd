extends "res://scripts/main_v30.gd"

# v3.1 replaces the almost-static v2.4 runtime sheet with an authored 4x4
# farmer sheet whose leg silhouettes visibly change on every stride.
const FARMER_WALK_SHEET_V31: Texture2D = preload("res://assets/art/v31/farmer_walk_sheet.png")
var v31_walk_sequence: Array[int] = [1, 3, 2, 3]

func _ready() -> void:
	super()
	_apply_v31_farmer()
	ui.show_message("v3.1: new four-direction farmer walk sheet with clearly separated leg poses; v3.0 step hold and v2.8 collisions retained.")

func _apply_v18_farmer() -> void:
	_apply_v31_farmer()
func _apply_v19_farmer() -> void:
	_apply_v31_farmer()
func _apply_v22_farmer() -> void:
	_apply_v31_farmer()
func _apply_v23_farmer() -> void:
	_apply_v31_farmer()
func _apply_v24_farmer() -> void:
	_apply_v31_farmer()
func _apply_v28_farmer() -> void:
	_apply_v31_farmer()
func _apply_v29_farmer() -> void:
	_apply_v31_farmer()
func _apply_v30_farmer() -> void:
	_apply_v31_farmer()

func _apply_v24_walk_timing() -> void:
	_apply_v31_walk_timing()
func _apply_v28_walk_timing() -> void:
	_apply_v31_walk_timing()
func _apply_v29_walk_timing() -> void:
	_apply_v31_walk_timing()
func _apply_v30_walk_timing() -> void:
	_apply_v31_walk_timing()

func _apply_v31_farmer() -> void:
	if not player:
		return
	if player.custom_character_sheet != FARMER_WALK_SHEET_V31:
		player.set_custom_character_sheet(FARMER_WALK_SHEET_V31, 4, 4, Vector2(0.88, 0.88))
	if player.character_sprite:
		player.character_sprite.modulate = Color.WHITE
		player.character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _apply_v31_walk_timing() -> void:
	if not player or not player.character_sprite:
		return
	_apply_v31_farmer()

	var row := 0
	if absf(player.facing.x) > absf(player.facing.y):
		row = 1 if player.facing.x > 0.0 else 2
	else:
		row = 0 if player.facing.y >= 0.0 else 3

	if not player.is_walk_visual_active():
		player.character_sprite.frame_coords = Vector2i(0, row)
		player.character_sprite.position = Vector2(0, -28)
		return

	# FarmPlayer walk_time advances at 8 units/sec. 0.75 yields a readable
	# ~6 fps four-pose cycle on mobile: left plant -> contact -> right plant -> contact.
	var phase: int = int(floor(player.walk_time * 0.75)) % v31_walk_sequence.size()
	player.character_sprite.frame_coords = Vector2i(v31_walk_sequence[phase], row)
	player.character_sprite.position = Vector2(0, -29 if phase % 2 == 0 else -28)
