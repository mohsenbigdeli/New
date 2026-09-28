extends Node2D
class_name FarmSouthGroveV33

const MAP_SIZE := Vector2(2304, 2300)
const GROVE_TOP := 1450.0

const TREE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_tree.png")
const HOUSE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_house.png")
const NORA_TEX: Texture2D = preload("res://assets/art/v17/watercolor_lina.png")

var active := true
var collected: Dictionary = {}
var collision_bodies: Array[CollisionObject2D] = []

var forage_spots: Array[Dictionary] = [
	{"id":"berries", "name":"Wild berry thicket", "pos":Vector2(840, 1795)},
	{"id":"herbs", "name":"Forest herb patch", "pos":Vector2(1280, 1715)},
	{"id":"mushrooms", "name":"Mushroom ring", "pos":Vector2(1865, 1985)}
]

func _ready() -> void:
	z_index = -2
	_install_collisions()
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	for body in collision_bodies:
		if is_instance_valid(body):
			body.collision_layer = 1 if value else 0
			body.collision_mask = 1 if value else 0
	queue_redraw()

func set_collected_state(state: Dictionary) -> void:
	collected = state.duplicate(true)
	queue_redraw()

func get_interaction(pos: Vector2) -> Dictionary:
	if not active:
		return {}

	if pos.distance_to(Vector2(1082, 1578)) < 88.0:
		return {"type":"v33_grove_sign", "name":"Willow Grove sign"}
	if pos.distance_to(Vector2(625, 1698)) < 92.0:
		return {"type":"v33_nora", "name":"Nora · Grove Keeper"}
	if pos.distance_to(Vector2(505, 2110)) < 100.0:
		return {"type":"v33_ancient_tree", "name":"Ancient willow"}
	if pos.distance_to(Vector2(1695, 2150)) < 92.0:
		return {"type":"v33_campfire", "name":"Grove campfire"}

	for item in forage_spots:
		var id := String(item["id"])
		if collected.has(id):
			continue
		var p: Vector2 = item["pos"]
		if pos.distance_to(p) < 78.0:
			return {
				"type":"v33_forage",
				"id":id,
				"name":String(item["name"])
			}
	return {}

func _install_collisions() -> void:
	var trees: Array[Vector2] = [
		Vector2(170, 1595), Vector2(730, 1575), Vector2(1950, 1580),
		Vector2(250, 1880), Vector2(2040, 1845), Vector2(790, 2185),
		Vector2(1260, 2210), Vector2(1980, 2180), Vector2(315, 2205)
	]
	for i in range(trees.size()):
		_add_circle_obstacle("V33Tree%d" % i, trees[i], 28.0)

	# The grove spring and the continued east river are physical water.
	_add_circle_obstacle("V33SpringCore", Vector2(1495, 1920), 102.0)
	_add_rect_obstacle("V33EastRiverExtension", Vector2(2213, 1918), Vector2(182, 764))

	# The ranger cabin is scenery for now, but it should still feel solid.
	_add_rect_obstacle("V33GroveCabin", Vector2(390, 1668), Vector2(255, 125))

func _add_circle_obstacle(node_name: String, center: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	collision_bodies.append(body)

func _add_rect_obstacle(node_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	collision_bodies.append(body)

func _draw() -> void:
	if not active:
		return

	_draw_extended_ground()
	_draw_grove_paths()
	_draw_river_extension()
	_draw_grove_spring()
	_draw_cabin()
	_draw_trees()
	_draw_forage_spots()
	_draw_ancient_willow()
	_draw_campfire()
	_draw_nora()
	_draw_grove_sign()

func _draw_extended_ground() -> void:
	draw_rect(Rect2(0, GROVE_TOP, MAP_SIZE.x, MAP_SIZE.y - GROVE_TOP), Color("#79b95b"), true)

	# Broad translucent washes make the new area feel painted rather than tiled.
	var washes: Array[Dictionary] = [
		{"p":Vector2(330, 1690), "r":Vector2(310, 150), "c":Color(0.30,0.53,0.20,0.11)},
		{"p":Vector2(1020, 1840), "r":Vector2(390, 180), "c":Color(0.73,0.68,0.28,0.07)},
		{"p":Vector2(1760, 1715), "r":Vector2(340, 160), "c":Color(0.27,0.55,0.24,0.09)},
		{"p":Vector2(680, 2150), "r":Vector2(360, 135), "c":Color(0.36,0.62,0.25,0.09)}
	]
	for item in washes:
		_draw_ellipse(item["p"], item["r"], item["c"])

	for i in range(90):
		var x := 70.0 + fmod(float(i * 173 + (i % 9) * 41), 2020.0)
		var y := 1510.0 + fmod(float(i * 97 + (i % 7) * 37), 710.0)
		if x > 990.0 and x < 1165.0:
			continue
		if Vector2(x, y).distance_to(Vector2(1495, 1920)) < 170.0:
			continue
		if i % 5 == 0:
			_draw_wildflower(Vector2(x, y), i)
		else:
			_draw_grass(Vector2(x, y), i)

func _draw_grove_paths() -> void:
	var path := Color("#d7b775")
	var edge := Color(0.48,0.34,0.18,0.18)

	# Main south road continues directly from the old map.
	draw_rect(Rect2(1028, 1450, 94, 780), path, true)
	# West branch leads to Nora's cabin.
	draw_rect(Rect2(390, 1650, 690, 78), path, true)
	# East branch reaches the spring and forage loop.
	draw_rect(Rect2(1080, 1850, 770, 76), path, true)
	# Lower trail reaches the ancient willow and campfire.
	draw_rect(Rect2(500, 2100, 1220, 70), path, true)

	for y in range(1480, 2215, 62):
		_draw_ellipse(Vector2(1030, float(y)), Vector2(12, 26), edge)
		_draw_ellipse(Vector2(1120, float(y + 25)), Vector2(12, 25), edge)
	for x in range(420, 1780, 70):
		_draw_ellipse(Vector2(float(x), 1652), Vector2(28, 9), edge)
	for x in range(1120, 1840, 72):
		_draw_ellipse(Vector2(float(x), 1924), Vector2(30, 9), edge)

func _draw_river_extension() -> void:
	draw_rect(Rect2(2104, GROVE_TOP, 18, MAP_SIZE.y - GROVE_TOP), Color("#cbb17b"), true)
	draw_rect(Rect2(2122, GROVE_TOP, 182, MAP_SIZE.y - GROVE_TOP), Color("#4b9fba"), true)
	for i in range(16):
		var yy := 1490.0 + float(i) * 48.0
		draw_line(Vector2(2145, yy), Vector2(2200, yy + sin(float(i)) * 2.0), Color(0.9,0.98,0.96,0.26), 1.5)

func _draw_grove_spring() -> void:
	var c := Vector2(1495, 1920)
	_draw_ellipse(c + Vector2(0, 18), Vector2(150, 48), Color(0.05,0.09,0.05,0.14))
	draw_circle(c, 142, Color("#cbb17b"))
	draw_circle(c, 129, Color("#73a66b"))
	draw_circle(c, 118, Color("#4d9fbb"))
	for i in range(5):
		var p := c + Vector2(-65.0 + float(i) * 32.0, -15.0 + sin(float(i)) * 24.0)
		draw_line(p - Vector2(12,0), p + Vector2(12,0), Color(0.93,1.0,0.96,0.20), 1.5)
	draw_circle(c + Vector2(-50, 24), 13, Color("#70b35a"))
	draw_circle(c + Vector2(36, -33), 10, Color("#70b35a"))

func _draw_cabin() -> void:
	var r := Rect2(230, 1510, 320, 232)
	_draw_ellipse(Vector2(r.position.x + r.size.x * 0.5, r.end.y - 2), Vector2(118, 15), Color(0.05,0.08,0.04,0.14))
	draw_texture_rect(HOUSE_TEX, r, false, Color(0.88,0.95,0.78,1.0))
	draw_string(ThemeDB.fallback_font, Vector2(300, 1748), "GROVE CABIN", HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color("#5c452e"))

func _draw_trees() -> void:
	var rects: Array[Rect2] = [
		Rect2(88, 1395, 164, 214), Rect2(648, 1370, 166, 216), Rect2(1868, 1370, 166, 216),
		Rect2(165, 1660, 174, 226), Rect2(1950, 1630, 170, 221), Rect2(705, 1970, 176, 228),
		Rect2(1170, 1980, 182, 236), Rect2(1890, 1960, 180, 232), Rect2(225, 1985, 180, 234)
	]
	for i in range(rects.size()):
		var r: Rect2 = rects[i]
		var tint := Color.WHITE
		if i % 3 == 1:
			tint = Color(0.96,1.0,0.92,1.0)
		elif i % 3 == 2:
			tint = Color(1.0,0.96,0.89,1.0)
		_draw_ellipse(Vector2(r.position.x + r.size.x * 0.5, r.end.y - 6), Vector2(r.size.x * 0.30, 10), Color(0.05,0.08,0.04,0.13))
		draw_texture_rect(TREE_TEX, r, false, tint)

func _draw_forage_spots() -> void:
	for item in forage_spots:
		var id := String(item["id"])
		if collected.has(id):
			continue
		var p: Vector2 = item["pos"]
		match id:
			"berries":
				for j in range(5):
					var q := p + Vector2(float(j - 2) * 12.0, sin(float(j) * 1.7) * 8.0)
					draw_circle(q, 10, Color("#4d843d"))
					draw_circle(q + Vector2(3,-3), 3, Color("#b84f63"))
			"herbs":
				for j in range(6):
					var q := p + Vector2(float(j - 3) * 9.0, sin(float(j) * 1.4) * 7.0)
					draw_line(q, q + Vector2(2,-18), Color("#4e7f3d"), 3.0)
					draw_circle(q + Vector2(4,-17), 5, Color("#79a95f"))
			"mushrooms":
				for j in range(5):
					var a := TAU * float(j) / 5.0
					var q := p + Vector2(cos(a), sin(a)) * 18.0
					draw_line(q, q + Vector2(0,-9), Color("#e8d8bd"), 3.0)
					draw_circle(q + Vector2(0,-10), 7, Color("#b87355"))

func _draw_ancient_willow() -> void:
	var r := Rect2(390, 1840, 230, 300)
	_draw_ellipse(Vector2(505, 2126), Vector2(78, 17), Color(0.04,0.07,0.03,0.17))
	draw_texture_rect(TREE_TEX, r, false, Color(0.88,1.0,0.82,1.0))
	draw_circle(Vector2(505, 2110), 9, Color(0.96,0.88,0.47,0.45))

func _draw_campfire() -> void:
	var p := Vector2(1695, 2150)
	_draw_ellipse(p + Vector2(0,8), Vector2(34,10), Color(0.10,0.07,0.04,0.18))
	for a in [0.0, PI * 0.5]:
		var d := Vector2(cos(a), sin(a)) * 24.0
		draw_line(p - d, p + d, Color("#6e4d34"), 8.0)
	draw_circle(p + Vector2(0,-3), 13, Color("#ed8a43"))
	draw_circle(p + Vector2(0,-10), 8, Color("#ffd15f"))

func _draw_nora() -> void:
	var r := Rect2(575, 1610, 96, 132)
	_draw_ellipse(Vector2(623, 1733), Vector2(28, 7), Color(0.05,0.08,0.04,0.14))
	draw_texture_rect(NORA_TEX, r, false, Color(0.92,1.0,0.90,1.0))
	draw_string(ThemeDB.fallback_font, Vector2(576, 1751), "NORA", HORIZONTAL_ALIGNMENT_CENTER, 94, 11, Color("#4f3d2c"))

func _draw_grove_sign() -> void:
	var p := Vector2(1082, 1578)
	draw_line(p + Vector2(-32,24), p + Vector2(-32,64), Color("#6f5136"), 6.0)
	draw_line(p + Vector2(32,24), p + Vector2(32,64), Color("#6f5136"), 6.0)
	draw_rect(Rect2(p - Vector2(72,26), Vector2(144,52)), Color("#8e6845"), true)
	draw_rect(Rect2(p - Vector2(67,21), Vector2(134,42)), Color("#d7bd83"), true)
	draw_string(ThemeDB.fallback_font, p + Vector2(-61,6), "WILLOW GROVE", HORIZONTAL_ALIGNMENT_CENTER, 122, 12, Color("#4b3826"))

func _draw_wildflower(p: Vector2, seed: int) -> void:
	var stem := 8.0 + float(seed % 5)
	draw_line(p, p + Vector2(0,-stem), Color("#4d7d3f"), 2.0)
	var c := [Color("#f4d37a"), Color("#f2a6b5"), Color("#f7eee2"), Color("#c9a8dc")][seed % 4]
	draw_circle(p + Vector2(0,-stem), 4.0, c)

func _draw_grass(p: Vector2, seed: int) -> void:
	var h := 6.0 + float(seed % 7)
	var c := Color(0.19,0.43,0.16,0.35)
	draw_line(p, p + Vector2(-3,-h), c, 1.2)
	draw_line(p + Vector2(3,0), p + Vector2(5,-h*0.82), c, 1.2)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
