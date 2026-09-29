extends Control

signal move_changed(value: Vector2)

var touch_id := -1
var knob := Vector2.ZERO
const RADIUS := 40.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			_set_knob(event.position)
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			knob = Vector2.ZERO
			move_changed.emit(Vector2.ZERO)
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_set_knob(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			_set_knob(event.position)
		else:
			knob = Vector2.ZERO
			move_changed.emit(Vector2.ZERO)
			queue_redraw()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_set_knob(event.position)

func _set_knob(local_pos: Vector2) -> void:
	var center := size * 0.5
	knob = (local_pos - center).limit_length(RADIUS)
	move_changed.emit(knob / RADIUS)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, RADIUS + 11.0, Color(0.10, 0.16, 0.09, 0.12))
	draw_circle(center, RADIUS, Color(0.96, 0.90, 0.72, 0.21))
	draw_circle(center + knob, 18.0, Color(0.98, 0.91, 0.67, 0.66))
	draw_arc(center, RADIUS + 3.0, 0.0, TAU, 36, Color(0.28, 0.36, 0.18, 0.20), 2.0)
