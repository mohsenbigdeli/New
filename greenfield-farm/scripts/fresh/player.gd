extends CharacterBody2D
class_name FreshPlayer

signal interaction_result(data: Dictionary)

@onready var sprite: Sprite2D = $Sprite2D
@onready var detector: Area2D = $InteractionDetector

var touch_move := Vector2.ZERO
var facing := Vector2.DOWN
var speed := 185.0
var walk_phase := 0.0
const SPRITE_REST := Vector2(0, -34)

func _ready() -> void:
	sprite.position = SPRITE_REST

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
	_update_visual(move, delta)

func set_touch_move(value: Vector2) -> void:
	touch_move = value.limit_length(1.0)

func interact() -> void:
	var best: Area2D
	var best_distance := INF
	for area in detector.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		var d := global_position.distance_to(area.global_position)
		if d < best_distance:
			best = area
			best_distance = d
	if best == null:
		interaction_result.emit({"message":"Nothing nearby needs attention."})
		return
	var result = best.interact()
	if result is Dictionary:
		interaction_result.emit(result)

func _update_visual(move: Vector2, delta: float) -> void:
	if absf(facing.x) > 0.18:
		sprite.flip_h = facing.x < 0.0
	if move.length() > 0.05:
		walk_phase += delta * 10.0
		sprite.position = SPRITE_REST + Vector2(0, sin(walk_phase) * 2.4)
		sprite.rotation = sin(walk_phase * 0.5) * 0.018
	else:
		walk_phase = 0.0
		var weight := minf(1.0, delta * 12.0)
		sprite.position = sprite.position.lerp(SPRITE_REST, weight)
		sprite.rotation = lerpf(sprite.rotation, 0.0, weight)
