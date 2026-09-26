extends Control
class_name FarmJoystick

signal vector_changed(direction: Vector2)

var direction := Vector2.ZERO
var active_touch := -1
var knob_position := Vector2.ZERO
var radius := 46.0
var knob_radius := 20.0

func _ready() -> void:
	custom_minimum_size = Vector2(120, 120)
	mouse_filter = Control.MOUSE_FILTER_STOP
	knob_position = size * 0.5
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		knob_position = size * 0.5 + direction * radius
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			_update_from_point(event.position)
			accept_event()
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			_reset()
			accept_event()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_from_point(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active_touch = -2
			_update_from_point(event.position)
		else:
			active_touch = -1
			_reset()
		accept_event()
	elif event is InputEventMouseMotion and active_touch == -2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_from_point(event.position)
		accept_event()

func force_release() -> void:
	active_touch = -1
	_reset()

func _update_from_point(point: Vector2) -> void:
	var center: Vector2 = size * 0.5
	var offset: Vector2 = point - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	knob_position = center + offset
	direction = offset / radius
	if direction.length() < 0.10:
		direction = Vector2.ZERO
	vector_changed.emit(direction)
	queue_redraw()

func _reset() -> void:
	direction = Vector2.ZERO
	knob_position = size * 0.5
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center + Vector2(0, 4), radius + 10.0, Color(0.07, 0.05, 0.03, 0.17))
	draw_circle(center, radius + 7.0, Color(0.18, 0.13, 0.09, 0.40))
	draw_circle(center, radius + 2.0, Color(0.78, 0.66, 0.46, 0.24))
	draw_circle(center, radius, Color(0.18, 0.26, 0.14, 0.42))
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for v: Vector2 in directions:
		var p: Vector2 = center + v * 33.0
		draw_circle(p, 2.7, Color(1, 0.94, 0.76, 0.32))
	draw_circle(knob_position + Vector2(0, 2), knob_radius + 2.0, Color(0.05, 0.04, 0.03, 0.22))
	draw_circle(knob_position, knob_radius + 1.0, Color(0.92, 0.79, 0.53, 0.78))
	draw_circle(knob_position, knob_radius - 4.0, Color(0.34, 0.48, 0.25, 0.90))
	draw_circle(knob_position - Vector2(5, 6), 4.0, Color(1, 1, 0.88, 0.16))
