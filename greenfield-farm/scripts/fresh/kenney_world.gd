extends Node2D

const FARM := preload("res://assets/pro/kenney/tiny_farm.png")
const TOWN := preload("res://assets/pro/kenney/tiny_town.png")

const SRC := 16.0
const STEP := 48.0
const MAP_W := 40
const MAP_H := 22

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Match the pond and paddock visuals with real, solid boundaries.
	_add_obstacle(Vector2(1180,270), Vector2(360,156))
	_add_obstacle(Vector2(1392,984), Vector2(264,24))
	_add_obstacle(Vector2(1680,984), Vector2(168,24))
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

	_dirt_rect(0, 9, MAP_W, 2)
	_dirt_rect(7, 4, 3, 8)
	_dirt_rect(18, 9, 3, 8)
	_dirt_rect(31, 7, 3, 5)

	draw_texture_rect_region(TOWN,Rect2(240,96,144,192),Rect2(0,64,48,64))
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
		var foot := Vector2(p) * STEP + Vector2(24,24)
		draw_set_transform(foot + Vector2(0,16), 0, Vector2(1,0.3))
		draw_circle(Vector2.ZERO, 25, Color(0.08,0.2,0.12,0.15))
		draw_set_transform(Vector2.ZERO)
		var column := 4 if rng.randf() > 0.4 else 5
		draw_texture_rect_region(TOWN,Rect2(foot-Vector2(24,68),Vector2(48,96)),Rect2(column*16,0,16,32))
	# Flower borders and small clumps use whole sprites, not fragments of trees.
	for i in range(30):
		var pos := Vector2(130+i*22,615+sin(i*2.4)*8)
		draw_texture_rect_region(TOWN,Rect2(pos,Vector2(24,24)),Rect2(32,0,16,16))
	for i in range(18):
		var pos := Vector2(800+sin(i*1.3)*24,190+i*13)
		draw_texture_rect_region(FARM,Rect2(pos,Vector2(26,26)),Rect2(96,48,16,16))
	# Stepped pixel shoreline, quiet blue water and lily pads.
	draw_rect(Rect2(974,174,412,190),Color("6b965c"))
	draw_rect(Rect2(990,186,380,168),Color("5f9e9b"))
	draw_rect(Rect2(1002,198,356,144),Color("75b4ad"))
	for i in range(9):
		var pos := Vector2(1018+i*37,225+sin(i*1.7)*58)
		draw_rect(Rect2(pos,Vector2(18,3)),Color("b1d5bd"))
	for pos in [Vector2(1040,265),Vector2(1240,220),Vector2(1290,310)]:
		draw_rect(Rect2(pos,Vector2(22,12)),Color("477b60"))
		draw_rect(Rect2(pos+Vector2(7,-4),Vector2(8,7)),Color("f1c0ae"))

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
		_tile(TOWN, top_col, 3, x, fy)
		if x != 31 and x != 32:
			var bottom_col := 8 if x == fx else (10 if x == fx + fw - 1 else 9)
			_tile(TOWN, bottom_col, 5, x, fy + fh - 1)
	for y in range(fy + 1, fy + fh - 1):
		_tile(TOWN, 8, 4, fx, y)
		_tile(TOWN, 10, 4, fx + fw - 1, y)
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

func _add_obstacle(center: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
