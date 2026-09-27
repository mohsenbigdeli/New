extends "res://scripts/main_v23.gd"

var farmer_walk_texture_v24: Texture2D
var v24_walk_sequence: Array[int] = [1, 0, 2, 0, 3, 0]

func _ready() -> void:
	super()
	_apply_v24_farmer()
	ui.show_message("v2.4 Watercolor Walk: real painted 4-direction frames with a softer foot-planted walk cycle.")

func _process(delta: float) -> void:
	super(delta)
	_apply_v24_farmer()
	_apply_v24_walk_timing()

func _apply_v18_farmer() -> void:
	_apply_v24_farmer()

func _apply_v19_farmer() -> void:
	_apply_v24_farmer()

func _apply_v22_farmer() -> void:
	_apply_v24_farmer()

func _apply_v23_farmer() -> void:
	_apply_v24_farmer()

func _load_v24_farmer_texture() -> Texture2D:
	if farmer_walk_texture_v24:
		return farmer_walk_texture_v24
	var encoded: String = FileAccess.get_file_as_string("res://assets/art/v24/farmer_walk_sheet.b64").strip_edges()
	if encoded.is_empty():
		push_error("v2.4 farmer walk data is missing")
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	var image := Image.new()
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		push_error("v2.4 farmer PNG decode failed: %s" % err)
		return null
	farmer_walk_texture_v24 = ImageTexture.create_from_image(image)
	return farmer_walk_texture_v24

func _apply_v24_farmer() -> void:
	if not player:
		return
	var tex := _load_v24_farmer_texture()
	if not tex:
		return
	# 192x144 sheet = 4 columns x 4 rows. The authored watercolor poses have
	# transparent margins, so a 3x display scale keeps the farmer readable while
	# planting the feet close to the gameplay shadow.
	player.set_custom_character_sheet(tex, 4, 4, Vector2(3.0, 3.0))
	if player.character_sprite:
		player.character_sprite.modulate = Color.WHITE
		player.character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _apply_v24_walk_timing() -> void:
	if not player or not player.character_sprite or not player.custom_character_sheet:
		return
	var row: int = player.character_sprite.frame_coords.y
	if not player.is_walking:
		player.character_sprite.frame_coords = Vector2i(0, row)
		return
	# Use the neutral pose between extended strides. This removes the mechanical
	# 1-2-3 loop and gives each foot a visible plant/contact phase.
	var phase: int = int(floor(player.walk_time * 0.78)) % v24_walk_sequence.size()
	player.character_sprite.frame_coords = Vector2i(v24_walk_sequence[phase], row)
