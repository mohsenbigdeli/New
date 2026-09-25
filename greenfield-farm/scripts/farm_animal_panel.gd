extends CanvasLayer
class_name FarmAnimalPanel

signal open_state_changed(open: bool)
signal buy_animal_requested(kind: String)
signal buy_feed_requested
signal close_requested

var panel: Panel
var info_label: Label
var is_open := false

func _ready() -> void:
	layer = 16
	_build_panel()

func _style_box(fill: Color, border: Color, radius: int = 12, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.04,0.02,0.01,0.32)
	style.shadow_size = 7
	return style

func _style_button(button: Button, accent := Color("#876040")) -> void:
	button.add_theme_stylebox_override("normal", _style_box(Color("#5d422f"), Color("#d2a05e"), 10, 2))
	button.add_theme_stylebox_override("hover", _style_box(Color("#745239"), Color("#f0c77b"), 10, 2))
	button.add_theme_stylebox_override("pressed", _style_box(accent.darkened(0.15), Color("#ffe2a0"), 10, 2))
	button.add_theme_color_override("font_color", Color("#fff0ca"))
	button.add_theme_font_size_override("font_size", 15)

func _label(parent: Node, pos: Vector2, size: Vector2, text: String, font_size: int, color := Color("#f5e6c7")) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.text = text
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.add_theme_color_override("font_shadow_color",Color(0,0,0,0.30))
	l.add_theme_constant_override("shadow_offset_x",1)
	l.add_theme_constant_override("shadow_offset_y",1)
	parent.add_child(l)
	return l

func _build_panel() -> void:
	panel = Panel.new()
	panel.position = Vector2(350,126)
	panel.size = Vector2(580,470)
	panel.add_theme_stylebox_override("panel",_style_box(Color("#2b2119f4"),Color("#c69b5b"),18,3))
	panel.visible = false
	add_child(panel)

	var header := Panel.new()
	header.position = Vector2(16,16)
	header.size = Vector2(548,74)
	header.add_theme_stylebox_override("panel",_style_box(Color("#624630"),Color("#d3a25f"),12,2))
	panel.add_child(header)
	var title := _label(header,Vector2(18,9),Vector2(360,30),"BARN LEDGER",24,Color("#fff0c7"))
	title.text = "BARN LEDGER"
	var sub := _label(header,Vector2(19,42),Vector2(450,22),"Animals, feed and daily produce",12,Color("#e8c999"))
	sub.text = "Animals, feed and daily produce"

	info_label = _label(panel,Vector2(28,110),Vector2(524,90),"",15,Color("#f1dfbd"))
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var chicken := Button.new()
	chicken.text = "BUY CHICKEN\n500g"
	chicken.position = Vector2(28,218)
	chicken.size = Vector2(160,74)
	_style_button(chicken,Color("#8a704c"))
	panel.add_child(chicken)
	chicken.pressed.connect(func(): buy_animal_requested.emit("chicken"))

	var cow := Button.new()
	cow.text = "BUY COW\n1500g"
	cow.position = Vector2(210,218)
	cow.size = Vector2(160,74)
	_style_button(cow,Color("#745448"))
	panel.add_child(cow)
	cow.pressed.connect(func(): buy_animal_requested.emit("cow"))

	var feed := Button.new()
	feed.text = "BUY FEED x5\n120g"
	feed.position = Vector2(392,218)
	feed.size = Vector2(160,74)
	_style_button(feed,Color("#6f8650"))
	panel.add_child(feed)
	feed.pressed.connect(func(): buy_feed_requested.emit())

	var tips := _label(panel,Vector2(32,320),Vector2(516,80),"Feed animals at the trough each day. Pet them to raise happiness. Fed chickens lay eggs and fed cows produce milk the next morning.",13,Color("#d7bc8c"))
	tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var close := Button.new()
	close.text = "CLOSE"
	close.position = Vector2(384,406)
	close.size = Vector2(168,42)
	_style_button(close,Color("#8d5946"))
	panel.add_child(close)
	close.pressed.connect(close_panel)

func open_panel(summary: String) -> void:
	is_open = true
	panel.visible = true
	info_label.text = summary
	open_state_changed.emit(true)

func refresh(summary: String) -> void:
	if info_label:
		info_label.text = summary

func close_panel() -> void:
	if not is_open:
		return
	is_open = false
	panel.visible = false
	open_state_changed.emit(false)
	close_requested.emit()
