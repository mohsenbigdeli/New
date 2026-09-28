extends Node2D
class_name FarmHighlandsV41

const MAP_SIZE := Vector2(3800, 3600)
const REGION_LEFT := 2940.0
const REGION_TOP := 2200.0

const TREE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_tree.png")
const HOUSE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_house.png")
const IVY_TEX: Texture2D = preload("res://assets/art/v17/watercolor_lina.png")
const GARRICK_TEX: Texture2D = preload("res://assets/art/v17/watercolor_rowan.png")

var active := true
var current_day := 1
var collision_bodies: Array[CollisionObject2D] = []
var blooms_collected: Dictionary = {}
var crystals_collected: Dictionary = {}
var chests_opened: Dictionary = {}
var daily_collected: Dictionary = {}

var bloom_spots: Array[Dictionary] = [
	{"id":"bloom_1", "name":"Silverleaf bloom", "pos":Vector2(3160, 2670)},
	{"id":"bloom_2", "name":"Suncrest flower", "pos":Vector2(3500, 2480)},
	{"id":"bloom_3", "name":"Cloudbell flower", "pos":Vector2(3650, 2860)},
	{"id":"bloom_4", "name":"Moonpetal bloom", "pos":Vector2(3290, 3040)}
]

var crystal_spots: Array[Dictionary] = [
	{"id":"crystal_1", "name":"Blue crystal cluster", "pos":Vector2(3125, 3260)},
	{"id":"crystal_2", "name":"Quartz vein", "pos":Vector2(3325, 3420)},
	{"id":"crystal_3", "name":"Amber crystal", "pos":Vector2(3510, 3370)},
	{"id":"crystal_4", "name":"Moonstone cluster", "pos":Vector2(3690, 3220)},
	{"id":"crystal_5", "name":"Deep crystal vein", "pos":Vector2(3600, 3505)}
]

var daily_spots: Array[Dictionary] = [
	{"id":"pinecone", "name":"Pinecone cache", "pos":Vector2(3070, 2860)},
	{"id":"dew", "name":"Crystal dew", "pos":Vector2(3400, 2750)},
	{"id":"herbs", "name":"Highland herb patch", "pos":Vector2(3710, 3020)}
]

func _ready() -> void:
	z_index = 0
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

func set_state(
		blooms: Dictionary,
		crystals: Dictionary,
		chests: Dictionary,
		daily: Dictionary,
		day: int
	) -> void:
	blooms_collected = blooms.duplicate(true)
	crystals_collected = crystals.duplicate(true)
	chests_opened = chests.duplicate(true)
	daily_collected = daily.duplicate(true)
	current_day = day
	queue_redraw()

func get_interaction(pos: Vector2) -> Dictionary:
	if not active:
		return {}

	if pos.distance_to(Vector2(3010, 2390)) < 95.0:
		return {"type":"v41_sign", "name":"Pinewatch Highlands map"}
	if pos.distance_to(Vector2(3045, 2495)) < 95.0:
		return {"type":"v41_cart", "name":"Trail Cart · South Crossroads"}
	if pos.distance_to(Vector2(3235, 2530)) < 95.0:
		return {"type":"v41_ivy", "name":"Ivy · Highland Botanist"}
	if pos.distance_to(Vector2(3440, 3260)) < 95.0:
		return {"type":"v41_garrick", "name":"Garrick · Crystal Prospector"}
	if pos.distance_to(Vector2(3520, 2850)) < 105.0:
		return {"type":"v41_hot_spring", "name":"Pinewatch hot spring"}
	if pos.distance_to(Vector2(3680, 2520)) < 95.0:
		return {"type":"v41_lookout", "name":"Skylook Point"}
	if pos.distance_to(Vector2(3210, 3450)) < 95.0:
		return {"type":"v41_sky_shrine", "name":"Sky Shrine"}

	for item in bloom_spots:
		var id := String(item["id"])
		if blooms_collected.has(id):
			continue
		if pos.distance_to(item["pos"]) < 74.0:
			return {"type":"v41_bloom", "id":id, "name":String(item["name"])}

	for item in crystal_spots:
		var id := String(item["id"])
		if crystals_collected.has(id):
			continue
		if pos.distance_to(item["pos"]) < 78.0:
			return {"type":"v41_crystal", "id":id, "name":String(item["name"])}

	for item in daily_spots:
		var id := String(item["id"])
		if daily_collected.has(id):
			continue
		if pos.distance_to(item["pos"]) < 76.0:
			return {"type":"v41_daily", "id":id, "name":String(item["name"])}

	if not chests_opened.has("lookout") and pos.distance_to(Vector2(3750, 2635)) < 78.0:
		return {"type":"v41_chest", "id":"lookout", "name":"Lookout cache"}
	if not chests_opened.has("cave") and pos.distance_to(Vector2(3065, 3490)) < 78.0:
		return {"type":"v41_chest", "id":"cave", "name":"Crystal cave chest"}
	if not chests_opened.has("spring") and pos.distance_to(Vector2(3660, 2945)) < 78.0:
		return {"type":"v41_chest", "id":"spring", "name":"Hot spring chest"}

	return {}

func _install_collisions() -> void:
	var trees: Array[Vector2] = [
		Vector2(3070,2310), Vector2(3300,2325), Vector2(3570,2305), Vector2(3760,2360),
		Vector2(3110,2570), Vector2(3390,2600), Vector2(3740,2660),
		Vector2(3035,2935), Vector2(3300,2920), Vector2(3740,3140),
		Vector2(3040,3180), Vector2(3240,3200), Vector2(3770,3440)
	]
	for i in range(trees.size()):
		_add_circle_obstacle("V41Tree%d" % i, trees[i], 27.0)

	_add_circle_obstacle("V41HotSpring", Vector2(3520, 2850), 95.0)
	_add_rect_obstacle("V41NorthCliff", Vector2(3370, 2205), Vector2(820, 40))
	_add_rect_obstacle("V41EastCliff", Vector2(3790, 2880), Vector2(30, 1300))

	var rocks: Array[Dictionary] = [
		{"p":Vector2(3060,3300),"r":44.0},
		{"p":Vector2(3210,3370),"r":38.0},
		{"p":Vector2(3410,3290),"r":48.0},
		{"p":Vector2(3615,3400),"r":42.0},
		{"p":Vector2(3740,3260),"r":45.0}
	]
	for i in range(rocks.size()):
		_add_circle_obstacle("V41CaveRock%d" % i, rocks[i]["p"], float(rocks[i]["r"]))

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
	_draw_cliffs()
	_draw_hot_spring()
	_draw_cave()
	_draw_lodge()
	_draw_trees()
	_draw_blooms()
	_draw_crystals()
	_draw_daily_spots()
	_draw_chests()
	_draw_npcs()
	_draw_cart()
	_draw_lookout()
	_draw_sky_shrine()
	_draw_labels()

func _draw_ground() -> void:
	draw_rect(Rect2(REGION_LEFT, REGION_TOP, MAP_SIZE.x - REGION_LEFT, MAP_SIZE.y - REGION_TOP), Color("#75ad58"), true)
	draw_rect(Rect2(2980, 3150, 800, 450), Color("#536a50"), true)
	for i in range(105):
		var x := 2985.0 + fmod(float(i * 137 + (i % 7) * 47), 760.0)
		var y := 2240.0 + fmod(float(i * 91 + (i % 5) * 39), 1290.0)
		if Vector2(x,y).distance_to(Vector2(3520,2850)) < 145.0:
			continue
		if i % 6 == 0:
			_draw_flower(Vector2(x,y), i)
		else:
			_draw_grass(Vector2(x,y), i)

func _draw_paths() -> void:
	var path := Color("#d2b16f")
	var edge := Color(0.42,0.29,0.15,0.17)
	draw_rect(Rect2(2940, 2405, 445, 78), path, true)
	draw_rect(Rect2(3200, 2400, 82, 780), path, true)
	draw_rect(Rect2(3240, 2765, 470, 72), path, true)
	draw_rect(Rect2(3620, 2470, 72, 370), path, true)
	draw_rect(Rect2(3210, 3090, 80, 420), path, true)
	draw_rect(Rect2(3210, 3420, 430, 68), path, true)
	for x in range(2960, 3700, 66):
		_draw_ellipse(Vector2(float(x), 2410), Vector2(25,8), edge)
	for y in range(2440, 3480, 68):
		_draw_ellipse(Vector2(3205, float(y)), Vector2(8,25), edge)

func _draw_cliffs() -> void:
	for x in range(3000, 3780, 72):
		var y := 2240.0 + sin(float(x) * 0.02) * 14.0
		_draw_ellipse(Vector2(float(x), y), Vector2(34,16), Color("#78745f"))
		_draw_ellipse(Vector2(float(x), y - 5), Vector2(28,10), Color("#aaa184"))
	for p in [Vector2(2990,3060),Vector2(3120,3120),Vector2(3690,3050),Vector2(3760,2960)]:
		_draw_ellipse(p, Vector2(56,24), Color(0.26,0.30,0.23,0.25))
		_draw_ellipse(p-Vector2(0,7), Vector2(48,18), Color("#8b8873"))

func _draw_hot_spring() -> void:
	var c := Vector2(3520, 2850)
	_draw_ellipse(c + Vector2(0,18), Vector2(135,44), Color(0.06,0.08,0.05,0.17))
	draw_circle(c, 124, Color("#c9b783"))
	draw_circle(c, 110, Color("#74a9a7"))
	draw_circle(c, 96, Color("#6bb7b3"))
	for i in range(5):
		var p := c + Vector2(-58.0 + float(i)*30.0, sin(float(i)*1.7)*24.0)
		draw_line(p-Vector2(12,0), p+Vector2(12,0), Color(1,1,1,0.22), 1.5)
	for i in range(4):
		var sx := 3470.0 + float(i)*30.0
		draw_line(Vector2(sx,2770),Vector2(sx+sin(float(i))*5.0,2745),Color(0.92,0.98,0.92,0.13),2.0)

func _draw_cave() -> void:
	var mouth := Vector2(3360, 3200)
	_draw_ellipse(mouth, Vector2(170,78), Color("#3f493e"))
	_draw_ellipse(mouth + Vector2(0,12), Vector2(130,57), Color("#26302d"))
	for p in [Vector2(3090,3310),Vector2(3290,3370),Vector2(3490,3320),Vector2(3700,3410)]:
		_draw_ellipse(p,Vector2(46,22),Color("#6f725f"))

func _draw_lodge() -> void:
	var r := Rect2(3090, 2290, 260, 188)
	_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-3),Vector2(92,12),Color(0.05,0.07,0.04,0.14))
	draw_texture_rect(HOUSE_TEX,r,false,Color(0.84,0.92,0.78,1.0))

func _draw_trees() -> void:
	var rects: Array[Rect2] = [
		Rect2(2980,2130,165,215),Rect2(3220,2150,168,218),Rect2(3485,2135,170,220),Rect2(3670,2180,168,218),
		Rect2(3015,2370,170,220),Rect2(3300,2400,174,225),Rect2(3660,2460,172,222),
		Rect2(2960,2730,176,228),Rect2(3220,2710,174,225),Rect2(3660,2890,176,228),
		Rect2(2965,2970,176,228),Rect2(3170,2980,176,228),Rect2(3675,3230,178,230)
	]
	for i in range(rects.size()):
		var r: Rect2 = rects[i]
		var tint := Color.WHITE
		if i % 3 == 1:
			tint = Color(0.93,1.0,0.91,1.0)
		elif i % 3 == 2:
			tint = Color(1.0,0.96,0.88,1.0)
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-7),Vector2(r.size.x*0.30,10),Color(0.05,0.08,0.04,0.13))
		draw_texture_rect(TREE_TEX,r,false,tint)

func _draw_blooms() -> void:
	for item in bloom_spots:
		var id := String(item["id"])
		if blooms_collected.has(id):
			continue
		var p: Vector2 = item["pos"]
		for i in range(5):
			var a := TAU * float(i) / 5.0
			var q := p + Vector2(cos(a),sin(a))*12.0
			draw_line(q,q+Vector2(0,-12),Color("#527b43"),2.0)
			draw_circle(q+Vector2(0,-15),5.0,Color("#f2d4e8") if i%2==0 else Color("#d8e7ff"))

func _draw_crystals() -> void:
	for item in crystal_spots:
		var id := String(item["id"])
		if crystals_collected.has(id):
			continue
		var p: Vector2 = item["pos"]
		for i in range(4):
			var off := Vector2(float(i-2)*8.0, float(abs(i-2))*4.0)
			var points := PackedVector2Array([
				p+off+Vector2(-5,6),p+off+Vector2(0,-18-float(i%2)*7.0),
				p+off+Vector2(6,6),p+off+Vector2(0,12)
			])
			draw_colored_polygon(points,Color("#86c4d8") if i%2==0 else Color("#c6b4dd"))

func _draw_daily_spots() -> void:
	for item in daily_spots:
		var id := String(item["id"])
		if daily_collected.has(id):
			continue
		var p: Vector2 = item["pos"]
		if id == "pinecone":
			draw_circle(p,12,Color("#805d3c"))
			draw_line(p+Vector2(-7,-7),p+Vector2(7,7),Color("#c59b62"),2.0)
		elif id == "dew":
			draw_circle(p,13,Color(0.55,0.86,0.94,0.62))
			draw_circle(p-Vector2(4,4),4,Color(1,1,1,0.55))
		else:
			for i in range(6):
				var q := p+Vector2(float(i-3)*7.0, sin(float(i))*5.0)
				draw_line(q,q+Vector2(0,-17),Color("#507e43"),2.5)

func _draw_chests() -> void:
	var entries: Array[Dictionary] = [
		{"id":"lookout","p":Vector2(3750,2635)},
		{"id":"cave","p":Vector2(3065,3490)},
		{"id":"spring","p":Vector2(3660,2945)}
	]
	for item in entries:
		if chests_opened.has(String(item["id"])):
			continue
		var p: Vector2 = item["p"]
		draw_rect(Rect2(p-Vector2(22,14),Vector2(44,28)),Color("#8f623b"),true)
		draw_rect(Rect2(p-Vector2(22,14),Vector2(44,8)),Color("#c69a5a"),true)
		draw_circle(p,4,Color("#e7cf77"))

func _draw_npcs() -> void:
	_draw_npc_sprite(Vector2(3235,2530), IVY_TEX, "IVY")
	_draw_npc_sprite(Vector2(3440,3260), GARRICK_TEX, "GARRICK")

func _draw_npc_sprite(p: Vector2, tex: Texture2D, label: String) -> void:
	_draw_ellipse(p+Vector2(0,35),Vector2(28,7),Color(0.05,0.07,0.04,0.15))
	draw_texture_rect(tex,Rect2(p-Vector2(43,70),Vector2(86,118)),false,Color.WHITE)
	draw_string(ThemeDB.fallback_font,p+Vector2(-45,58),label,HORIZONTAL_ALIGNMENT_CENTER,90,11,Color("#5a4631"))

func _draw_cart() -> void:
	var p := Vector2(3045,2495)
	draw_rect(Rect2(p-Vector2(34,15),Vector2(68,30)),Color("#8b603b"),true)
	draw_circle(p+Vector2(-22,18),11,Color("#514438"))
	draw_circle(p+Vector2(22,18),11,Color("#514438"))
	draw_line(p+Vector2(34,-4),p+Vector2(62,-18),Color("#705238"),5.0)

func _draw_lookout() -> void:
	var p := Vector2(3680,2520)
	draw_rect(Rect2(p-Vector2(48,8),Vector2(96,16)),Color("#876344"),true)
	for x in [-38.0,38.0]:
		draw_line(p+Vector2(x,0),p+Vector2(x,45),Color("#6c4c32"),6.0)
	draw_line(p+Vector2(-48,-2),p+Vector2(48,-2),Color("#c39864"),3.0)

func _draw_sky_shrine() -> void:
	var p := Vector2(3210,3450)
	draw_circle(p,48,Color(0.70,0.72,0.64,0.25))
	draw_rect(Rect2(p-Vector2(28,37),Vector2(56,74)),Color("#8d907e"),true)
	draw_circle(p-Vector2(0,5),16,Color("#d7d9c3"))
	draw_circle(p+Vector2(7,-10),16,Color("#8d907e"))

func _draw_labels() -> void:
	draw_string(ThemeDB.fallback_font,Vector2(3010,2265),"PINEWATCH HIGHLANDS",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#40513a"))
	draw_string(ThemeDB.fallback_font,Vector2(3000,3150),"CRYSTAL HOLLOW",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#d7dfcf"))
	draw_string(ThemeDB.fallback_font,Vector2(3450,2725),"HOT SPRING",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#49605a"))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(30):
		var a := TAU * float(i) / 30.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points,color)

func _draw_grass(p: Vector2, seed: int) -> void:
	var sway := sin(float(seed)*1.73)*2.0
	var col := Color(0.22,0.43,0.20,0.34)
	draw_line(p,p+Vector2(sway,-8.0-float(seed%4)*1.5),col,1.2)
	draw_line(p+Vector2(4,1),p+Vector2(5+sway,-6),col,1.0)

func _draw_flower(p: Vector2, seed: int) -> void:
	draw_line(p,p+Vector2(0,-10),Color("#4f7c3f"),1.7)
	var c := Color("#efd6e7") if seed%2==0 else Color("#f0d47f")
	draw_circle(p+Vector2(0,-12),3.5,c)
