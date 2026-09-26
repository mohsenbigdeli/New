extends "res://scripts/main_v10.gd"

func _ready() -> void:
	super()
	_apply_v11_composition()
	get_viewport().size_changed.connect(_apply_v11_composition)
	ui.show_message("v1.1 Art Pass: wider framing, compact HUD, smaller touch controls and cleaner composition.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if player and player.camera and room == "outside":
		player.camera.zoom = Vector2(1.05, 1.05)
		player.camera.reset_smoothing()

func _apply_v11_composition() -> void:
	if not ui or not inventory_ui:
		return
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var w: float = view_size.x
	var h: float = view_size.y

	# Top HUD: substantially shorter and less dominant.
	ui.info_panel.size = Vector2(290,44)
	ui.info_panel.position = Vector2(8,7)
	ui.day_label.position = Vector2(10,15)
	ui.day_label.add_theme_font_size_override("font_size",13)
	ui.time_label.position = Vector2(88,15)
	ui.time_label.add_theme_font_size_override("font_size",13)
	ui.money_label.position = Vector2(158,15)
	ui.money_label.add_theme_font_size_override("font_size",13)
	ui.weather_label.position = Vector2(218,17)
	ui.weather_label.add_theme_font_size_override("font_size",9)
	ui.inventory_label.position = Vector2(10,32)
	ui.inventory_label.size = Vector2(270,10)
	ui.inventory_label.add_theme_font_size_override("font_size",7)
	if ui.info_panel.get_child_count() > 0 and ui.info_panel.get_child(0) is Label:
		var title := ui.info_panel.get_child(0) as Label
		title.position = Vector2(10,3)
		title.add_theme_font_size_override("font_size",7)

	ui.energy_panel.size = Vector2(224,44)
	ui.energy_panel.position = Vector2(306,7)
	ui.energy_label.position = Vector2(11,4)
	ui.energy_label.add_theme_font_size_override("font_size",8)
	ui.shipping_label.position = Vector2(158,4)
	ui.shipping_label.add_theme_font_size_override("font_size",8)
	ui.energy_bar.position = Vector2(11,22)
	ui.energy_bar.size = Vector2(202,12)

	ui.quest_panel.size = Vector2(232,44)
	ui.quest_panel.position = Vector2(maxf(540.0,w-374.0),7)
	ui.quest_label.position = Vector2(10,17)
	ui.quest_label.size = Vector2(212,22)
	ui.quest_label.add_theme_font_size_override("font_size",8)
	if ui.quest_panel.get_child_count() > 0 and ui.quest_panel.get_child(0) is Label:
		var quest_title := ui.quest_panel.get_child(0) as Label
		quest_title.position = Vector2(10,3)
		quest_title.add_theme_font_size_override("font_size",7)

	ui.save_button.size = Vector2(48,23)
	ui.load_button.size = Vector2(48,23)
	ui.save_button.position = Vector2(w-108.0,7.0)
	ui.load_button.position = Vector2(w-56.0,7.0)
	ui.save_button.add_theme_font_size_override("font_size",8)
	ui.load_button.add_theme_font_size_override("font_size",8)

	inventory_ui.bag_button.size = Vector2(48,23)
	inventory_ui.bag_button.position = Vector2(w-56.0,34.0)
	inventory_ui.bag_button.add_theme_font_size_override("font_size",8)

	# Bottom hotbar: smaller, icon-first, leaves more of the farm visible.
	ui.hotbar_panel.size = Vector2(370,40)
	for i in range(ui.tool_buttons.size()):
		var tool_button: Button = ui.tool_buttons[i]
		tool_button.position = Vector2(5 + i*60,5)
		tool_button.size = Vector2(56,30)
		tool_button.add_theme_constant_override("icon_max_width",26)
	ui.hotbar_panel.position = Vector2((w-ui.hotbar_panel.size.x)*0.5,h-46.0)

	# Touch controls are intentionally unobtrusive.
	ui.joystick.size = Vector2(88,88)
	ui.joystick.position = Vector2(14.0,h-100.0)
	ui.action_button.size = Vector2(64,64)
	ui.action_button.position = Vector2(w-78.0,h-78.0)
	ui.action_button.add_theme_font_size_override("font_size",12)
	ui.action_button.modulate = Color(1,1,1,0.80)

	ui.context_panel.size = Vector2(264,24)
	ui.context_label.position = Vector2(7,3)
	ui.context_label.size = Vector2(250,17)
	ui.context_label.add_theme_font_size_override("font_size",9)
	ui.context_panel.position = Vector2((w-ui.context_panel.size.x)*0.5,h-76.0)

	ui.toast_panel.size = Vector2(460,28)
	ui.message_label.position = Vector2(10,4)
	ui.message_label.size = Vector2(440,18)
	ui.message_label.add_theme_font_size_override("font_size",9)
	ui.toast_panel.position = Vector2((w-ui.toast_panel.size.x)*0.5,56.0)

	# Outside framing: show more world and keep edge NPCs/buildings inside the shot.
	if interiors.active_room == "outside" and player and player.camera:
		player.camera.zoom = Vector2(1.05,1.05)
