extends CanvasLayer
class_name FarmInventoryPanel

signal open_state_changed(open: bool)
signal transfer_requested(item_key: String, direction: String)

var panel: Panel
var bag_button: Button
var title_label: Label
var subtitle_label: Label
var bag_values: Dictionary = {}
var chest_values: Dictionary = {}
var row_labels: Dictionary = {}
var left_buttons: Dictionary = {}
var right_buttons: Dictionary = {}
var is_open := false
var chest_mode := false

const ITEMS := [
	{"key":"seed_turnip", "name":"Turnip Seeds"},
	{"key":"seed_carrot", "name":"Carrot Seeds"},
	{"key":"seed_corn", "name":"Corn Seeds"},
	{"key":"turnip", "name":"Turnip"},
	{"key":"carrot", "name":"Carrot"},
	{"key":"corn", "name":"Corn"},
	{"key":"egg", "name":"Egg"},
	{"key":"milk", "name":"Milk"},
	{"key":"fish", "name":"Fresh Fish"},
	{"key":"stone", "name":"Stone"},
	{"key":"copper", "name":"Copper Ore"},
	{"key":"bait", "name":"Fishing Bait"}
]

func _ready() -> void:
	layer = 14
	_build_bag_button()
	_build_panel()
	get_viewport().size_changed.connect(_layout_for_viewport)
	call_deferred("_layout_for_viewport")

func _layout_for_viewport() -> void:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	if bag_button:
		bag_button.position = Vector2(view_size.x-74.0,47.0)
	if panel:
		panel.position = Vector2((view_size.x-panel.size.x)*0.5,(view_size.y-panel.size.y)*0.5)

func _style_box(fill: Color, border: Color, radius: int = 12, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.04,0.02,0.01,0.34)
	style.shadow_size = 7
	return style

func _style_button(button: Button, accent := Color("#876040")) -> void:
	button.add_theme_stylebox_override("normal", _style_box(Color("#5e432fdc"), Color("#d3a25f"), 8, 2))
	button.add_theme_stylebox_override("hover", _style_box(Color("#76543aee"), Color("#f0c97e"), 8, 2))
	button.add_theme_stylebox_override("pressed", _style_box(accent.darkened(0.15), Color("#ffe2a2"), 8, 2))
	button.add_theme_color_override("font_color", Color("#fff0cc"))
	button.add_theme_font_size_override("font_size", 12)

func _label(parent: Node, pos: Vector2, size: Vector2, text: String, font_size: int, color := Color("#f5e6c7")) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.35))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label

func _build_bag_button() -> void:
	bag_button = Button.new()
	bag_button.text = "BAG"
	bag_button.size = Vector2(62,30)
	_style_button(bag_button, Color("#6f8650"))
	bag_button.add_theme_font_size_override("font_size",10)
	add_child(bag_button)
	bag_button.pressed.connect(_on_bag_pressed)

func _build_panel() -> void:
	panel = Panel.new()
	panel.size = Vector2(708,672)
	panel.add_theme_stylebox_override("panel", _style_box(Color("#2b2119f2"), Color("#c89b5b"), 18, 3))
	panel.visible = false
	add_child(panel)

	var header := Panel.new()
	header.position = Vector2(16,14)
	header.size = Vector2(676,62)
	header.add_theme_stylebox_override("panel", _style_box(Color("#60432f"), Color("#d3a25f"), 12, 2))
	panel.add_child(header)
	title_label = _label(header, Vector2(18,5), Vector2(420,27), "BACKPACK", 21, Color("#fff0c8"))
	subtitle_label = _label(header, Vector2(19,32), Vector2(560,20), "Farm, animal, fishing and mining items", 11, Color("#e7c998"))

	var close := Button.new()
	close.text = "X"
	close.position = Vector2(620,10)
	close.size = Vector2(40,40)
	_style_button(close, Color("#9d5448"))
	header.add_child(close)
	close.pressed.connect(close_panel)

	_label(panel, Vector2(24,82), Vector2(260,20), "ITEM", 10, Color("#d1ad70"))
	_label(panel, Vector2(362,82), Vector2(92,20), "BAG", 10, Color("#d1ad70"))
	_label(panel, Vector2(548,82), Vector2(108,20), "CHEST", 10, Color("#d1ad70"))

	for i in range(ITEMS.size()):
		var item: Dictionary = ITEMS[i]
		var key := String(item["key"])
		var y := 103 + i * 43
		var row := Panel.new()
		row.position = Vector2(20,y)
		row.size = Vector2(668,36)
		row.add_theme_stylebox_override("panel", _style_box(Color("#3c2d22c7"), Color("#755536"), 8, 1))
		panel.add_child(row)
		_label(row, Vector2(14,6), Vector2(245,24), String(item["name"]), 12)
		var bag_count := _label(row, Vector2(342,6), Vector2(70,24), "0", 13, Color("#ffd77a"))
		bag_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_labels[key + "_bag"] = bag_count
		var chest_count := _label(row, Vector2(528,6), Vector2(70,24), "-", 13, Color("#b7d98d"))
		chest_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_labels[key + "_chest"] = chest_count

		var to_chest := Button.new()
		to_chest.text = ">"
		to_chest.position = Vector2(430,3)
		to_chest.size = Vector2(44,30)
		_style_button(to_chest, Color("#7a8f55"))
		row.add_child(to_chest)
		to_chest.pressed.connect(_transfer.bind(key, "to_chest"))
		left_buttons[key] = to_chest

		var to_bag := Button.new()
		to_bag.text = "<"
		to_bag.position = Vector2(480,3)
		to_bag.size = Vector2(44,30)
		_style_button(to_bag, Color("#8f7650"))
		row.add_child(to_bag)
		to_bag.pressed.connect(_transfer.bind(key, "to_bag"))
		right_buttons[key] = to_bag

	var footer := _label(panel, Vector2(28,628), Vector2(650,30), "Farm storage accepts crops, animal products, fish, ore, stone and bait.", 11, Color("#d6bb8d"))
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _on_bag_pressed() -> void:
	if is_open:
		close_panel()
	else:
		open_bag(bag_values)

func open_bag(bag: Dictionary) -> void:
	bag_values = bag.duplicate(true)
	chest_values = {}
	chest_mode = false
	is_open = true
	panel.visible = true
	title_label.text = "BACKPACK"
	subtitle_label.text = "Farm, animal, fishing and mining items"
	_refresh_rows()
	open_state_changed.emit(true)

func open_chest(bag: Dictionary, chest: Dictionary) -> void:
	bag_values = bag.duplicate(true)
	chest_values = chest.duplicate(true)
	chest_mode = true
	is_open = true
	panel.visible = true
	title_label.text = "FARM STORAGE"
	subtitle_label.text = "Move one item at a time between bag and chest"
	_refresh_rows()
	open_state_changed.emit(true)

func refresh_data(bag: Dictionary, chest: Dictionary) -> void:
	bag_values = bag.duplicate(true)
	if chest_mode:
		chest_values = chest.duplicate(true)
	_refresh_rows()

func close_panel() -> void:
	if not is_open:
		return
	is_open = false
	chest_mode = false
	panel.visible = false
	open_state_changed.emit(false)

func _transfer(item_key: String, direction: String) -> void:
	if not chest_mode:
		return
	transfer_requested.emit(item_key, direction)

func _refresh_rows() -> void:
	for item in ITEMS:
		var key := String(item["key"])
		var bag_count := int(bag_values.get(key, 0))
		var chest_count := int(chest_values.get(key, 0))
		var bag_label := row_labels.get(key + "_bag") as Label
		var chest_label := row_labels.get(key + "_chest") as Label
		if bag_label:
			bag_label.text = str(bag_count)
		if chest_label:
			chest_label.text = str(chest_count) if chest_mode else "-"
		var to_chest := left_buttons.get(key) as Button
		var to_bag := right_buttons.get(key) as Button
		if to_chest:
			to_chest.visible = chest_mode
			to_chest.disabled = bag_count <= 0
		if to_bag:
			to_bag.visible = chest_mode
			to_bag.disabled = chest_count <= 0
