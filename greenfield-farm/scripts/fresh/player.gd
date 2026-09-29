extends CharacterBody2D
class_name FreshPlayer

signal interaction_result(data: Dictionary)

const WALK_B64_PATH := "res://assets/art/v24/farmer_walk_sheet.b64"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector: Area2D = $InteractionDetector

var touch_move := Vector2.ZERO
var facing := Vector2.DOWN
var speed := 185.0
var _walk_texture: Texture2D

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

func _load_watercolor_sheet() -> Texture2D:
	if _walk_texture:
		return _walk_texture
	var encoded: String = FileAccess.get_file_as_string(WALK_B64_PATH).strip_edges()
	if encoded.is_empty():
		push_error("Fresh watercolor farmer data is missing")
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	var image := Image.new()
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		push_error("Fresh watercolor farmer PNG decode failed: %s" % err)
		return null
	_walk_texture = ImageTexture.create_from_image(image)
	return _walk_texture

func _build_sprite_frames() -> void:
	var sheet := _load_watercolor_sheet()
	if not sheet:
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var names: Array[String] = ["down", "right", "left", "up"]
	for row in range(4):
		var idle_name: String = "idle_" + names[row]
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, true)
		frames.set_animation_speed(idle_name, 1.0)
		frames.add_frame(idle_name, _atlas_frame(sheet, 0, row))

		var walk_name: String = "walk_" + names[row]
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, 7.0)
		for col in [1, 0, 2, 0, 3, 0]:
			frames.add_frame(walk_name, _atlas_frame(sheet, col, row))
	sprite.sprite_frames = frames

func _atlas_frame(sheet: Texture2D, col: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(col * 48, row * 36, 48, 36)
	return frame
