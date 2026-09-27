extends "res://scripts/main_v20.gd"

var painted_world_v21: FarmPaintedWorldV21

func _ready() -> void:
	super()
	if painted_world_v20:
		painted_world_v20.set_active(false)
	painted_world_v21 = FarmPaintedWorldV21.new()
	painted_world_v21.name = "PaintedWorldV21"
	add_child(painted_world_v21)
	painted_world_v21.setup(farm)
	painted_world_v21.set_active(interiors.active_room == "outside")
	ui.show_message("v2.1 Character Motion + Tree Variety: animated watercolor walking and four distinct tree silhouettes.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painted_world_v17:
		painted_world_v17.set_active(false)
	if painted_world_v18:
		painted_world_v18.set_active(false)
	if painted_world_v19:
		painted_world_v19.set_active(false)
	if painted_world_v20:
		painted_world_v20.set_active(false)
	if painted_world_v21:
		painted_world_v21.set_active(room == "outside")
	if room == "outside" and farm:
		farm.visible = false
