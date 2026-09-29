extends Node2D

const FARM := preload("res://assets/pro/kenney/tiny_farm.png")
const TOWN := preload("res://assets/pro/kenney/tiny_town.png")

const SRC := 16.0
const STEP := 48.0
const MAP_W := 40
const MAP_H := 22

func _ready() -> void:
	queue_redraw()

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
	rng.seed = 42

	for y in range(MAP_H):
		for x in range(MAP_W):
			var col := 1 if rng.randi_range(0, 5) == 0 else 0
			_tile(TOWN, col, 0, x, y)
			if rng.randf() < 0.035:
				_tile(TOWN, 2, 0, x, y)

	_dirt_rect(0, 9, MAP_W, 3)
	_dirt_rect(7, 4, 3, 8)
	_dirt_rect(18, 9, 3, 8)
	_dirt_rect(31, 7, 3, 5)

	for yy in range(3):
		for xx in range(3):
			_tile(FARM, 6 + xx, 7 + yy, 5 + xx, 2 + yy)
	_tile(TOWN, 1, 3, 6, 5)

	_tile(TOWN, 8, 8, 14, 7)
	_tile(TOWN, 11, 7, 16, 7)

	var tree_tiles := [Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(3, 2), Vector2i(4, 2)]
	var tree_spots := [
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(10, 1), Vector2i(11, 2),
		Vector2i(14, 1), Vector2i(20, 1), Vector2i(22, 2), Vector2i(25, 1),
		Vector2i(28, 2), Vector2i(36, 1), Vector2i(38, 2), Vector2i(1, 6),
		Vector2i(38, 6), Vector2i(1, 15), Vector2i(38, 15), Vector2i(2, 20),
		Vector2i(36, 20), Vector2i(39, 19), Vector2i(22, 20)
	]
	for p in tree_spots:
		var t: Vector2i = tree_tiles[rng.randi_range(0, tree_tiles.size() - 1)]
		_tile(TOWN, t.x, t.y, p.x, p.y)

	for p in [
		Vector2i(12, 4), Vector2i(13, 4), Vector2i(22, 5), Vector2i(23, 5),
		Vector2i(27, 4), Vector2i(29, 6), Vector2i(35, 5), Vector2i(4, 7),
		Vector2i(11, 6), Vector2i(37, 13), Vector2i(2, 13), Vector2i(23, 18),
		Vector2i(15, 19)
	]:
		_tile(TOWN, 6, 0, p.x, p.y)
	for p in [Vector2i(12, 5), Vector2i(28, 5), Vector2i(37, 7), Vector2i(2, 16)]:
		_tile(TOWN, 6, 2, p.x, p.y)

	_dirt_rect(3, 13, 12, 7)
	for spec in [
		Vector4i(2, 13, 2, 6), Vector4i(15, 13, 3, 6), Vector4i(2, 18, 1, 7),
		Vector4i(15, 18, 1, 8), Vector4i(4, 20, 0, 8), Vector4i(6, 20, 1, 8),
		Vector4i(12, 20, 2, 8)
	]:
		_tile(FARM, spec.z, spec.w, spec.x, spec.y)

	var fx := 26
	var fy := 13
	var fw := 11
	var fh := 8
	for x in range(fx, fx + fw):
		var top_col := 8 if x == fx else (10 if x == fx + fw - 1 else 9)
		_tile(TOWN, top_col, 4, x, fy)
		if x != 31 and x != 32:
			var bottom_col := 8 if x == fx else (10 if x == fx + fw - 1 else 9)
			_tile(TOWN, bottom_col, 6, x, fy + fh - 1)
	for y in range(fy + 1, fy + fh - 1):
		_tile(TOWN, 8, 5, fx, y)
		_tile(TOWN, 10, 5, fx + fw - 1, y)
	for p in [Vector2i(28, 15), Vector2i(34, 14), Vector2i(35, 18), Vector2i(29, 19)]:
		_tile(TOWN, 1, 0, p.x, p.y)
	_tile(FARM, 0, 10, 29, 16)
	_tile(FARM, 2, 10, 33, 17)
	_tile(FARM, 2, 10, 35, 15)
	_tile(FARM, 1, 10, 31, 18)
	_tile(FARM, 0, 8, 27, 14)
	_tile(FARM, 3, 8, 34, 19)
	_tile(FARM, 3, 9, 28, 19)

	for spec in [
		Vector4i(4, 6, 2, 7), Vector4i(10, 5, 3, 7), Vector4i(11, 5, 4, 7),
		Vector4i(12, 6, 5, 7), Vector4i(3, 7, 1, 6),
		Vector4i(21, 8, 9, 0), Vector4i(23, 8, 10, 1), Vector4i(35, 8, 11, 2),
		Vector4i(17, 12, 9, 3)
	]:
		_tile(FARM, spec.z, spec.w, spec.x, spec.y)
	_tile(FARM, 1, 6, 24, 7)
	_tile(FARM, 0, 6, 25, 7)
