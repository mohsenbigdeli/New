extends "res://scripts/main_v11.gd"

var storybook_art: FarmStorybookArt

func _ready() -> void:
	super()
	player.z_index = 4
	storybook_art = FarmStorybookArt.new()
	storybook_art.name = "StorybookArt"
	add_child(storybook_art)
	storybook_art.setup(farm)
	storybook_art.set_active(interiors.active_room == "outside")
	ui.show_message("v1.2 Storybook Art: hand-painted meadow, organic pond, softer nature and authored NPC artwork.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if storybook_art:
		storybook_art.set_active(room == "outside")
