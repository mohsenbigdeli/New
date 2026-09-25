extends CanvasLayer
class_name GameUI

signal tool_selected(index: int)
signal action_pressed
signal move_changed(dir: Vector2)
signal save_pressed
signal load_pressed

var day_label: Label
var time_label: Label
var inventory_label: Label
var message_label: Label
var tool_buttons: Array[Button] = []
var movement_state := {"left": false, "right": false, "up": false, "down": false}

func _ready() -> void:
	_build_top_bar()
	_build_hotbar()
	_build_mobile_controls()

func _make_panel(rect: Rect2, alpha := 0.82) -> ColorRect:
	var panel := ColorRect.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.color = Color(0.08,0.09,0.08,alpha)
	add_child(panel)
	return panel

func _build_top_bar() -> void:
	var p := _make_panel(Rect2(20,16,520,66), 0.78)
	day_label = Label.new()
	day_label.position=Vector2(16,9)
	day_label.add_theme_font_size_override("font_size",22)
	p.add_child(day_label)
	time_label = Label.new()
	time_label.position=Vector2(145,9)
	time_label.add_theme_font_size_override("font_size",22)
	p.add_child(time_label)
	inventory_label = Label.new()
	inventory_label.position=Vector2(260,9)
	inventory_label.add_theme_font_size_override("font_size",20)
	p.add_child(inventory_label)
	message_label = Label.new()
	message_label.position=Vector2(16,38)
	message_label.add_theme_font_size_override("font_size",14)
	p.add_child(message_label)

func _build_hotbar() -> void:
	var names := ["Hoe", "Seeds", "Water", "Harvest"]
	var p := _make_panel(Rect2(382,632,516,72), 0.84)
	for i in names.size():
		var b := Button.new()
		b.text = "%d  %s" % [i+1, names[i]]
		b.position = Vector2(8 + i*126, 8)
		b.size = Vector2(118,56)
		b.add_theme_font_size_override("font_size",18)
		b.pressed.connect(_on_tool_button_pressed.bind(i))
		p.add_child(b)
		tool_buttons.append(b)

func _build_mobile_controls() -> void:
	_add_move_button("↑", Vector2(108,536), "up")
	_add_move_button("↓", Vector2(108,646), "down")
	_add_move_button("←", Vector2(28,591), "left")
	_add_move_button("→", Vector2(188,591), "right")

	var action := Button.new()
	action.text="USE"
	action.position=Vector2(1110,570)
	action.size=Vector2(128,108)
	action.add_theme_font_size_override("font_size",26)
	add_child(action)
	action.pressed.connect(_on_action_button_pressed)

	var save := Button.new()
	save.text="SAVE"
	save.position=Vector2(1090,18)
	save.size=Vector2(80,48)
	add_child(save)
	save.pressed.connect(_on_save_button_pressed)

	var load := Button.new()
	load.text="LOAD"
	load.position=Vector2(1178,18)
	load.size=Vector2(80,48)
	add_child(load)
	load.pressed.connect(_on_load_button_pressed)

func _add_move_button(text: String, pos: Vector2, key: String) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(78,68)
	b.add_theme_font_size_override("font_size",28)
	add_child(b)
	b.button_down.connect(_set_move.bind(key, true))
	b.button_up.connect(_set_move.bind(key, false))

func _set_move(key: String, pressed: bool) -> void:
	movement_state[key] = pressed
	var x := int(movement_state["right"]) - int(movement_state["left"])
	var y := int(movement_state["down"]) - int(movement_state["up"])
	move_changed.emit(Vector2(x,y).normalized())

func _on_tool_button_pressed(index: int) -> void:
	tool_selected.emit(index)

func _on_action_button_pressed() -> void:
	action_pressed.emit()

func _on_save_button_pressed() -> void:
	save_pressed.emit()

func _on_load_button_pressed() -> void:
	load_pressed.emit()

func update_status(day: int, minute_of_day: int, seeds: int, crops: int, selected: int, energy: int) -> void:
	var hour := int(minute_of_day / 60)
	var minute := int(minute_of_day % 60)
	day_label.text = "Day %d" % day
	time_label.text = "%02d:%02d" % [hour, minute]
	inventory_label.text = "Seeds %d   Turnips %d   Energy %d" % [seeds, crops, energy]
	for i in tool_buttons.size():
		tool_buttons[i].modulate = Color("#ffe78a") if i == selected else Color.WHITE

func show_message(text: String) -> void:
	message_label.text = text
