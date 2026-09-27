extends "res://scripts/main_v22.gd"

const FARMER_WALK_SHEET_V23: Texture2D = preload("res://assets/art/v23/farmer_walk_sheet.svg")

func _ready() -> void:
	super()
	_apply_v23_farmer()
	ui.show_message("v2.3 True Walk Cycle: real 4-direction frame animation replaces image warping; large mobile joystick retained.")

# Older parent scenes re-apply their farmer appearance from _process/_set_room_state.
# Route every one of those calls to the real v2.3 frame sheet.
func _apply_v18_farmer() -> void:
	_apply_v23_farmer()

func _apply_v19_farmer() -> void:
	_apply_v23_farmer()

func _apply_v22_farmer() -> void:
	_apply_v23_farmer()

func _apply_v23_farmer() -> void:
	if not player:
		return
	player.set_custom_character_sheet(FARMER_WALK_SHEET_V23,4,4,Vector2(0.72,0.72))
	if player.character_sprite:
		player.character_sprite.modulate = Color(1.0,0.99,0.96,1.0)
