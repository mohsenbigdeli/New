extends CharacterBody2D
class_name FreshPlayer

signal interaction_result(data: Dictionary)

const WALK_SHEET: Texture2D = preload("res://assets/art/v31/farmer_walk_sheet.svg")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector: Area2D = $InteractionDetector

var touch_move := Vector2.ZERO
var facing := Vector2.DOWN
var speed := 205.0

func _ready() -> void:
	_build_sprite_frames()
	sprite.play("idle_down")

func _physics_process(_delta: float) -> void:
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
	_update_animation(move)

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
		interaction_result.emit({"message":"Nothing close enough to use."})
		return
	var result = best.interact()
	if result is Dictionary:
		interaction_result.emit(result)

func _update_animation(move: Vector2) -> void:
	var direction: String = _direction_name(facing)
	var wanted: String = ("walk_" if move.length() > 0.05 else "idle_") + direction
	if sprite.animation != wanted:
		sprite.play(wanted)

func _direction_name(dir: Vector2) -> String:
	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x > 0.0 else "left"
	return "down" if dir.y >= 0.0 else "up"

func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var names: Array[String] = ["down", "right", "left", "up"]
	for row in range(4):
		var idle_name: String = "idle_" + names[row]
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, true)
		frames.set_animation_speed(idle_name, 1.0)
		frames.add_frame(idle_name, _atlas_frame(0, row))

		var walk_name: String = "walk_" + names[row]
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, 7.5)
		for col in range(4):
			frames.add_frame(walk_name, _atlas_frame(col, row))
	sprite.sprite_frames = frames

func _atlas_frame(col: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = WALK_SHEET
	frame.region = Rect2(col * 96, row * 128, 96, 128)
	return frame
