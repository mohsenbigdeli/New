extends Node2D

const FARM := preload("res://assets/pro/kenney/tiny_farm.png")
const TOWN := preload("res://assets/pro/kenney/tiny_town.png")

const SRC := 16.0
const STEP := 48.0
const MAP_W := 40
const MAP_H := 22

func _ready() -> void:
	queue_redraw()
	call_deferred("_spawn_props")

func _atlas(texture: Texture2D, col: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * SRC, row * SRC, SRC, SRC)
	return atlas

func _tile(texture: Texture2D, col: int, row: int, x: int, y: int) -> void:
	draw_texture_rect_region(
		texture,
		Rect2(Vector2(x * STEP, y * STEP), Vector2(STEP, STEP)),
		Rect2(Vector2(col * SRC, row * SRC), Vector2(SRC, SRC))
	)

func _dirt_rect(x0: int, y0: int, width: int, height: int) -> void:
	for y in range(y0, y0 + height):
		for x in range(x0, x0 + width):
			var col := 0 if x == x0 else (2 if x == x0 + width - 1 else 1)
			var row_offset := 0 if y == y0 else (2 if y == y0 + height - 1 else 1)
			_tile(TOWN, col, 1 + row_offset, x, y)

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 97

	# Cohesive Kenney grass base with restrained variation.
	for y in range(MAP_H):
		for x in range(MAP_W):
			var col := 1 if rng.randi_range(0, 7) == 0 else 0
			_tile(TOWN, col, 0, x, y)
			if rng.randf() < 0.025:
				_tile(TOWN, 2, 0, x, y)

	# Village road and readable branches to each gameplay landmark.
	_dirt_rect(0, 8, MAP_W, 3)
	_dirt_rect(6, 4, 3, 7)
	_dirt_rect(18, 8, 3, 6)
	_dirt_rect(28, 6, 3, 5)

	# Working field: large enough to feel like a farm, compact enough for mobile.
	_dirt_rect(3, 12, 13, 8)

	# Small ranch / animal corner.
	_dirt_rect(26, 13, 11, 7)

func _spawn_props() -> void:
	var world := get_parent()
	if world == null:
		return

	# Farmhouse/barn and market tent are multi-tile objects sorted at their feet.
	_add_building(world, FARM, 6, 7, 3, 3, 5, 2, "Farmhouse")
	_add_building(world, FARM, 9, 6, 3, 5, 28, 1, "MarketTent")

	# Landmark props tied to gameplay interactions.
	_add_prop(world, FARM, 1, 6, 19, 6, "Well", 0, true)
	_add_prop(world, FARM, 4, 6, 14, 12, "ShippingBin", 0, true)
	_add_prop(world, FARM, 2, 8, 25, 7, "Bench", 0, true)
	_add_prop(world, FARM, 3, 10, 27, 14, "FeedTub", 0, true)
	_add_prop(world, FARM, 4, 10, 35, 18, "HayBale", 0, true)

	# Animals make the lower-right area feel inhabited.
	_add_prop(world, FARM, 0, 10, 29, 15, "SheepA", 0, true)
	_add_prop(world, FARM, 1, 10, 33, 16, "SheepB", 0, true)
	_add_prop(world, FARM, 2, 10, 35, 14, "ChickenA", 0, true)
	_add_prop(world, FARM, 2, 10, 31, 18, "ChickenB", 0, true)

	# Trees frame the map instead of being random clutter in the walkable core.
	var tree_spots := [
		Vector2i(1, 1), Vector2i(2, 2), Vector2i(10, 1), Vector2i(12, 2),
		Vector2i(18, 1), Vector2i(21, 2), Vector2i(24, 1), Vector2i(37, 1),
		Vector2i(38, 3), Vector2i(1, 6), Vector2i(38, 7), Vector2i(1, 15),
		Vector2i(38, 15), Vector2i(2, 20), Vector2i(18, 20), Vector2i(22, 20),
		Vector2i(36, 20), Vector2i(39, 19)
	]
	for i in range(tree_spots.size()):
		var p: Vector2i = tree_spots[i]
		var row := i % 4
		_add_prop(world, FARM, 3, row, p.x, p.y, "Tree_%02d" % i, 0, true)

	# Flower, crop and shrub accents around routes and buildings.
	var decor := [
		Vector4i(4, 0, 12, 4), Vector4i(5, 0, 13, 4), Vector4i(6, 0, 22, 5),
		Vector4i(4, 1, 23, 5), Vector4i(5, 1, 26, 4), Vector4i(6, 1, 34, 5),
		Vector4i(4, 2, 11, 6), Vector4i(5, 2, 23, 18), Vector4i(6, 2, 16, 19),
		Vector4i(4, 3, 2, 12), Vector4i(5, 3, 17, 12), Vector4i(6, 3, 37, 12),
		Vector4i(4, 5, 25, 12), Vector4i(5, 5, 24, 12), Vector4i(8, 5, 36, 12)
	]
	for i in range(decor.size()):
		var d: Vector4i = decor[i]
		_add_prop(world, FARM, d.x, d.y, d.z, d.w, "Decor_%02d" % i, -2, false)

func _add_prop(world: Node, texture: Texture2D, col: int, row: int, gx: int, gy: int, prop_name: String, z: int = 0, shadowed: bool = false) -> void:
	var holder := Node2D.new()
	holder.name = prop_name
	holder.position = Vector2((gx + 0.5) * STEP, (gy + 1.0) * STEP)
	holder.z_index = z

	if shadowed:
		var shadow := Polygon2D.new()
		shadow.polygon = PackedVector2Array([-18, -4, 18, -4, 23, 0, 18, 4, -18, 4, -23, 0])
		shadow.color = Color(0.08, 0.07, 0.09, 0.24)
		shadow.z_index = -1
		holder.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.texture = _atlas(texture, col, row)
	sprite.scale = Vector2(3, 3)
	sprite.position = Vector2(0, -STEP * 0.5)
	holder.add_child(sprite)
	world.add_child(holder)

func _add_building(world: Node, texture: Texture2D, atlas_x: int, atlas_y: int, cols: int, rows: int, gx: int, gy: int, building_name: String) -> void:
	var holder := Node2D.new()
	holder.name = building_name
	holder.position = Vector2((gx + cols * 0.5) * STEP, (gy + rows) * STEP)

	var half_w := cols * STEP * 0.46
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([-half_w, -10, half_w, -10, half_w + 12, 0, half_w, 8, -half_w, 8, -half_w - 12, 0])
	shadow.color = Color(0.07, 0.06, 0.08, 0.30)
	shadow.z_index = -1
	holder.add_child(shadow)

	for ry in range(rows):
		for rx in range(cols):
			var sprite := Sprite2D.new()
			sprite.texture = _atlas(texture, atlas_x + rx, atlas_y + ry)
			sprite.scale = Vector2(3, 3)
			sprite.position = Vector2((rx - cols * 0.5 + 0.5) * STEP, (ry - rows + 0.5) * STEP)
			holder.add_child(sprite)
	world.add_child(holder)
