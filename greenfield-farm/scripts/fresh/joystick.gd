extends Control
signal move_changed(value: Vector2)
var touch_id := -1
var mouse_active := false
var knob := Vector2.ZERO
const RADIUS := 52.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and touch_id == -1:
		touch_id = event.index
		_set_knob(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and touch_id == -1:
		mouse_active = true
		_set_knob(event.position)
		accept_event()
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_id:
		release()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_set_knob(event.position - global_position)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and mouse_active:
		release()
	elif event is InputEventMouseMotion and mouse_active:
		_set_knob(event.position - global_position)
func release() -> void:
	touch_id = -1
	mouse_active = false
	knob = Vector2.ZERO
	move_changed.emit(Vector2.ZERO)
	queue_redraw()
func _set_knob(point: Vector2) -> void:
	knob = (point - size * 0.5).limit_length(RADIUS)
	move_changed.emit(knob / RADIUS)
	queue_redraw()
func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 70, Color("244234a8"))
	draw_arc(center, 70, 0, TAU, 64, Color("dfd0a580"), 2, true)
	draw_circle(center + knob, 28, Color("f2d494dc"))
	draw_arc(center + knob, 28, 0, TAU, 32, Color("fff2c6"), 2, true)
