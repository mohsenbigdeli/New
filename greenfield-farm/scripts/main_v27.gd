extends "res://scripts/main_v26.gd"

const FARM_LIFE_V27 := preload("res://scripts/farm_life_v27.gd")
var farm_life_v27: Node2D

func _ready() -> void:
	super()
	_install_v27_world_life()
	call_deferred("_apply_v27_hud_polish")
	ui.show_message("v2.7: clearer mobile messages, larger action HUD and a livelier Greenfield world.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if farm_life_v27 and farm_life_v27.has_method("set_active"):
		farm_life_v27.set_active(room == "outside")

# Parent v2.6 already owns the viewport-size signal. Override that same layout
# pass so every resize also reapplies the v2.7 readability fixes.
func _layout_mobile_hud_v26() -> void:
	super._layout_mobile_hud_v26()
	_apply_v27_hud_polish()

func _install_v27_world_life() -> void:
	if farm_life_v27:
		return
	farm_life_v27 = FARM_LIFE_V27.new()
	farm_life_v27.name = "FarmLifeV27"
	add_child(farm_life_v27)
	if farm_life_v27.has_method("set_active"):
		farm_life_v27.set_active(interiors.active_room == "outside")

func _apply_v27_hud_polish() -> void:
	if not ui:
		return
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var w := view_size.x
	var h := view_size.y

	# Device video showed the transient dialogue strip as almost black. Replace
	# it with a bright parchment card and explicit dark text for outdoor scenes.
	if ui.toast_panel:
		ui.toast_panel.size = Vector2(650, 42)
		ui.toast_panel.position = Vector2((w - ui.toast_panel.size.x) * 0.5, 84.0)
		var toast_style := StyleBoxFlat.new()
		toast_style.bg_color = Color(0.975, 0.925, 0.79, 0.97)
		toast_style.border_color = Color(0.34, 0.24, 0.15, 0.88)
		toast_style.set_border_width_all(2)
		toast_style.corner_radius_top_left = 12
		toast_style.corner_radius_top_right = 12
		toast_style.corner_radius_bottom_left = 12
		toast_style.corner_radius_bottom_right = 12
		toast_style.shadow_color = Color(0.08, 0.05, 0.03, 0.24)
		toast_style.shadow_size = 5
		ui.toast_panel.add_theme_stylebox_override("panel", toast_style)
	if ui.message_label:
		ui.message_label.position = Vector2(16, 8)
		ui.message_label.size = Vector2(618, 26)
		ui.message_label.add_theme_font_size_override("font_size", 12)
		ui.message_label.add_theme_color_override("font_color", Color("#3f3023"))
		ui.message_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0))

	# The interaction prompt remains above the hotbar but gains a little width
	# and the same high-contrast parchment treatment.
	if ui.context_panel:
		ui.context_panel.size = Vector2(380, 34)
		ui.context_panel.position = Vector2((w - ui.context_panel.size.x) * 0.5, h - 108.0)
		var context_style := StyleBoxFlat.new()
		context_style.bg_color = Color(0.97, 0.92, 0.79, 0.97)
		context_style.border_color = Color(0.36, 0.27, 0.18, 0.84)
		context_style.set_border_width_all(2)
		context_style.corner_radius_top_left = 12
		context_style.corner_radius_top_right = 12
		context_style.corner_radius_bottom_left = 12
		context_style.corner_radius_bottom_right = 12
		ui.context_panel.add_theme_stylebox_override("panel", context_style)
	if ui.context_label:
		ui.context_label.position = Vector2(10, 6)
		ui.context_label.size = Vector2(360, 22)
		ui.context_label.add_theme_font_size_override("font_size", 12)
		ui.context_label.add_theme_color_override("font_color", Color("#443326"))
		ui.context_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0))

	# Give the six tool slots more touch area while keeping them centered and
	# clear of the joystick / USE button on short landscape phones.
	if ui.hotbar_panel:
		ui.hotbar_panel.size = Vector2(516, 56)
		ui.hotbar_panel.position = Vector2((w - ui.hotbar_panel.size.x) * 0.5, h - 64.0)
	for i in range(ui.tool_buttons.size()):
		var button: Button = ui.tool_buttons[i]
		button.position = Vector2(5.0 + float(i) * 85.0, 5.0)
		button.size = Vector2(81, 46)
		button.add_theme_font_size_override("font_size", 10)

	# Keep the utility row legible after the v2.6 overlap fix.
	if board_button:
		board_button.add_theme_font_size_override("font_size", 9)
	if inventory_ui and inventory_ui.bag_button:
		inventory_ui.bag_button.add_theme_font_size_override("font_size", 10)
	if ui.quest_label:
		ui.quest_label.add_theme_font_size_override("font_size", 11)
