extends Node2D
class_name FarmExpansionV40

const MAP_SIZE := Vector2(3000, 3300)
const EXPANSION_TOP := 2260.0

const TREE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_tree.png")
const HOUSE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_house.png")
const OREN_TEX: Texture2D = preload("res://assets/art/v17/watercolor_rowan.png")
const MIRA_TEX: Texture2D = preload("res://assets/art/v17/watercolor_lina.png")
const THEO_TEX: Texture2D = preload("res://assets/art/v17/watercolor_marnie.png")

var active := true
var collision_bodies: Array[CollisionObject2D] = []
var debris_collected: Dictionary = {}
var relic_collected: Dictionary = {}
var chests_opened: Dictionary = {}
var daily_collected: Dictionary = {}

var debris_spots: Array[Dictionary] = [
	{"id":"driftwood_1","name":"Driftwood pile","pos":Vector2(330, 2760)},
	{"id":"driftwood_2","name":"Washed-up crate","pos":Vector2(720, 2920)},
	{"id":"driftwood_3","name":"Tangled rope","pos":Vector2(1085, 3045)},
	{"id":"driftwood_4","name":"Broken basket","pos":Vector2(470, 3150)},
	{"id":"driftwood_5","name":"Old fishing net","pos":Vector2(1320, 2810)}
]

var relic_spots: Array[Dictionary] = [
	{"id":"relic_1","name":"Carved stone fragment","pos":Vector2(1895, 2625)},
	{"id":"relic_2","name":"Copper rune shard","pos":Vector2(2540, 2675)},
	{"id":"relic_3","name":"Mossy tablet piece","pos":Vector2(2085, 3075)},
	{"id":"relic_4","name":"Moon-marked relic","pos":Vector2(2760, 2980)}
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
	queue_redraw()

func set_state(debris: Dictionary, relics: Dictionary, chests: Dictionary, daily: Dictionary) -> void:
	debris_collected = debris.duplicate(true)
	relic_collected = relics.duplicate(true)
	chests_opened = chests.duplicate(true)
	daily_collected = daily.duplicate(true)
	queue_redraw()

func get_interaction(pos: Vector2) -> Dictionary:
	if not active:
		return {}

	if pos.distance_to(Vector2(1090, 2350)) < 90.0:
		return {"type":"v40_sign", "name":"South Trail map"}
	if pos.distance_to(Vector2(1090, 2425)) < 92.0:
		return {"type":"v40_cart_grove", "name":"Trail Cart · Sunset Coast"}
	if pos.distance_to(Vector2(585, 3130)) < 92.0:
		return {"type":"v40_cart_coast", "name":"Trail Cart · Willow Grove"}
	if pos.distance_to(Vector2(2650, 3130)) < 92.0:
		return {"type":"v40_cart_ridge", "name":"Trail Cart · Willow Grove"}

	if pos.distance_to(Vector2(1435, 2440)) < 96.0:
		return {"type":"v40_theo", "name":"Theo's seed bundle · 140g"}
	if pos.distance_to(Vector2(535, 2705)) < 95.0:
		return {"type":"v40_oren", "name":"Oren · Coast Keeper"}
	if pos.distance_to(Vector2(2360, 2705)) < 95.0:
		return {"type":"v40_mira", "name":"Mira · Ruins Explorer"}

	for item in debris_spots:
		var id := String(item["id"])
		if debris_collected.has(id):
			continue
		if pos.distance_to(item["pos"]) < 76.0:
			return {"type":"v40_debris", "id":id, "name":String(item["name"])}

	for item in relic_spots:
		var id := String(item["id"])
		if relic_collected.has(id):
			continue
		if pos.distance_to(item["pos"]) < 76.0:
			return {"type":"v40_relic", "id":id, "name":String(item["name"])}

	if not chests_opened.has("coast") and pos.distance_to(Vector2(170, 3095)) < 78.0:
		return {"type":"v40_chest", "id":"coast", "name":"Sunset Coast chest"}
	if not chests_opened.has("ridge") and pos.distance_to(Vector2(2860, 2845)) < 78.0:
		return {"type":"v40_chest", "id":"ridge", "name":"Cedar Ridge chest"}

	if pos.distance_to(Vector2(1250, 3070)) < 88.0:
		return {"type":"v40_tidepool", "name":"Tide pool"}
	if pos.distance_to(Vector2(2500, 3140)) < 92.0:
		return {"type":"v40_shrine", "name":"Cedar moon shrine"}
	return {}

func _install_collisions() -> void:
	var trees: Array[Vector2] = [
		Vector2(180,2390),Vector2(620,2405),Vector2(1860,2395),Vector2(2810,2400),
		Vector2(120,2660),Vector2(1510,2640),Vector2(1690,2710),Vector2(2900,2720),
		Vector2(150,2920),Vector2(1540,2930),Vector2(1700,2990),Vector2(2880,3040),
		Vector2(950,3230),Vector2(1840,3220),Vector2(2300,3260)
	]
	for i in range(trees.size()):
		_add_circle_obstacle("V40Tree%d" % i, trees[i], 28.0)

	var rocks: Array[Dictionary] = [
		{"p":Vector2(1810,2520),"r":44.0},
		{"p":Vector2(2210,2860),"r":52.0},
		{"p":Vector2(2640,2550),"r":48.0},
		{"p":Vector2(2470,2990),"r":42.0}
	]
	for i in range(rocks.size()):
		_add_circle_obstacle("V40Rock%d" % i, rocks[i]["p"], float(rocks[i]["r"]))

	# Deep ocean at the south edge is not walkable.
	_add_rect_obstacle("V40Ocean", Vector2(760, 3265), Vector2(1520, 120))
	# Small alpine pond at Cedar Ridge.
	_add_circle_obstacle("V40RidgePond", Vector2(2120, 2865), 92.0)

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
	_draw_ground()
	_draw_paths()
	_draw_regions()
	_draw_water()
	_draw_landmarks()
	_draw_trees()
	_draw_collectibles()
	_draw_npcs()
	_draw_carts()
	_draw_labels()

func _draw_ground() -> void:
	draw_rect(Rect2(0, EXPANSION_TOP, MAP_SIZE.x, MAP_SIZE.y - EXPANSION_TOP), Color("#78b45a"), true)
	# Coast and ridge receive different watercolor washes so they feel like distinct biomes.
	draw_rect(Rect2(0, 2760, 1600, 540), Color("#cfc27f"), true)
	draw_rect(Rect2(1600, 2520, 1400, 780), Color("#6c9c57"), true)
	for i in range(120):
		var x := 55.0 + fmod(float(i * 211 + (i % 9) * 43), 2860.0)
		var y := 2300.0 + fmod(float(i * 101 + (i % 7) * 59), 900.0)
		if i % 5 == 0:
			_draw_flower(Vector2(x,y), i)
		else:
			_draw_grass(Vector2(x,y), i)

func _draw_paths() -> void:
	var path := Color("#d8b976")
	var edge := Color(0.43,0.30,0.16,0.16)
	draw_rect(Rect2(1032, 2260, 96, 440), path, true)
	draw_rect(Rect2(420, 2398, 2100, 78), path, true)
	draw_rect(Rect2(500, 2450, 82, 600), path, true)
	draw_rect(Rect2(2240, 2440, 82, 620), path, true)
	draw_rect(Rect2(530, 3020, 2140, 70), path, true)
	for x in range(450, 2520, 72):
		_draw_ellipse(Vector2(float(x), 2404), Vector2(28,8), edge)
	for x in range(550, 2670, 78):
		_draw_ellipse(Vector2(float(x), 3088), Vector2(30,8), edge)

func _draw_regions() -> void:
	# Crossroads market stall.
	var stall := Rect2(1335, 2330, 200, 120)
	_draw_ellipse(Vector2(1435,2450),Vector2(78,12),Color(0.05,0.07,0.04,0.13))
	draw_rect(stall,Color("#9a633c"),true)
	draw_rect(Rect2(1318,2308,234,38),Color("#5c875e"),true)
	for i in range(6):
		if i % 2 == 0:
			draw_rect(Rect2(1318 + i*39,2308,39,38),Color("#ead59d"),true)

	# Cedar ruins use broken stone arcs and pillars.
	for p in [Vector2(1880,2630),Vector2(2020,2570),Vector2(2490,2640),Vector2(2690,2790),Vector2(2100,3070)]:
		draw_rect(Rect2(p-Vector2(24,40),Vector2(48,80)),Color("#9b9a83"),true)
		draw_rect(Rect2(p-Vector2(30,43),Vector2(60,10)),Color("#c0bca3"),true)
	for p in [Vector2(1760,2860),Vector2(2810,3170),Vector2(2360,3260)]:
		_draw_ellipse(p,Vector2(74,24),Color(0.30,0.34,0.27,0.18))

func _draw_water() -> void:
	# Sunset Coast ocean.
	draw_rect(Rect2(0, 3210, 1600, 90), Color("#4b9fb9"), true)
	for i in range(14):
		var y := 3222.0 + float(i % 3) * 20.0
		var x := 45.0 + float(i) * 108.0
		draw_line(Vector2(x,y),Vector2(x+58,y+sin(float(i))*3.0),Color(0.94,1.0,0.97,0.28),1.6)
	# Tide pool.
	_draw_ellipse(Vector2(1250,3070),Vector2(116,54),Color("#c7b076"))
	_draw_ellipse(Vector2(1250,3070),Vector2(101,43),Color("#5aa4b9"))
	# Ridge pond.
	_draw_ellipse(Vector2(2120,2865),Vector2(112,78),Color("#c7b47a"))
	_draw_ellipse(Vector2(2120,2865),Vector2(98,66),Color("#559bb0"))

func _draw_landmarks() -> void:
	# Coast keeper hut.
	var hut := Rect2(350,2510,270,190)
	_draw_ellipse(Vector2(485,2695),Vector2(92,12),Color(0.05,0.07,0.04,0.14))
	draw_texture_rect(HOUSE_TEX,hut,false,Color(0.94,0.86,0.66,1.0))
	# Cedar camp tent.
	var tent_c := Vector2(2380,2670)
	var tent_points := PackedVector2Array([tent_c+Vector2(-72,40),tent_c+Vector2(0,-60),tent_c+Vector2(72,40)])
	draw_colored_polygon(tent_points,Color("#807357"))
	draw_line(tent_c+Vector2(0,-60),tent_c+Vector2(0,42),Color("#5b4b37"),4.0)
	# Moon shrine.
	var s := Vector2(2500,3140)
	draw_circle(s,58,Color(0.65,0.69,0.61,0.24))
	draw_rect(Rect2(s-Vector2(34,42),Vector2(68,84)),Color("#8f917c"),true)
	draw_circle(s+Vector2(0,-7),18,Color("#d6d7b4"))
	draw_circle(s+Vector2(7,-12),18,Color("#8f917c"))

func _draw_trees() -> void:
	var rects: Array[Rect2] = [
		Rect2(80,2180,170,220),Rect2(540,2215,170,220),Rect2(1770,2190,172,223),Rect2(2720,2200,174,225),
		Rect2(40,2440,176,230),Rect2(1430,2440,180,232),Rect2(1605,2495,182,235),Rect2(2800,2500,180,232),
		Rect2(70,2700,176,228),Rect2(1430,2700,180,232),Rect2(1600,2760,184,238),Rect2(2780,2800,178,230),
		Rect2(860,3010,180,232),Rect2(1750,3000,182,236),Rect2(2210,3030,184,238)
	]
	for i in range(rects.size()):
		var r := rects[i]
		var tint := Color.WHITE
		if i % 3 == 1:
			tint = Color(0.94,1.0,0.92,1.0)
		elif i % 3 == 2:
			tint = Color(1.0,0.95,0.87,1.0)
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-6),Vector2(r.size.x*0.29,10),Color(0.05,0.07,0.04,0.13))
		draw_texture_rect(TREE_TEX,r,false,tint)

func _draw_collectibles() -> void:
	for item in debris_spots:
		var id := String(item["id"])
		if debris_collected.has(id):
			continue
		var p: Vector2 = item["pos"]
		draw_line(p-Vector2(22,7),p+Vector2(21,8),Color("#77593f"),8.0)
		draw_circle(p+Vector2(18,-2),7,Color("#c9b179"))
	for item in relic_spots:
		var id := String(item["id"])
		if relic_collected.has(id):
			continue
		var p: Vector2 = item["pos"]
		draw_circle(p,18,Color(0.95,0.88,0.52,0.20))
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-15),p+Vector2(12,5),p+Vector2(0,16),p+Vector2(-12,5)]),Color("#b1a37c"))
	if not chests_opened.has("coast"):
		_draw_chest(Vector2(170,3095))
	if not chests_opened.has("ridge"):
		_draw_chest(Vector2(2860,2845))

func _draw_chest(p: Vector2) -> void:
	_draw_ellipse(p+Vector2(0,10),Vector2(30,8),Color(0.05,0.05,0.03,0.16))
	draw_rect(Rect2(p-Vector2(29,18),Vector2(58,36)),Color("#8f5d32"),true)
	draw_rect(Rect2(p-Vector2(29,18),Vector2(58,9)),Color("#c99854"),true)
	draw_rect(Rect2(p-Vector2(4,4),Vector2(8,14)),Color("#e0bd68"),true)

func _draw_npcs() -> void:
	_draw_npc(OREN_TEX,Rect2(490,2625,90,126),"OREN")
	_draw_npc(MIRA_TEX,Rect2(2315,2625,90,126),"MIRA")
	_draw_npc(THEO_TEX,Rect2(1390,2365,88,120),"THEO")

func _draw_npc(tex: Texture2D, rect: Rect2, label: String) -> void:
	_draw_ellipse(Vector2(rect.position.x+rect.size.x*0.5,rect.end.y-5),Vector2(27,7),Color(0.04,0.06,0.03,0.14))
	draw_texture_rect(tex,rect,false,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x-12,rect.end.y+13),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x+24,10,Color("#5a4630"))

func _draw_carts() -> void:
	for p in [Vector2(1090,2425),Vector2(585,3130),Vector2(2650,3130)]:
		draw_rect(Rect2(p-Vector2(34,18),Vector2(68,36)),Color("#98683e"),true)
		draw_circle(p+Vector2(-23,22),9,Color("#5d4433"))
		draw_circle(p+Vector2(23,22),9,Color("#5d4433"))

func _draw_labels() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(950,2330),"SOUTH TRAIL",HORIZONTAL_ALIGNMENT_CENTER,280,16,Color("#58442f"))
	draw_string(ThemeDB.fallback_font,Vector2(360,2580),"SUNSET COAST",HORIZONTAL_ALIGNMENT_CENTER,420,19,Color("#655136"))
	draw_string(ThemeDB.fallback_font,Vector2(2050,2490),"CEDAR RIDGE",HORIZONTAL_ALIGNMENT_CENTER,500,19,Color("#43513d"))

func _draw_grass(p: Vector2, seed: int) -> void:
	var lean := float((seed % 5) - 2)
	var c := Color(0.20,0.39,0.16,0.30)
	draw_line(p,p+Vector2(lean,-10),c,1.2)
	draw_line(p+Vector2(4,1),p+Vector2(6+lean,-7),c,1.0)

func _draw_flower(p: Vector2, seed: int) -> void:
	var petals := [Color("#f7e6a6"),Color("#f1c6cf"),Color("#d9d6f0")]
	var c: Color = petals[seed % petals.size()]
	draw_line(p,p+Vector2(0,-10),Color("#4e7b3f"),1.4)
	draw_circle(p+Vector2(0,-12),4,c)
	draw_circle(p+Vector2(0,-12),1.5,Color("#cfa34e"))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
