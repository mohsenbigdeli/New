extends CharacterBody2D
class_name FarmPlayer

signal action_requested(target_position: Vector2)

var speed := 260.0
var facing := Vector2.DOWN
var virtual_move := Vector2.ZERO
var can_act := true

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 16
	capsule.height = 40
	shape.shape = capsule
	add_child(shape)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1280
	camera.limit_bottom = 900
	add_child(camera)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var x := int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var y := int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var keyboard := Vector2(x, y)
	var dir := keyboard if keyboard.length() > 0.01 else virtual_move
	if dir.length() > 0.01:
		dir = dir.normalized()
		facing = dir
	velocity = dir * speed
	move_and_slide()
	position.x = clamp(position.x, 40.0, 1240.0)
	position.y = clamp(position.y, 40.0, 860.0)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			request_action()

func set_virtual_move(dir: Vector2) -> void:
	virtual_move = dir

func request_action() -> void:
	if not can_act:
		return
	action_requested.emit(position + facing.normalized() * 58.0)
	can_act = false
	await get_tree().create_timer(0.16).timeout
	can_act = true

func _draw() -> void:
	_draw_ellipse(Vector2(0,18), Vector2(22,8), Color(0,0,0,0.22))
	draw_rect(Rect2(-13, 8, 10, 20), Color("#3a4d72"), true)
	draw_rect(Rect2(3, 8, 10, 20), Color("#3a4d72"), true)
	draw_rect(Rect2(-20,-22,40,36), Color("#4f86c6"), true)
	draw_circle(Vector2(0,-34), 18, Color("#f2c79f"))
	draw_arc(Vector2(0,-39),18,PI,TAU,18,Color("#4a3228"),8)
	draw_line(Vector2.ZERO, facing.normalized()*30, Color(1,1,1,0.65), 3)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
