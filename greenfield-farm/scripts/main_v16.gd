extends "res://scripts/main_v15.gd"

var painted_world_v16: FarmPaintedWorldV16

func _ready() -> void:
	super()
	_disable_legacy_outdoor_art()
	if painted_world_v15:
		painted_world_v15.set_active(false)
	painted_world_v16 = FarmPaintedWorldV16.new()
	painted_world_v16.name = "PaintedWorldV16"
	add_child(painted_world_v16)
	painted_world_v16.setup(farm)
	painted_world_v16.set_active(interiors.active_room == "outside")
	_apply_v16_composition()
	ui.show_message("v1.6 Clean Storybook Farm: unified outdoor renderer, natural meadow, smaller pond and corrected world scale.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	_disable_legacy_outdoor_art()
	if painted_world_v15:
		painted_world_v15.set_active(false)
	if painted_world_v16:
		painted_world_v16.set_active(room == "outside")
	if room == "outside":
		farm.visible = false
		if player and player.camera:
			player.camera.zoom = Vector2(0.94,0.94)
			player.camera.reset_smoothing()

func _disable_legacy_outdoor_art() -> void:
	# Earlier releases accumulated several visual overlays. They are intentionally
	# disabled in v1.6 so the world is rendered exactly once.
	if visual_polish:
		visual_polish.set_active(false)
	if plot_polish:
		plot_polish.set_active(false)
	if storybook_art:
		storybook_art.set_active(false)
	if painterly_v13:
		painterly_v13.set_active(false)
	if cinematic_v14:
		cinematic_v14.set_active(false)
	if farm:
		farm.visible = false

func _apply_v16_composition() -> void:
	if player and player.camera and interiors.active_room == "outside":
		# Slightly wider framing keeps the farmhouse roof and nearby trees inside the shot.
		player.camera.zoom = Vector2(0.94,0.94)
		player.camera.reset_smoothing()

	if not ui:
		return
	# Controls stay compact but gain enough contrast to read over the brighter meadow.
	if ui.joystick:
		ui.joystick.modulate = Color(1.0,1.0,1.0,0.96)
	if ui.action_button:
		ui.action_button.modulate = Color(1.0,1.0,1.0,0.92)
		ui.action_button.add_theme_font_size_override("font_size",13)
	if ui.hotbar_panel:
		ui.hotbar_panel.modulate = Color(1.0,1.0,1.0,0.96)
	if ui.info_panel:
		ui.info_panel.modulate = Color(1.0,1.0,1.0,0.97)
	if ui.energy_panel:
		ui.energy_panel.modulate = Color(1.0,1.0,1.0,0.97)
	if ui.quest_panel:
		ui.quest_panel.modulate = Color(1.0,1.0,1.0,0.97)
