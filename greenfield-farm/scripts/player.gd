extends CharacterBody2D
class_name FarmPlayer

signal action_requested(target_position: Vector2)

var speed := 300.0
var facing := Vector2.DOWN
var virtual_move := Vector2.ZERO
var can_act := true
var controls_locked := false
var world_size := Vector2(2304, 1536)
var walk_time := 0.0
var is_walking := false

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 15
	capsule.height = 42
	shape.shape = capsule
	shape.position = Vector2(0, 4)
	add_child(shape)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_size.x)
	camera.limit_bottom = int(world_size.y)
	add_child(camera)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if controls_locked:
		velocity = Vector2.ZERO
		is_walking = false
		queue_redraw()
		return

	var x := int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var y := int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var keyboard := Vector2(x, y)
	var dir := keyboard if keyboard.length() > 0.01 else virtual_move
	is_walking = dir.length() > 0.01
	if is_walking:
		dir = dir.normalized()
		facing = dir
		walk_time += delta * 9.0
	else:
		walk_time = 0.0

	velocity = dir * speed
	move_and_slide()
	position.x = clamp(position.x, 36.0, world_size.x - 36.0)
	position.y = clamp(position.y, 50.0, world_size.y - 42.0)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if controls_locked:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			request_action()

func set_virtual_move(dir: Vector2) -> void:
	if controls_locked:
		virtual_move = Vector2.ZERO
	else:
		virtual_move = dir

func set_controls_locked(locked: bool) -> void:
	controls_locked = locked
	if locked:
		virtual_move = Vector2.ZERO
		velocity = Vector2.ZERO

func request_action() -> void:
	if not can_act or controls_locked:
		return
	action_requested.emit(position + facing.normalized() * 62.0)
	can_act = false
	await get_tree().create_timer(0.16).timeout
	can_act = true

func _draw() -> void:
	var bob := sin(walk_time) * 2.0 if is_walking else 0.0
	var leg_swing := sin(walk_time) * 5.0 if is_walking else 0.0
	_draw_ellipse(Vector2(0,22), Vector2(22,8), Color(0,0,0,0.22))

	# legs and boots
	draw_rect(Rect2(-14, 8+bob+leg_swing*0.25, 10, 21), Color("#405173"), true)
	draw_rect(Rect2(4, 8+bob-leg_swing*0.25, 10, 21), Color("#405173"), true)
	draw_rect(Rect2(-15, 26+bob+leg_swing*0.25, 12, 6), Color("#473a30"), true)
	draw_rect(Rect2(3, 26+bob-leg_swing*0.25, 12, 6), Color("#473a30"), true)

	# body, shirt and overalls
	draw_rect(Rect2(-20,-23+bob,40,38), Color("#df6f54"), true)
	draw_rect(Rect2(-13,-8+bob,26,23), Color("#4f7eb4"), true)
	draw_rect(Rect2(-13,-12+bob,6,14), Color("#4f7eb4"), true)
	draw_rect(Rect2(7,-12+bob,6,14), Color("#4f7eb4"), true)

	# arms
	draw_line(Vector2(-20,-12+bob), Vector2(-25,4+bob+leg_swing*0.18), Color("#efc49e"), 7)
	draw_line(Vector2(20,-12+bob), Vector2(25,4+bob-leg_swing*0.18), Color("#efc49e"), 7)

	# head and hair
	draw_circle(Vector2(0,-37+bob), 18, Color("#f1c59f"))
	draw_arc(Vector2(0,-41+bob), 18, PI, TAU, 20, Color("#4a332a"), 9)
	draw_circle(Vector2(-6,-38+bob), 1.7, Color("#2e2a27"))
	draw_circle(Vector2(6,-38+bob), 1.7, Color("#2e2a27"))
	draw_line(Vector2(-4,-30+bob), Vector2(4,-30+bob), Color("#a45d54"), 2)

	# facing marker kept subtle for touch controls
	draw_circle(facing.normalized()*34.0 + Vector2(0,3), 3.5, Color(1,1,1,0.48))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
