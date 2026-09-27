extends Control
class_name FarmJoystick

signal vector_changed(direction: Vector2)

var direction := Vector2.ZERO
var active_touch := -1
var knob_position := Vector2.ZERO
var radius := 68.0
var knob_radius := 27.0
var deadzone := 0.07

func _ready() -> void:
	custom_minimum_size = Vector2(168, 168)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_dimensions()
	knob_position = size * 0.5
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_dimensions()
		knob_position = size * 0.5 + direction * radius
		queue_redraw()

func _sync_dimensions() -> void:
	var diameter: float = minf(size.x,size.y)
	if diameter <= 0.0:
		return
	radius = maxf(52.0,diameter * 0.38)
	knob_radius = maxf(23.0,diameter * 0.15)

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
	if direction.length() < deadzone:
		direction = Vector2.ZERO
	else:
		# Remap the deadzone so movement starts smoothly and reaches full speed sooner.
		var strength: float = clampf((direction.length()-deadzone)/(1.0-deadzone),0.0,1.0)
		direction = direction.normalized() * strength
	vector_changed.emit(direction)
	queue_redraw()

func _reset() -> void:
	direction = Vector2.ZERO
	knob_position = size * 0.5
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center + Vector2(0, 4), radius + 12.0, Color(0.05,0.04,0.03,0.14))
	draw_circle(center, radius + 9.0, Color(0.16,0.12,0.08,0.38))
	draw_circle(center, radius + 4.0, Color(0.90,0.78,0.55,0.18))
	draw_circle(center, radius, Color(0.18,0.31,0.15,0.34))
	var directions: Array[Vector2] = [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]
	for v: Vector2 in directions:
		var p: Vector2 = center + v * radius * 0.68
		draw_circle(p,3.2,Color(1,0.94,0.76,0.34))
	draw_circle(knob_position + Vector2(0,3),knob_radius+4.0,Color(0.05,0.04,0.03,0.20))
	draw_circle(knob_position,knob_radius+2.0,Color(0.94,0.81,0.56,0.78))
	draw_circle(knob_position,knob_radius-4.0,Color(0.31,0.49,0.24,0.92))
	draw_circle(knob_position-Vector2(6,6),4.0,Color(1,1,0.88,0.18))
