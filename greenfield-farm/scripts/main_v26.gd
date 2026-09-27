extends "res://scripts/main_v25.gd"

# v2.6: responsive mobile HUD cleanup based on the first Android v2.5 device test.
# Keeps the gameplay systems from v2.5 while preventing the top-right utility
# controls from overlapping each other on wide landscape phones.

func _ready() -> void:
	super()
	if not get_viewport().size_changed.is_connected(_layout_mobile_hud_v26):
		get_viewport().size_changed.connect(_layout_mobile_hud_v26)
	call_deferred("_layout_mobile_hud_v26")
	ui.show_message("v2.6 Mobile HUD: Board, Bag and save controls now use a clean two-row layout.")

func _layout_contract_board() -> void:
	super._layout_contract_board()
	if not board_button or not board_panel:
		return
	var view_size: Vector2 = get_viewport().get_visible_rect().size

	# Row 2 utility controls. BAG occupies the far-right 62 px, so BOARD sits
	# immediately to its left with a small gap. This avoids the SAVE/LOAD row.
	board_button.size = Vector2(92, 30)
	board_button.position = Vector2(view_size.x - 172.0, 47.0)
	board_button.add_theme_font_size_override("font_size", 8)

	# Keep the parchment centered and safely inside short landscape screens.
	board_panel.position = Vector2(
		(view_size.x - board_panel.size.x) * 0.5,
		maxf(72.0, (view_size.y - board_panel.size.y) * 0.5)
	)

func _layout_mobile_hud_v26() -> void:
	if not ui or not inventory_ui:
		return

	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var w: float = view_size.x
	var h: float = view_size.y

	# Preserve the existing top HUD blocks, but reserve a dedicated utility area
	# on the right: SAVE/LOAD on row 1, BOARD/BAG on row 2.
	if ui.info_panel:
		ui.info_panel.position = Vector2(12.0, 10.0)
	if ui.energy_panel:
		ui.energy_panel.position = Vector2(374.0, 10.0)
	if ui.quest_panel:
		ui.quest_panel.position = Vector2(maxf(688.0, w - 446.0), 10.0)
	if ui.save_button:
		ui.save_button.position = Vector2(w - 142.0, 11.0)
	if ui.load_button:
		ui.load_button.position = Vector2(w - 74.0, 11.0)
	if inventory_ui.bag_button:
		inventory_ui.bag_button.position = Vector2(w - 74.0, 47.0)

	# BOARD is owned by v2.5. Re-apply its layout here because GameUI and the
	# inventory layer also react to viewport changes independently.
	if board_button:
		board_button.size = Vector2(92.0, 30.0)
		board_button.position = Vector2(w - 172.0, 47.0)

	# Give transient messages a little breathing room below the two-row HUD.
	if ui.toast_panel:
		ui.toast_panel.position = Vector2((w - ui.toast_panel.size.x) * 0.5, 82.0)

	# Keep the bottom controls clear of one another on short landscape screens.
	if ui.hotbar_panel:
		ui.hotbar_panel.position = Vector2((w - ui.hotbar_panel.size.x) * 0.5, h - ui.hotbar_panel.size.y - 8.0)
	if ui.context_panel:
		ui.context_panel.position = Vector2((w - ui.context_panel.size.x) * 0.5, h - 104.0)
	if ui.joystick:
		ui.joystick.position = Vector2(18.0, h - 144.0)
	if ui.action_button:
		ui.action_button.position = Vector2(w - 108.0, h - 112.0)

	_layout_contract_board()
