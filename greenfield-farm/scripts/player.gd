extends CharacterBody2D
class_name FarmPlayer

signal action_requested(target_position: Vector2)

const TEX_DOWN: Texture2D = preload("res://assets/art/player_down.svg")
const TEX_UP: Texture2D = preload("res://assets/art/player_up.svg")
const TEX_LEFT: Texture2D = preload("res://assets/art/player_left.svg")
const TEX_RIGHT: Texture2D = preload("res://assets/art/player_right.svg")

var speed := 285.0
var facing := Vector2.DOWN
var virtual_move := Vector2.ZERO
var can_act := true
var controls_locked := false
var world_size := Vector2(2304, 1536)
var walk_time := 0.0
var is_walking := false
var character_sprite: Sprite2D
var camera: Camera2D
var action_flash := 0.0
var equipped_tool := 0

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17
	capsule.height = 46
	shape.shape = capsule
	shape.position = Vector2(0, 13)
	add_child(shape)

	character_sprite = Sprite2D.new()
	character_sprite.texture = TEX_DOWN
	character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	character_sprite.position = Vector2(0, -10)
	character_sprite.z_index = 2
	character_sprite.scale = Vector2(1.30, 1.30)
	add_child(character_sprite)

	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.5
	camera.zoom = Vector2(1.16, 1.16)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_size.x)
	camera.limit_bottom = int(world_size.y)
	add_child(camera)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if action_flash > 0.0:
		action_flash = maxf(0.0, action_flash - delta)
	if controls_locked:
		velocity = Vector2.ZERO
		is_walking = false
		_update_sprite()
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
	position.x = clamp(position.x, 42.0, world_size.x - 42.0)
	position.y = clamp(position.y, 56.0, world_size.y - 48.0)
	_update_sprite()
	queue_redraw()

func _update_sprite() -> void:
	if not character_sprite:
		return
	if absf(facing.x) > absf(facing.y):
		character_sprite.texture = TEX_RIGHT if facing.x > 0.0 else TEX_LEFT
	else:
		character_sprite.texture = TEX_DOWN if facing.y >= 0.0 else TEX_UP

	var bob := 0.0
	var sway := 0.0
	if is_walking:
		bob = absf(sin(walk_time)) * 3.0
		sway = sin(walk_time) * 0.022
	character_sprite.position = Vector2(0, -10 - bob)
	character_sprite.rotation = sway
	character_sprite.scale = Vector2(1.30, 1.30)
	if action_flash > 0.0:
		var t := action_flash / 0.22
		character_sprite.scale = Vector2(1.34 + 0.05*(1.0-t), 1.24)
		character_sprite.rotation += sin(t * PI) * 0.06 * signf(facing.x if absf(facing.x) > 0.2 else 1.0)

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
		virtual_move = dir.limit_length(1.0)

func set_controls_locked(locked: bool) -> void:
	controls_locked = locked
	if locked:
		virtual_move = Vector2.ZERO
		velocity = Vector2.ZERO

func set_world_bounds(size: Vector2, zoom_value: float = 1.16) -> void:
	world_size = size
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(size.x)
		camera.limit_bottom = int(size.y)
		camera.zoom = Vector2(zoom_value, zoom_value)
		camera.reset_smoothing()

func set_equipped_tool(index: int) -> void:
	equipped_tool = clampi(index, 0, 5)

func request_action() -> void:
	if not can_act or controls_locked:
		return
	action_flash = 0.22
	action_requested.emit(position + facing.normalized() * 67.0)
	queue_redraw()
	can_act = false
	await get_tree().create_timer(0.20).timeout
	can_act = true

func _draw() -> void:
	_draw_shadow(Vector2(0, 32), Vector2(28, 9), Color(0,0,0,0.24))
	var marker_alpha := 0.62 if action_flash > 0.0 else 0.20
	var target := facing.normalized()*43.0 + Vector2(0,7)
	draw_circle(target, 4.0, Color(1,0.95,0.75,marker_alpha))
	if action_flash > 0.0:
		_draw_tool_action()

func _draw_tool_action() -> void:
	var d := facing.normalized()
	var side := Vector2(-d.y, d.x)
	var hand := d * 25.0 + Vector2(0,-7)
	match equipped_tool:
		0:
			draw_line(hand - d*7.0, hand + d*32.0, Color("#8b633f"), 6.0)
			draw_line(hand + d*31.0 - side*12.0, hand + d*31.0 + side*12.0, Color("#b9b2a0"), 7.0)
		1,2,3:
			for i in range(4):
				var spread := side * float(i-1.5) * 7.0
				draw_circle(hand + d*(25.0 + i*5.0) + spread, 3.0, Color("#d6b567"))
		4:
			draw_rect(Rect2(hand + d*8.0 - Vector2(10,8), Vector2(20,16)), Color("#6fa8ba"), true)
			draw_line(hand + d*17.0, hand + d*31.0 + side*7.0, Color("#94c7d5"), 5.0)
			for i in range(3):
				draw_circle(hand + d*(36.0 + i*7.0) + side*float(i-1)*6.0, 3.2, Color(0.55,0.82,0.95,0.85))
		5:
			for i in range(4):
				var a := TAU * float(i) / 4.0
				var p := hand + d*34.0 + Vector2(cos(a),sin(a))*13.0
				draw_line(p-Vector2(4,0), p+Vector2(4,0), Color("#ffe27a"), 2.5)
				draw_line(p-Vector2(0,4), p+Vector2(0,4), Color("#ffe27a"), 2.5)

func _draw_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
