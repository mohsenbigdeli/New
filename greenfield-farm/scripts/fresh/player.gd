extends CharacterBody2D
class_name FreshPlayer

signal interaction_result(data: Dictionary)

@onready var sprite: Sprite2D = $Sprite2D
@onready var detector: Area2D = $InteractionDetector

var touch_move := Vector2.ZERO
var facing := Vector2.DOWN
var speed := 155.0
var walk_clock := 0.0

const FRAME_SIZE := Vector2(48, 48)
const SPRITE_HOME := Vector2(0, -5)
const INTERACT_DISTANCE := 38.0

func _ready() -> void:
	sprite.region_rect = Rect2(Vector2.ZERO, FRAME_SIZE)
	_update_detector()

func _physics_process(delta: float) -> void:
	var keyboard := Vector2(
		float(int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))),
		float(int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	)
	var move := keyboard if keyboard.length() > 0.05 else touch_move
	if move.length() > 1.0:
		move = move.normalized()

	velocity = move * speed
	if move.length() > 0.05:
		facing = move.normalized()
	move_and_slide()
	global_position = global_position.round()
	_update_detector()
	_update_animation(move, delta)

func set_touch_move(value: Vector2) -> void:
	touch_move = value.limit_length(1.0)

func interact() -> void:
	var best: Area2D
	var best_score := INF
	for area in detector.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		var to_area := area.global_position - global_position
		if to_area.length() > 0.01 and facing.dot(to_area.normalized()) < 0.05:
			continue
		var score := detector.global_position.distance_to(area.global_position)
		if score < best_score:
			best = area
			best_score = score
	if best == null:
		interaction_result.emit({"message":"Nothing useful is in front of you."})
		return
	var result = best.interact()
	if result is Dictionary:
		interaction_result.emit(result)

func _update_detector() -> void:
	var dir := facing
	if absf(dir.x) > absf(dir.y):
		dir = Vector2(signf(dir.x), 0)
	else:
		dir = Vector2(0, signf(dir.y))
	detector.position = dir * INTERACT_DISTANCE + Vector2(0, 4)

func _update_animation(move: Vector2, delta: float) -> void:
	if absf(facing.x) > 0.20:
		sprite.flip_h = facing.x < 0.0
	if move.length() > 0.05:
		walk_clock += delta
		var frame := int(floor(walk_clock * 8.0)) % 2
		sprite.region_rect = Rect2(Vector2(frame * 48, 0), FRAME_SIZE)
		var bob := sin(walk_clock * 16.0) * 1.5
		sprite.position = SPRITE_HOME + Vector2(0, bob)
	else:
		walk_clock = 0.0
		sprite.region_rect = Rect2(Vector2.ZERO, FRAME_SIZE)
		sprite.position = sprite.position.lerp(SPRITE_HOME, 0.35)
