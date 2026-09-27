extends "res://scripts/main_v27.gd"

const PAINTED_WORLD_V28 := preload("res://scripts/farm_painted_world_v28.gd")
const FARMER_WALK_SHEET_V28: Texture2D = preload("res://assets/art/v23/farmer_walk_sheet.svg")

var painted_world_v28: Node2D
var v28_walk_sequence: Array[int] = [1, 0, 2, 0, 3, 0]

func _ready() -> void:
	super()
	_install_v28_painted_world()
	_install_v28_world_collisions()
	_apply_v28_farmer()
	ui.show_message("v2.8: watercolor trees restored, pond/river/tree collisions added, and the farmer now has a visible step cycle.")

func _set_room_state(room: String) -> void:
	super._set_room_state(room)
	if painted_world_v22:
		painted_world_v22.set_active(false)
	if painted_world_v28 and painted_world_v28.has_method("set_active"):
		painted_world_v28.set_active(room == "outside")

func _install_v28_painted_world() -> void:
	if painted_world_v22:
		painted_world_v22.set_active(false)
	if painted_world_v28:
		return
	painted_world_v28 = PAINTED_WORLD_V28.new()
	painted_world_v28.name = "PaintedWorldV28"
	add_child(painted_world_v28)
	painted_world_v28.setup(farm)
	painted_world_v28.set_active(interiors.active_room == "outside")

# Route every older appearance hook to the stronger authored v2.3 gait sheet.
# This prevents v2.4 from re-installing its almost-static runtime PNG every frame.
func _apply_v18_farmer() -> void:
	_apply_v28_farmer()

func _apply_v19_farmer() -> void:
	_apply_v28_farmer()

func _apply_v22_farmer() -> void:
	_apply_v28_farmer()

func _apply_v23_farmer() -> void:
	_apply_v28_farmer()

func _apply_v24_farmer() -> void:
	_apply_v28_farmer()

func _apply_v24_walk_timing() -> void:
	_apply_v28_walk_timing()

func _apply_v28_farmer() -> void:
	if not player:
		return
	if player.custom_character_sheet != FARMER_WALK_SHEET_V28:
		player.set_custom_character_sheet(FARMER_WALK_SHEET_V28, 4, 4, Vector2(0.82, 0.82))
	if player.character_sprite:
		player.character_sprite.modulate = Color.WHITE
		player.character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _apply_v28_walk_timing() -> void:
	if not player or not player.character_sprite:
		return
	_apply_v28_farmer()
	var row := 0
	if absf(player.facing.x) > absf(player.facing.y):
		row = 1 if player.facing.x > 0.0 else 2
	else:
		row = 0 if player.facing.y >= 0.0 else 3

	if not player.is_walking:
		player.character_sprite.frame_coords = Vector2i(0, row)
		player.character_sprite.position = Vector2(0, -20)
		return

	# The older sequence was too subtle on a phone. Use the real extended-leg
	# poses with a clear neutral contact frame between each stride.
	var phase := int(floor(player.walk_time * 0.92)) % v28_walk_sequence.size()
	player.character_sprite.frame_coords = Vector2i(v28_walk_sequence[phase], row)
	player.character_sprite.position = Vector2(0, -21 if phase % 2 == 0 else -20)

func _install_v28_world_collisions() -> void:
	if not farm or farm.has_node("V28PondCore"):
		return

	# Pond water: several overlapping circles follow the watercolor shoreline
	# while leaving the southwest dock approach open for fishing.
	_add_v28_circle_obstacle("V28PondCore", Vector2(1418, 600), 108.0)
	_add_v28_circle_obstacle("V28PondNorthWest", Vector2(1348, 535), 70.0)
	_add_v28_circle_obstacle("V28PondNorthEast", Vector2(1490, 540), 72.0)
	_add_v28_circle_obstacle("V28PondSouthEast", Vector2(1490, 676), 66.0)

	# The painted east river is now solid instead of being only a visual strip.
	_add_v28_rect_obstacle("V28EastRiver", Vector2(2213, 768), Vector2(182, 1536))

	# Important world props should feel physical. Buildings already have their
	# own colliders in FarmWorld, so add trunks and the shipping bin here.
	var trunks: Array[Vector2] = [
		Vector2(719, 269), Vector2(896, 331), Vector2(1954, 589),
		Vector2(2041, 748), Vector2(787, 1338), Vector2(1500, 1370),
		Vector2(1924, 1397), Vector2(175, 1376)
	]
	for i in range(trunks.size()):
		_add_v28_circle_obstacle("V28TreeTrunk%d" % i, trunks[i], 25.0)
	_add_v28_rect_obstacle("V28ShippingBin", Vector2(1080, 680), Vector2(66, 54))

func _add_v28_circle_obstacle(node_name: String, center: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	body.add_child(collision)
	farm.add_child(body)

func _add_v28_rect_obstacle(node_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	farm.add_child(body)
