extends CharacterBody2D
class_name FarmPlayer

signal action_requested(target_position: Vector2)

const TEX_DOWN: Texture2D = preload("res://assets/art/player_down.svg")
const TEX_UP: Texture2D = preload("res://assets/art/player_up.svg")
const TEX_LEFT: Texture2D = preload("res://assets/art/player_left.svg")
const TEX_RIGHT: Texture2D = preload("res://assets/art/player_right.svg")

var speed := 300.0
var facing := Vector2.DOWN
var virtual_move := Vector2.ZERO
var can_act := true
var controls_locked := false
var world_size := Vector2(2304, 1536)
var walk_time := 0.0
var is_walking := false
var character_sprite: Sprite2D
var action_flash := 0.0

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 15
	capsule.height = 42
	shape.shape = capsule
	shape.position = Vector2(0, 10)
	add_child(shape)

	character_sprite = Sprite2D.new()
	character_sprite.texture = TEX_DOWN
	character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	character_sprite.position = Vector2(0, -6)
	character_sprite.z_index = 2
	add_child(character_sprite)

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
		walk_time += delta * 10.0
	else:
		walk_time = 0.0

	velocity = dir * speed
	move_and_slide()
	position.x = clamp(position.x, 36.0, world_size.x - 36.0)
	position.y = clamp(position.y, 50.0, world_size.y - 42.0)
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
		bob = absf(sin(walk_time)) * 2.0
		sway = sin(walk_time) * 0.025
	character_sprite.position = Vector2(0, -6 - bob)
	character_sprite.rotation = sway
	character_sprite.scale = Vector2(1.05, 1.05)
	if action_flash > 0.0:
		character_sprite.scale = Vector2(1.10, 0.98)

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
	action_flash = 0.16
	action_requested.emit(position + facing.normalized() * 62.0)
	can_act = false
	await get_tree().create_timer(0.16).timeout
	can_act = true

func _draw() -> void:
	# soft contact shadow and action target marker
	_draw_shadow(Vector2(0, 28), Vector2(22, 7), Color(0,0,0,0.20))
	var marker_alpha := 0.66 if action_flash > 0.0 else 0.30
	draw_circle(facing.normalized()*37.0 + Vector2(0,5), 3.5, Color(1,1,1,marker_alpha))
	if action_flash > 0.0:
		var hand := facing.normalized() * 28.0 + Vector2(0,-4)
		draw_line(hand, hand + facing.normalized()*22.0, Color("#d9b66f"), 5.0)
		draw_circle(hand + facing.normalized()*23.0, 6.0, Color("#c3a263"))

func _draw_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var a := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)
