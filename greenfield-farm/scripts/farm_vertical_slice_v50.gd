extends Node2D
class_name FarmVerticalSliceV50

const HOUSE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_house.png")
const TREE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_tree.png")
const POND_TEX: Texture2D = preload("res://assets/art/v17/watercolor_pond.png")
const ROWAN_TEX: Texture2D = preload("res://assets/art/v17/watercolor_rowan.png")
const LINA_TEX: Texture2D = preload("res://assets/art/v17/watercolor_lina.png")
const MARNIE_TEX: Texture2D = preload("res://assets/art/v17/watercolor_marnie.png")
const SOIL_TEX: Texture2D = preload("res://assets/art/soil_tile.svg")
const SOIL_WET_TEX: Texture2D = preload("res://assets/art/soil_wet_tile.svg")

var farm: FarmWorld
var active := true
var t := 0.0
var collision_bodies: Array[CollisionObject2D] = []

func setup(world: FarmWorld) -> void:
	farm = world
	z_index = -5
	_install_slice_collisions()
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	for body in collision_bodies:
		if is_instance_valid(body):
			body.collision_layer = 1 if value else 0
			body.collision_mask = 1 if value else 0
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	t += delta
	queue_redraw()

func get_interaction(pos: Vector2) -> Dictionary:
	if not active:
		return {}
	if pos.distance_to(Vector2(1135, 445)) < 78.0:
		return {"type":"v50_welcome_board", "name":"Greenfield notice board"}
	if pos.distance_to(Vector2(1380, 1115)) < 82.0:
		return {"type":"v50_well", "name":"Village well"}
	if pos.distance_to(Vector2(1608, 724)) < 82.0:
		return {"type":"v50_bench", "name":"Pond bench"}
	if pos.distance_to(Vector2(825, 1118)) < 82.0:
		return {"type":"v50_garden", "name":"Community herb garden"}
	return {}

func _install_slice_collisions() -> void:
	_add_circle_obstacle("V50VillageWell", Vector2(1380, 1115), 34.0)
	_add_rect_obstacle("V50PondBench", Vector2(1608, 724), Vector2(82, 30))
	_add_rect_obstacle("V50NoticeBoard", Vector2(1135, 445), Vector2(46, 36))

func _add_circle_obstacle(node_name: String, center: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
	collision_bodies.append(body)

func _add_rect_obstacle(node_name: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
	collision_bodies.append(body)

func _draw() -> void:
	if not active or not farm:
		return
	_draw_ground()
	_draw_paths()
	_draw_field()
	_draw_water()
	_draw_buildings()
	_draw_town_square()
	_draw_trees()
	_draw_shipping_bin()
	_draw_small_landmarks()
	_draw_npcs()
	_draw_meadow_details()
	_draw_edge_vignette()

func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, FarmWorld.WORLD_SIZE), Color("#8bc76d"), true)

	var washes: Array[Dictionary] = [
		{"p":Vector2(320, 250), "r":Vector2(330, 190), "c":Color(0.96,0.84,0.42,0.070)},
		{"p":Vector2(820, 310), "r":Vector2(420, 230), "c":Color(0.39,0.67,0.29,0.075)},
		{"p":Vector2(420, 970), "r":Vector2(360, 220), "c":Color(0.82,0.72,0.30,0.050)},
		{"p":Vector2(1510, 920), "r":Vector2(450, 250), "c":Color(0.38,0.65,0.28,0.072)},
		{"p":Vector2(1900, 1260), "r":Vector2(330, 190), "c":Color(0.91,0.79,0.37,0.050)}
	]
	for item in washes:
		_draw_ellipse(item["p"], item["r"], item["c"])

	for i in range(150):
		var x := 36.0 + fmod(float(i * 139 + (i % 11) * 41), 2200.0)
		var y := 42.0 + fmod(float(i * 97 + (i % 7) * 53), 1430.0)
		if _is_path_area(Vector2(x,y)):
			continue
		if Vector2(x,y).distance_to(Vector2(1415, 600)) < 230.0:
			continue
		var sway := sin(t * 0.35 + float(i) * 1.7) * 1.4
		var h := 5.0 + float(i % 4) * 1.4
		var color := Color(0.24,0.50,0.22,0.24) if i % 2 == 0 else Color(0.63,0.72,0.31,0.22)
		draw_line(Vector2(x,y), Vector2(x+sway,y-h), color, 1.15)

func _is_path_area(p: Vector2) -> bool:
	if p.y > 382.0 and p.y < 482.0:
		return true
	if p.x > 1022.0 and p.x < 1127.0 and p.y > 380.0 and p.y < 1290.0:
		return true
	if p.y > 785.0 and p.y < 882.0 and p.x > 1015.0 and p.x < 2075.0:
		return true
	if p.y > 1098.0 and p.y < 1195.0 and p.x > 1060.0 and p.x < 2050.0:
		return true
	return false

func _draw_paths() -> void:
	var base := Color("#dbbb7c")
	var edge := Color(0.47,0.34,0.20,0.15)
	_draw_soft_path(Rect2(0, 392, FarmWorld.WORLD_SIZE.x, 90), false, base, edge)
	_draw_soft_path(Rect2(1028, 392, 94, 900), true, base, edge)
	_draw_soft_path(Rect2(1028, 792, 1040, 88), false, base, edge)
	_draw_soft_path(Rect2(1068, 1110, 980, 82), false, base, edge)

	_draw_soft_path(Rect2(360, 360, 74, 180), true, Color("#dec188"), Color(0.43,0.31,0.19,0.12))
	for p in [
		Vector2(1190, 930), Vector2(1245, 965), Vector2(1300, 988),
		Vector2(1358, 1000), Vector2(1415, 992), Vector2(1470, 970)
	]:
		_draw_ellipse(p, Vector2(18,7), Color(0.50,0.40,0.25,0.12))

func _draw_soft_path(rect: Rect2, vertical: bool, base: Color, edge: Color) -> void:
	draw_rect(rect, base, true)
	if vertical:
		for y in range(int(rect.position.y)+18, int(rect.end.y), 46):
			_draw_ellipse(Vector2(rect.position.x+3,float(y)), Vector2(11,24), edge)
			_draw_ellipse(Vector2(rect.end.x-3,float(y+21)), Vector2(11,24), edge)
	else:
		for x in range(int(rect.position.x)+18, int(rect.end.x), 58):
			_draw_ellipse(Vector2(float(x),rect.position.y+3), Vector2(29,9), edge)
			_draw_ellipse(Vector2(float(x+25),rect.end.y-3), Vector2(29,9), edge)

	for i in range(16):
		var px := rect.position.x + 10.0 + fmod(float(i*73), maxf(24.0, rect.size.x-20.0))
		var py := rect.position.y + 9.0 + fmod(float(i*31), maxf(18.0, rect.size.y-18.0))
		_draw_ellipse(Vector2(px,py), Vector2(3.0+float(i%3),1.5), Color(0.37,0.27,0.16,0.11))

func _draw_field() -> void:
	var field_rect := Rect2(FarmWorld.ORIGIN - Vector2(22,22), Vector2(FarmWorld.COLS * FarmWorld.TILE_SIZE + 44, FarmWorld.ROWS * FarmWorld.TILE_SIZE + 44))
	draw_rect(field_rect, Color(0.18,0.39,0.14,0.085), true)

	draw_line(field_rect.position + Vector2(0,2), Vector2(field_rect.end.x, field_rect.position.y+2), Color(0.34,0.45,0.23,0.16), 2.0)
	draw_line(Vector2(field_rect.position.x,field_rect.end.y-2), field_rect.end-Vector2(0,2), Color(0.34,0.45,0.23,0.16), 2.0)

	for y in range(FarmWorld.ROWS):
		for x in range(FarmWorld.COLS):
			var cell := Vector2i(x,y)
			var data: Dictionary = farm.get_cell(cell)
			if not bool(data.get("tilled", false)):
				continue
			var pos := FarmWorld.ORIGIN + Vector2(x*FarmWorld.TILE_SIZE + 4, y*FarmWorld.TILE_SIZE + 4)
			var rect := Rect2(pos, Vector2(FarmWorld.TILE_SIZE-8, FarmWorld.TILE_SIZE-8))
			var tex: Texture2D = SOIL_WET_TEX if bool(data.get("watered", false)) else SOIL_TEX
			draw_texture_rect(tex, rect, false, Color(1.0,0.98,0.92,0.95))
			_draw_soil_brush_edges(rect, x+y)
			var crop := String(data.get("crop",""))
			if not crop.is_empty():
				_draw_crop(rect.get_center(), crop, int(data.get("stage",0)), int(data.get("age",0)))

func _draw_soil_brush_edges(rect: Rect2, seed: int) -> void:
	var col := Color(0.24,0.15,0.09,0.13)
	draw_line(rect.position+Vector2(5,4), Vector2(rect.end.x-7,rect.position.y+3+float(seed%3)), col, 1.0)
	draw_line(Vector2(rect.position.x+7,rect.end.y-4), rect.end-Vector2(5,4), col, 1.0)

func _draw_crop(center: Vector2, crop: String, stage: int, age: int) -> void:
	var growth := 0.55 + float(stage) * 0.18
	var leaf := Color("#5f9f48")
	var fruit := Color("#e9e4d6")
	if crop == "carrot":
		leaf = Color("#4a9547")
		fruit = Color("#e98a38")
	elif crop == "corn":
		leaf = Color("#73a94d")
		fruit = Color("#efc84a")

	var stem_h := 13.0 + float(stage) * 5.0
	for i in range(3):
		var stem_x := center.x + float(i-1) * 7.0
		draw_line(Vector2(stem_x,center.y+10), Vector2(stem_x+float(i-1)*2.0,center.y-stem_h), leaf, 3.0)
		_draw_leaf(Vector2(stem_x,center.y-stem_h*0.55), float(i-1)*0.55, leaf, growth)

	if stage >= 2:
		if crop == "corn":
			draw_rect(Rect2(center+Vector2(-5,-8),Vector2(10,20)), fruit, true)
		else:
			draw_circle(center + Vector2(0,7), 6.0 + float(stage)*1.2, fruit)

	if age >= 1:
		draw_circle(center+Vector2(-13,-18), 2.2, Color(1.0,0.95,0.70,0.34))

func _draw_leaf(origin: Vector2, angle: float, color: Color, scale_value: float) -> void:
	var d := Vector2(cos(angle),sin(angle))
	var side := Vector2(-d.y,d.x)
	var points := PackedVector2Array([
		origin,
		origin + d * 13.0 * scale_value + side * 5.0 * scale_value,
		origin + d * 23.0 * scale_value,
		origin + d * 13.0 * scale_value - side * 5.0 * scale_value
	])
	draw_colored_polygon(points, color)

func _draw_water() -> void:
	draw_rect(Rect2(2102, 0, 20, FarmWorld.WORLD_SIZE.y), Color("#cbb17b"), true)
	draw_rect(Rect2(2122, 0, 182, FarmWorld.WORLD_SIZE.y), Color("#4d9fb8"), true)
	for i in range(30):
		var yy := 32.0 + float(i) * 48.0
		draw_line(Vector2(2145,yy), Vector2(2192+float(i%3)*8.0,yy+sin(t*0.35+float(i))*1.5), Color(0.93,1.0,0.98,0.23), 1.3)

	var pond_rect := Rect2(1236, 410, 366, 372)
	_draw_ellipse(pond_rect.get_center()+Vector2(0,22), Vector2(160,45), Color(0.06,0.10,0.05,0.13))
	draw_texture_rect(POND_TEX, pond_rect, false, Color.WHITE)
	for i in range(6):
		var a := t*0.22 + float(i)*1.05
		var p := pond_rect.get_center() + Vector2(cos(a)*float(22+i*13), sin(a*1.07)*float(11+i*7))
		draw_line(p-Vector2(8,0), p+Vector2(8,0), Color(0.98,1.0,0.96,0.18), 1.1)

func _draw_buildings() -> void:
	_draw_building(Rect2(180, 86, 430, 310), Color.WHITE, "FARMHOUSE")
	_draw_building(Rect2(1600, 96, 360, 262), Color(0.86,0.98,0.89,1.0), "GENERAL STORE")
	_draw_building(Rect2(1590, 790, 388, 282), Color(0.90,0.94,1.0,1.0), "TOWN HALL")
	_draw_building(Rect2(258, 1058, 390, 280), Color(1.0,0.78,0.72,1.0), "BARN")

func _draw_building(rect: Rect2, tint: Color, kind: String) -> void:
	_draw_ellipse(Vector2(rect.position.x+rect.size.x*0.5,rect.end.y-4), Vector2(rect.size.x*0.34,15), Color(0.05,0.07,0.04,0.13))
	draw_texture_rect(HOUSE_TEX, rect, false, tint)

	if kind == "FARMHOUSE":
		for i in range(7):
			_draw_flower(rect.position + Vector2(68.0+float(i)*48.0, rect.size.y-10.0+sin(float(i))*4.0), i+10)
	elif kind == "GENERAL STORE":
		var awning := Rect2(rect.position + Vector2(rect.size.x*0.50,rect.size.y*0.62), Vector2(rect.size.x*0.42,28))
		draw_rect(awning, Color("#5f8c65"), true)
		for i in range(6):
			if i % 2 == 0:
				draw_rect(Rect2(awning.position+Vector2(float(i)*awning.size.x/6.0,0),Vector2(awning.size.x/6.0,awning.size.y)), Color(0.94,0.84,0.61,0.82), true)
		_draw_sign(Rect2(rect.position+Vector2(rect.size.x*0.56,rect.size.y*0.46),Vector2(128,30)), "GENERAL STORE")
	elif kind == "TOWN HALL":
		var c := rect.position + Vector2(rect.size.x*0.5,rect.size.y*0.29)
		draw_circle(c, 22, Color(0.97,0.93,0.76,0.96))
		draw_circle(c, 22, Color("#655847"), false, 3.0)
		draw_line(c,c+Vector2(0,-10),Color("#584a39"),3.0)
		draw_line(c,c+Vector2(9,5),Color("#584a39"),3.0)
	elif kind == "BARN":
		var door := Rect2(rect.position+Vector2(rect.size.x*0.34,rect.size.y*0.52),Vector2(rect.size.x*0.32,rect.size.y*0.38))
		draw_rect(door,Color("#57331f"),true)
		draw_line(door.position+Vector2(8,8),door.end-Vector2(8,8),Color("#c78b5a"),5.0)
		draw_line(Vector2(door.end.x-8,door.position.y+8),Vector2(door.position.x+8,door.end.y-8),Color("#c78b5a"),5.0)

func _draw_sign(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color(0.40,0.27,0.17,0.94), true)
	draw_string(ThemeDB.fallback_font, rect.position+Vector2(5,20), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x-10, 11, Color("#fff1c8"))

func _draw_town_square() -> void:
	_draw_ellipse(Vector2(1380, 1085), Vector2(260,118), Color(0.91,0.82,0.58,0.11))
	for p in [
		Vector2(1220,1055),Vector2(1280,1100),Vector2(1470,1100),Vector2(1530,1050),
		Vector2(1260,1160),Vector2(1500,1160)
	]:
		_draw_flower(p, int(p.x+p.y))

	var well := Vector2(1380,1115)
	_draw_ellipse(well+Vector2(0,8),Vector2(45,12),Color(0.06,0.07,0.05,0.16))
	draw_circle(well, 35, Color("#b6ad91"))
	draw_circle(well, 27, Color("#4f8390"))
	draw_circle(well, 27, Color("#797764"), false, 5.0)
	draw_line(well+Vector2(-27,-15),well+Vector2(-27,-52),Color("#77563b"),5.0)
	draw_line(well+Vector2(27,-15),well+Vector2(27,-52),Color("#77563b"),5.0)
	draw_line(well+Vector2(-31,-49),well+Vector2(31,-49),Color("#77563b"),5.0)

func _draw_trees() -> void:
	var rects: Array[Rect2] = [
		Rect2(42,100,176,228), Rect2(650,80,168,218), Rect2(820,125,180,234),
		Rect2(1868,380,172,224), Rect2(1960,570,150,194),
		Rect2(700,1132,172,224), Rect2(1410,1160,182,236),
		Rect2(1840,1200,170,220), Rect2(80,1170,180,234)
	]
	for i in range(rects.size()):
		var r := rects[i]
		var tint := Color.WHITE
		if i % 3 == 1:
			tint = Color(1.0,0.97,0.91,1.0)
		elif i % 3 == 2:
			tint = Color(0.95,1.0,0.94,1.0)
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-7),Vector2(r.size.x*0.29,10),Color(0.05,0.08,0.04,0.13))
		draw_texture_rect(TREE_TEX,r,false,tint)

func _draw_shipping_bin() -> void:
	var p := Vector2(1080,680)
	_draw_ellipse(p+Vector2(0,16),Vector2(38,10),Color(0.05,0.06,0.04,0.14))
	draw_rect(Rect2(p-Vector2(34,28),Vector2(68,55)),Color("#7b5435"),true)
	draw_rect(Rect2(p-Vector2(37,31),Vector2(74,12)),Color("#553923"),true)
	draw_line(p+Vector2(-22,-14),p+Vector2(22,15),Color(0.91,0.75,0.52,0.33),2.0)
	draw_string(ThemeDB.fallback_font,p+Vector2(-32,47),"SHIP",HORIZONTAL_ALIGNMENT_CENTER,64,10,Color("#5b4634"))

func _draw_small_landmarks() -> void:
	var b := Vector2(1135,445)
	draw_line(b+Vector2(-15,8),b+Vector2(-15,48),Color("#715037"),5.0)
	draw_line(b+Vector2(15,8),b+Vector2(15,48),Color("#715037"),5.0)
	draw_rect(Rect2(b-Vector2(36,18),Vector2(72,38)),Color("#8b6545"),true)
	draw_string(ThemeDB.fallback_font,b+Vector2(-31,5),"GREENFIELD",HORIZONTAL_ALIGNMENT_CENTER,62,9,Color("#fff0c9"))

	var bench := Vector2(1608,724)
	draw_line(bench+Vector2(-33,0),bench+Vector2(33,0),Color("#79563b"),8.0)
	draw_line(bench+Vector2(-29,-14),bench+Vector2(29,-14),Color("#9a724d"),7.0)
	draw_line(bench+Vector2(-23,3),bench+Vector2(-23,20),Color("#64472f"),5.0)
	draw_line(bench+Vector2(23,3),bench+Vector2(23,20),Color("#64472f"),5.0)

	var g := Vector2(825,1118)
	_draw_ellipse(g+Vector2(0,8),Vector2(54,16),Color(0.08,0.11,0.06,0.10))
	for i in range(9):
		var q := g + Vector2(float(i-4)*10.0, sin(float(i)*1.5)*8.0)
		draw_line(q,q+Vector2(1,-18),Color("#4f833f"),3.0)
		draw_circle(q+Vector2(3,-17),4,Color("#82ad68"))

func _draw_npcs() -> void:
	_draw_npc(ROWAN_TEX, FarmWorld.MAYOR_SPOT, "ROWAN")
	_draw_npc(LINA_TEX, FarmWorld.LINA_SPOT, "LINA")
	_draw_npc(MARNIE_TEX, FarmWorld.MARNIE_SPOT, "MARNIE")

func _draw_npc(tex: Texture2D, p: Vector2, label: String) -> void:
	_draw_ellipse(p+Vector2(0,32),Vector2(24,7),Color(0.05,0.07,0.04,0.14))
	draw_texture_rect(tex, Rect2(p-Vector2(38,62),Vector2(76,104)), false, Color.WHITE)
	draw_rect(Rect2(p+Vector2(-30,48),Vector2(60,18)),Color(0.98,0.93,0.78,0.91),true)
	draw_string(ThemeDB.fallback_font,p+Vector2(-27,61),label,HORIZONTAL_ALIGNMENT_CENTER,54,8,Color("#5b4736"))

func _draw_meadow_details() -> void:
	for i in range(44):
		var x := 70.0 + fmod(float(i*173), 1970.0)
		var y := 520.0 + fmod(float(i*109), 820.0)
		if _is_path_area(Vector2(x,y)):
			continue
		if Vector2(x,y).distance_to(Vector2(1415,600)) < 230.0:
			continue
		if i % 4 == 0:
			_draw_flower(Vector2(x,y), 900+i)
		else:
			_draw_grass_cluster(Vector2(x,y), i)

	for p in [Vector2(250,610),Vector2(570,690),Vector2(900,600),Vector2(340,930),Vector2(1820,650),Vector2(1880,960)]:
		_draw_ellipse(p+Vector2(0,4),Vector2(12,5),Color(0.07,0.08,0.06,0.11))
		_draw_ellipse(p,Vector2(11,7),Color(0.76,0.75,0.65,0.48))

func _draw_flower(p: Vector2, seed: int) -> void:
	var stem := Color("#5f8d43")
	draw_line(p,p+Vector2(0,-10),stem,1.5)
	var petal := Color("#f4d6b2")
	if seed % 3 == 1:
		petal = Color("#e9bed0")
	elif seed % 3 == 2:
		petal = Color("#f1e9b0")
	for a in [0.0, PI*0.5, PI, PI*1.5]:
		draw_circle(p+Vector2(0,-11)+Vector2(cos(a),sin(a))*3.2,2.3,petal)
	draw_circle(p+Vector2(0,-11),1.8,Color("#d5a74f"))

func _draw_grass_cluster(p: Vector2, seed: int) -> void:
	var col := Color(0.28,0.52,0.24,0.28)
	for i in range(3):
		var off := float(i-1)*4.0
		var sway := sin(t*0.35+float(seed+i))*1.1
		draw_line(p+Vector2(off,0),p+Vector2(off+sway,-7-float(i%2)*2.0),col,1.0)

func _draw_edge_vignette() -> void:
	var c := Color(0.18,0.27,0.14,0.035)
	draw_rect(Rect2(0,0,FarmWorld.WORLD_SIZE.x,26),c,true)
	draw_rect(Rect2(0,FarmWorld.WORLD_SIZE.y-26,FarmWorld.WORLD_SIZE.x,26),c,true)
	draw_rect(Rect2(0,0,26,FarmWorld.WORLD_SIZE.y),c,true)
	draw_rect(Rect2(FarmWorld.WORLD_SIZE.x-26,0,26,FarmWorld.WORLD_SIZE.y),c,true)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points,color)
