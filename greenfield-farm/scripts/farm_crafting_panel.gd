extends CanvasLayer
class_name FarmCraftingPanel

signal open_state_changed(open: bool)
signal craft_requested(recipe: String)

var panel: Panel
var resource_label: Label
var upgrade_label: Label
var is_open := false

func _ready() -> void:
	layer = 17
	_build_ui()

func _style(fill: Color, border: Color, radius: int = 14, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0,0,0,0.30)
	s.shadow_size = 7
	return s

func _button(text: String, y: float, recipe: String) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(34,y)
	b.size = Vector2(512,72)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_stylebox_override("normal", _style(Color("#5d4530"),Color("#d0a25f"),12,2))
	b.add_theme_stylebox_override("pressed", _style(Color("#493624"),Color.WHITE,12,2))
	b.add_theme_color_override("font_color",Color("#fff0cb"))
	panel.add_child(b)
	b.pressed.connect(_on_recipe_pressed.bind(recipe))
	return b

func _build_ui() -> void:
	panel = Panel.new()
	panel.position = Vector2(350,95)
	panel.size = Vector2(580,530)
	panel.add_theme_stylebox_override("panel",_style(Color("#2b211af2"),Color("#c58e50"),18,3))
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "KITCHEN & WORKBENCH"
	title.position = Vector2(24,18)
	title.size = Vector2(450,34)
	title.add_theme_font_size_override("font_size",23)
	title.add_theme_color_override("font_color",Color("#ffe8b9"))
	panel.add_child(title)

	resource_label = Label.new()
	resource_label.position = Vector2(24,58)
	resource_label.size = Vector2(520,54)
	resource_label.add_theme_font_size_override("font_size",13)
	resource_label.add_theme_color_override("font_color",Color("#e2c89c"))
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(resource_label)

	_button("CRAFT 5 BAIT\nCost: 1 Carrot + 1 Corn",126,"bait")
	_button("MIX 5 ANIMAL FEED\nCost: 2 Corn",210,"feed")
	_button("BUILD COPPER REEL UPGRADE\nCost: 12 Stone + 5 Copper",294,"reel_upgrade")

	upgrade_label = Label.new()
	upgrade_label.position = Vector2(34,382)
	upgrade_label.size = Vector2(512,54)
	upgrade_label.add_theme_font_size_override("font_size",13)
	upgrade_label.add_theme_color_override("font_color",Color("#b9d99b"))
	upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(upgrade_label)

	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(380,462)
	close.size = Vector2(166,46)
	close.add_theme_stylebox_override("normal",_style(Color("#614633"),Color("#bd9157"),10,2))
	close.add_theme_color_override("font_color",Color.WHITE)
	panel.add_child(close)
	close.pressed.connect(close_panel)

func open_panel(resources: Dictionary, reel_upgraded: bool, feed_stock: int) -> void:
	is_open = true
	panel.visible = true
	refresh(resources,reel_upgraded,feed_stock)
	open_state_changed.emit(true)

func refresh(resources: Dictionary, reel_upgraded: bool, feed_stock: int) -> void:
	resource_label.text = "Carrot %d  •  Corn %d  •  Stone %d  •  Copper %d  •  Bait %d  •  Feed %d" % [
		int(resources.get("carrot",0)), int(resources.get("corn",0)), int(resources.get("stone",0)),
		int(resources.get("copper",0)), int(resources.get("bait",0)), feed_stock
	]
	upgrade_label.text = "Copper Reel: INSTALLED — permanently wider catch timing." if reel_upgraded else "Copper Reel: not installed. Mining resources can permanently improve fishing."

func close_panel() -> void:
	if not is_open:
		return
	is_open = false
	panel.visible = false
	open_state_changed.emit(false)

func _on_recipe_pressed(recipe: String) -> void:
	if is_open:
		craft_requested.emit(recipe)
