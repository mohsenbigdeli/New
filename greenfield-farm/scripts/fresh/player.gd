extends CharacterBody2D
class_name FreshPlayer

signal interaction_result(data: Dictionary)
const SHEET = preload("res://assets/pro/greenfield/farmer_directions.png")
const FRAME_DATA = preload("res://assets/pro/greenfield/farmer_frames.json")
const WALK_FRAMES = [1, 2, 3, 2]
@onready var sprite: Sprite2D = $Sprite2D
@onready var detector: Area2D = $InteractionDetector
var touch_move := Vector2.ZERO
var facing := Vector2.DOWN
var speed := 172.0
var walk_clock := 0.0
var action_time := 0.0
var action_kind := ""
var row := 0
var locked := false
var reduced_motion := false
var frames: Array = []
var cell := Vector2(313, 313)

func _ready() -> void:
	sprite.texture = SHEET
	frames = FRAME_DATA.data.frames
	cell = Vector2(FRAME_DATA.data.cell[0], FRAME_DATA.data.cell[1])
	_set_frame(0)
	$Camera2D.position_smoothing_enabled = true
	$Camera2D.position_smoothing_speed = 9.0

func _physics_process(delta: float) -> void:
	action_time = maxf(0, action_time - delta)
	var keyboard := Vector2(float(int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))), float(int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))))
	var move := (keyboard if keyboard.length() > 0.05 else touch_move).limit_length(1.0)
	if move.length() < 0.14 or locked or action_time > 0.1:
		move = Vector2.ZERO
	if move.length() > 0.0:
		facing = move.normalized()
		if absf(facing.x) > absf(facing.y):
			row = 1 if facing.x > 0 else 3
		else:
			row = 0 if facing.y >= 0 else 2
	velocity = velocity.move_toward(move * speed, (950.0 if move != Vector2.ZERO else 1500.0) * delta)
	var before := global_position
	move_and_slide()
	var travelled := global_position.distance_to(before)
	if travelled > 0.02:
		walk_clock = fmod(walk_clock + travelled / 15.0, 4.0)
		_set_frame(WALK_FRAMES[int(walk_clock)])
	else:
		walk_clock = 0.0
		_set_frame(0)
	queue_redraw()

func _set_frame(column: int) -> void:
	var bounds: Array = frames[row * 4 + column]
	var extent := Vector2(bounds[2] - bounds[0], bounds[3] - bounds[1])
	sprite.region_rect = Rect2(Vector2(column, row) * cell + Vector2(bounds[0], bounds[1]), extent)
	sprite.scale = Vector2(0.24, 0.24)
	sprite.position = Vector2(0, 16 - extent.y * 0.12)
	sprite.flip_h = false

func set_touch_move(value: Vector2) -> void:
	touch_move = value.limit_length(1.0) if not locked else Vector2.ZERO

func find_target() -> Area2D:
	var best: Area2D
	var score := INF
	for area in detector.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		var offset := area.global_position - global_position
		var candidate := offset.length() - facing.dot(offset.normalized()) * 24.0
		if candidate < score:
			best = area
			score = candidate
	return best

func interact() -> void:
	if locked or action_time > 0:
		return
	var target := find_target()
	if target == null:
		interaction_result.emit({"message":"Move closer to a garden bed or Marnie."})
		return
	var result: Dictionary = target.interact()
	action_time = 0.32
	action_kind = String(result.get("effect", "talk"))
	result["position"] = target.global_position
	interaction_result.emit(result)

func _draw() -> void:
	if action_time <= 0 or action_kind == "talk" or reduced_motion:
		return
	var hand := facing * 14.0 + Vector2(0, -6)
	var phase := (0.32 - action_time) / 0.32
	var reach := hand + facing * (12 + sin(phase * PI) * 14)
	if action_kind == "water":
		draw_rect(Rect2(hand - Vector2(5, 4), Vector2(13, 10)), Color("8bbbc2"))
		draw_line(hand, reach, Color("c7eeee"), 3)
	else:
		draw_line(hand, reach, Color("8f6648"), 4)
		draw_line(reach - Vector2(6, 0), reach + Vector2(6, 0), Color("d7dbc9"), 4)
