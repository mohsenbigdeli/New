extends "res://scripts/main_v29.gd"

# v3.0 keeps the detailed v2.9 watercolor farmer and v2.8 world/collisions,
# but fixes the visual gait itself: short joystick taps now finish a planted
# step instead of snapping straight back to idle and looking like a slide.
var v30_walk_sequence: Array[int] = [1, 2, 3, 2]

func _ready() -> void:
	super()
	_apply_v30_farmer()
	ui.show_message("v3.0: short moves now complete a visible planted step; watercolor farmer, trees and world collisions are retained.")

func _apply_v18_farmer() -> void:
	_apply_v30_farmer()

func _apply_v19_farmer() -> void:
	_apply_v30_farmer()

func _apply_v22_farmer() -> void:
	_apply_v30_farmer()

func _apply_v23_farmer() -> void:
	_apply_v30_farmer()

func _apply_v24_farmer() -> void:
	_apply_v30_farmer()

func _apply_v28_farmer() -> void:
	_apply_v30_farmer()

func _apply_v29_farmer() -> void:
	_apply_v30_farmer()

func _apply_v24_walk_timing() -> void:
	_apply_v30_walk_timing()

func _apply_v28_walk_timing() -> void:
	_apply_v30_walk_timing()

func _apply_v29_walk_timing() -> void:
	_apply_v30_walk_timing()

func _apply_v30_farmer() -> void:
	if not player:
		return
	var tex: Texture2D = _load_v24_farmer_texture()
	if not tex:
		return
	if player.custom_character_sheet != tex:
		player.set_custom_character_sheet(tex, 4, 4, Vector2(3.15, 3.15))
	if player.character_sprite:
		player.character_sprite.modulate = Color.WHITE
		player.character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _apply_v30_walk_timing() -> void:
	if not player or not player.character_sprite:
		return
	_apply_v30_farmer()

	var row := 0
	if absf(player.facing.x) > absf(player.facing.y):
		row = 1 if player.facing.x > 0.0 else 2
	else:
		row = 0 if player.facing.y >= 0.0 else 3

	var visual_walk := player.is_walk_visual_active()
	if not visual_walk:
		player.character_sprite.frame_coords = Vector2i(0, row)
		player.character_sprite.position = Vector2(0, -20)
		return

	# walk_time already advances at 8 units/sec in FarmPlayer. This multiplier
	# gives a clearly readable contact/stride rhythm on phones while the player's
	# short visual hold lets a tap finish the current foot plant.
	var phase: int = int(floor(player.walk_time * 1.28)) % v30_walk_sequence.size()
	player.character_sprite.frame_coords = Vector2i(v30_walk_sequence[phase], row)
	player.character_sprite.position = Vector2(0, -21.3 if phase % 2 == 0 else -20.0)
