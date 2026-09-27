extends "res://scripts/main_v23.gd"

# The old embedded PNG is corrupt. Use the working imported sheet.
# FarmPlayer alone owns animation, avoiding competing render/physics updates.
func _ready() -> void:
	super()
	_apply_v24_farmer()
	ui.show_message("v2.4.1: repaired character art, distance-based steps and steady feet.")

func _apply_v18_farmer() -> void:
	_apply_v24_farmer()

func _apply_v19_farmer() -> void:
	_apply_v24_farmer()

func _apply_v22_farmer() -> void:
	_apply_v24_farmer()

func _apply_v23_farmer() -> void:
	_apply_v24_farmer()

func _apply_v24_farmer() -> void:
	if not player:
		return
	# Ancestors call this each render frame; only configure when changed.
	if player.custom_character_sheet != FARMER_WALK_SHEET_V23:
		player.set_custom_character_sheet(FARMER_WALK_SHEET_V23, 4, 4, Vector2(0.72, 0.72))
