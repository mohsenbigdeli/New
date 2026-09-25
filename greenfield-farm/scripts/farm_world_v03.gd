extends Node2D
class_name FarmWorld

const TILE_SIZE := 64
const COLS := 14
const ROWS := 8
const ORIGIN := Vector2(110, 470)
const WORLD_SIZE := Vector2(2304, 1536)

const HOUSE_RECT := Rect2(150, 120, 430, 260)
const STORE_RECT := Rect2(1580, 120, 400, 260)
const TOWN_HALL_RECT := Rect2(1640, 815, 430, 280)
const BARN_RECT := Rect2(220, 1090, 430, 260)

const HOUSE_DOOR := Vector2(365, 386)
const STORE_DOOR := Vector2(1780, 392)
const MAYOR_SPOT := Vector2(1450, 920)
const LINA_SPOT := Vector2(1160, 1030)
const MARNIE_SPOT := Vector2(1260, 690)
const SHIPPING_BIN := Vector2(1080, 680)

const GRASS_TEX: Texture2D = preload("res://assets/art/grass_tile.svg")
const PATH_TEX: Texture2D = preload("res://assets/art/path_tile.svg")
const SOIL_TEX: Texture2D = preload("res://assets/art/soil_tile.svg")
const SOIL_WET_TEX: Texture2D = preload("res://assets/art/soil_wet_tile.svg")
const WATER_TEX: Texture2D = preload("res://assets/art/water_tile.svg")
const TREE_TEX: Texture2D = preload("res://assets/art/tree.svg")
const FARMHOUSE_TEX: Texture2D = preload("res://assets/art/farmhouse.svg")
const STORE_TEX: Texture2D = preload("res://assets/art/store.svg")
const BARN_TEX: Texture2D = preload("res://assets/art/barn.svg")
const TOWNHALL_TEX: Texture2D = preload("res://assets/art/townhall.svg")

var cells: Dictionary = {}
var current_day := 1
var weather := "Sunny"
var time_of_day := 360
var npc_phase := 0.0

var crop_defs := {
	"turnip": {"days": 3, "leaf": Color("#58b947"), "fruit": Color("#ece9dd")},
	"carrot": {"days": 4, "leaf": Color("#3f9f48"), "fruit": Color("#ee8a2d")},
	"corn": {"days": 6, "leaf": Color("#67ad45"), "fruit": Color("#f2c84b")}
}

func _ready() -> void:
	_add_building_collider(HOUSE_RECT)
	_add_building_collider(STORE_RECT)
	_add_building_collider(TOWN_HALL_RECT)
	_add_building_collider(BARN_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	npc_phase += delta
	queue_redraw()

func _add_building_collider(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size * Vector2(0.90, 0.70)
	shape_node.shape = shape
	body.position = rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.62)
	body.add_child(shape_node)
	add_child(body)

func world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - ORIGIN
	return Vector2i(floor(local.x / TILE_SIZE), floor(local.y / TILE_SIZE))

func cell_to_world(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell.x * TILE_SIZE + TILE_SIZE * 0.5, cell.y * TILE_SIZE + TILE_SIZE * 0.5)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < COLS and cell.y < ROWS

func get_cell(cell: Vector2i) -> Dictionary:
	if not cells.has(cell):
		cells[cell] = {"tilled": false, "watered": false, "crop": "", "stage": 0, "age": 0}
	return cells[cell]

func till(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		return false
	var data: Dictionary = get_cell(cell)
	if bool(data["tilled"]):
		return false
	data["tilled"] = true
	cells[cell] = data
	queue_redraw()
	return true

func plant(cell: Vector2i, crop: String) -> bool:
	if not is_valid_cell(cell) or not crop_defs.has(crop):
		return false
	var data: Dictionary = get_cell(cell)
	if not bool(data["tilled"]) or String(data["crop"]) != "":
		return false
	data["crop"] = crop
	data["stage"] = 0
	data["age"] = 0
	cells[cell] = data
	queue_redraw()
	return true

func water(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		return false
	var data: Dictionary = get_cell(cell)
	if not bool(data["tilled"]) or bool(data["watered"]):
		return false
	data["watered"] = true
	cells[cell] = data
	queue_redraw()
	return true

func harvest(cell: Vector2i) -> String:
	if not is_valid_cell(cell):
		return ""
	var data: Dictionary = get_cell(cell)
	var crop := String(data["crop"])
	if crop == "" or not crop_defs.has(crop):
		return ""
	if int(data["age"]) < int(crop_defs[crop]["days"]):
		return ""
	data["crop"] = ""
	data["stage"] = 0
	data["age"] = 0
	data["watered"] = false
	cells[cell] = data
	queue_redraw()
	return crop

func next_day(new_weather: String) -> void:
	current_day += 1
	weather = new_weather
	for key in cells.keys():
		var data: Dictionary = cells[key]
		if String(data["crop"]) != "" and bool(data["watered"]):
			data["age"] = int(data["age"]) + 1
			var crop := String(data["crop"])
			var needed := int(crop_defs[crop]["days"])
			data["stage"] = clampi(int(round(float(data["age"]) / float(needed) * 3.0)), 0, 3)
		data["watered"] = (weather == "Rain") and bool(data["tilled"])
		cells[key] = data
	queue_redraw()

func set_time(minute: int) -> void:
	time_of_day = minute
	queue_redraw()

func get_interaction_near(pos: Vector2) -> Dictionary:
	if pos.distance_to(STORE_DOOR) < 95.0:
		return {"type": "shop", "name": "Willow General Store"}
	if pos.distance_to(HOUSE_DOOR) < 95.0:
		return {"type": "home", "name": "Farmhouse"}
	if pos.distance_to(SHIPPING_BIN) < 80.0:
		return {"type": "shipping", "name": "Shipping Bin"}
	var mayor := _npc_position(MAYOR_SPOT, 0.0)
	var lina := _npc_position(LINA_SPOT, 1.7)
	var marnie := _npc_position(MARNIE_SPOT, 3.2)
	if pos.distance_to(mayor) < 92.0:
		return {"type": "npc", "id": "mayor", "name": "Mayor Rowan"}
	if pos.distance_to(lina) < 92.0:
		return {"type": "npc", "id": "lina", "name": "Lina"}
	if pos.distance_to(marnie) < 92.0:
		return {"type": "npc", "id": "marnie", "name": "Marnie"}
	return {}

func get_save_data() -> Dictionary:
	var serialized := {}
	for key in cells.keys():
		serialized["%d,%d" % [key.x, key.y]] = cells[key]
	return {"day": current_day, "weather": weather, "cells": serialized}

func load_save_data(data: Dictionary) -> void:
	current_day = int(data.get("day", 1))
	weather = String(data.get("weather", "Sunny"))
	cells.clear()
	var saved_cells: Dictionary = data.get("cells", {})
	for key in saved_cells.keys():
		var parts := String(key).split(",")
		if parts.size() == 2:
			cells[Vector2i(int(parts[0]), int(parts[1]))] = saved_cells[key]
	queue_redraw()

func _draw() -> void:
	_draw_ground()
	_draw_paths()
	_draw_water()
	_draw_farm()
	_draw_world_props()
	_draw_building_shadow(HOUSE_RECT)
	_draw_building_shadow(STORE_RECT)
	_draw_building_shadow(TOWN_HALL_RECT)
	_draw_building_shadow(BARN_RECT)
	draw_texture_rect(FARMHOUSE_TEX, HOUSE_RECT, false)
	draw_texture_rect(STORE_TEX, STORE_RECT, false)
	draw_texture_rect(TOWNHALL_TEX, TOWN_HALL_RECT, false)
	draw_texture_rect(BARN_TEX, BARN_RECT, false)
	_draw_shipping_bin()
	_draw_npc(_npc_position(MAYOR_SPOT, 0.0), Color("#76508f"), Color("#d8b36e"), "Rowan")
	_draw_npc(_npc_position(LINA_SPOT, 1.7), Color("#4c8cae"), Color("#6a4438"), "Lina")
	_draw_npc(_npc_position(MARNIE_SPOT, 3.2), Color("#bd6b72"), Color("#9b6a38"), "Marnie")
	_draw_weather_fx()
	_draw_daylight_overlay()

func _draw_ground() -> void:
	for y in range(0, int(WORLD_SIZE.y), TILE_SIZE):
		for x in range(0, int(WORLD_SIZE.x), TILE_SIZE):
			draw_texture_rect(GRASS_TEX, Rect2(x, y, TILE_SIZE, TILE_SIZE), false)
	# larger meadow color patches break visible repetition
	for p in [Vector2(720,760),Vector2(1530,500),Vector2(1810,1270),Vector2(570,1390)]:
		draw_circle(p, 120, Color(0.20,0.42,0.17,0.05))

func _draw_paths() -> void:
	_tile_texture_in_rect(PATH_TEX, Rect2(0, 392, WORLD_SIZE.x, 92), 64)
	_tile_texture_in_rect(PATH_TEX, Rect2(1016, 392, 102, 892), 64)
	_tile_texture_in_rect(PATH_TEX, Rect2(1016, 792, 1076, 90), 64)
	_tile_texture_in_rect(PATH_TEX, Rect2(1060, 1112, 1010, 84), 64)
	# irregular grass tufts soften the road edges
	for x in range(18, 2080, 118):
		_draw_grass_tuft(Vector2(x, 389 + (x%3)*2))
		_draw_grass_tuft(Vector2(x+38, 486 - (x%2)*2))

func _draw_water() -> void:
	# east river with sandy bank
	draw_rect(Rect2(2098, 0, 22, WORLD_SIZE.y), Color("#c9ae78"), true)
	_tile_texture_in_rect(WATER_TEX, Rect2(2120, 0, 184, WORLD_SIZE.y), 64)
	# pond with layered shoreline
	draw_circle(Vector2(1360, 560), 176, Color("#d2b77f"))
	draw_circle(Vector2(1360, 560), 162, Color("#7aa765"))
	draw_circle(Vector2(1360, 560), 152, Color("#4ea4c6"))
	for y in range(430, 690, 64):
		for x in range(1230, 1490, 64):
			var p := Vector2(x + 32, y + 32)
			if p.distance_to(Vector2(1360, 560)) < 132.0:
				draw_texture_rect(WATER_TEX, Rect2(x, y, 64, 64), false)
	draw_circle(Vector2(1305, 520), 13, Color("#78b958"))
	draw_circle(Vector2(1400, 610), 15, Color("#78b958"))
	draw_circle(Vector2(1404, 606), 4, Color("#e8b2d2"))

func _draw_farm() -> void:
	# field is continuous grass; only worked tiles are drawn, removing the old grid look
	var farm_rect := Rect2(ORIGIN, Vector2(COLS*TILE_SIZE, ROWS*TILE_SIZE))
	draw_rect(Rect2(farm_rect.position-Vector2(6,6), farm_rect.size+Vector2(12,12)), Color(0.22,0.45,0.18,0.18), true)
	for y in range(ROWS):
		for x in range(COLS):
			var c := Vector2i(x, y)
			var data: Dictionary = get_cell(c)
			if not bool(data["tilled"]):
				continue
			var rect := Rect2(ORIGIN + Vector2(x*TILE_SIZE + 3, y*TILE_SIZE + 3), Vector2(TILE_SIZE-6, TILE_SIZE-6))
			var tex := SOIL_WET_TEX if bool(data["watered"]) else SOIL_TEX
			draw_texture_rect(tex, rect, false)
			var crop := String(data["crop"])
			if crop != "":
				_draw_crop(rect.get_center(), crop, int(data["stage"]), int(data["age"]))
	_draw_farm_fence()

func _draw_crop(center: Vector2, crop: String, stage: int, age: int) -> void:
	var def: Dictionary = crop_defs[crop]
	var needed := int(def["days"])
	var maturity := clampf(float(age) / float(needed), 0.0, 1.0)
	var growth := maxf(maturity, float(stage) / 3.0)
	var s := 0.46 + growth * 0.72
	var leaf: Color = def["leaf"]
	var fruit: Color = def["fruit"]
	_draw_pixel_ellipse(center + Vector2(0,16), Vector2(13*s,5*s), Color(0.10,0.07,0.04,0.22))
	if growth < 0.28:
		draw_line(center+Vector2(0,9), center+Vector2(0,-7), Color("#2e7337"), 4)
		draw_circle(center+Vector2(-5,-5), 5, leaf)
		draw_circle(center+Vector2(5,-7), 5, leaf.lightened(0.08))
		return
	if crop == "corn":
		draw_rect(Rect2(center + Vector2(-3,-26*s), Vector2(6,44*s)), Color("#397a42"), true)
		draw_colored_polygon(PackedVector2Array([center+Vector2(-3,-6),center+Vector2(-19*s,-18*s),center+Vector2(-6*s,-21*s)]), leaf)
		draw_colored_polygon(PackedVector2Array([center+Vector2(3,-1),center+Vector2(20*s,-14*s),center+Vector2(7*s,-18*s)]), leaf.lightened(0.09))
		if maturity >= 1.0:
			draw_rect(Rect2(center+Vector2(4,-8),Vector2(9,23)), fruit, true)
			draw_rect(Rect2(center+Vector2(7,-5),Vector2(3,15)), Color("#ffe07b"), true)
	else:
		var stem_h := 18.0*s
		draw_rect(Rect2(center+Vector2(-2,-stem_h),Vector2(4,stem_h+8)), Color("#2e6f37"), true)
		draw_colored_polygon(PackedVector2Array([center+Vector2(-1,-stem_h+5),center+Vector2(-18*s,-11*s),center+Vector2(-7*s,2)]), leaf)
		draw_colored_polygon(PackedVector2Array([center+Vector2(1,-stem_h+3),center+Vector2(18*s,-13*s),center+Vector2(7*s,3)]), leaf.lightened(0.10))
		if maturity >= 1.0:
			if crop == "carrot":
				draw_colored_polygon(PackedVector2Array([center+Vector2(-9,6),center+Vector2(9,6),center+Vector2(0,28)]), fruit)
				draw_line(center+Vector2(0,10), center+Vector2(0,22), Color("#f6b260"), 3)
			else:
				draw_circle(center+Vector2(0,12), 13, fruit)
				draw_rect(Rect2(center+Vector2(-5,7),Vector2(10,5)), Color("#cdb9df"), true)

func _draw_farm_fence() -> void:
	var left := ORIGIN.x - 30
	var top := ORIGIN.y - 28
	var right := ORIGIN.x + COLS*TILE_SIZE + 28
	var bottom := ORIGIN.y + ROWS*TILE_SIZE + 28
	# long rails first
	draw_line(Vector2(left,top),Vector2(right,top),Color("#8a6342"),5)
	draw_line(Vector2(left,bottom),Vector2(right,bottom),Color("#8a6342"),5)
	draw_line(Vector2(left,top),Vector2(left,bottom),Color("#8a6342"),5)
	draw_line(Vector2(right,top),Vector2(right,bottom-92),Color("#8a6342"),5)
	for x in range(int(left), int(right)+1, 96):
		_draw_fence_post(Vector2(x,top))
		_draw_fence_post(Vector2(x,bottom))
	for y in range(int(top), int(bottom)+1, 96):
		_draw_fence_post(Vector2(left,y))
		if y < int(bottom)-92:
			_draw_fence_post(Vector2(right,y))

func _draw_fence_post(p: Vector2) -> void:
	draw_rect(Rect2(p-Vector2(5,15),Vector2(10,30)), Color("#6d4b32"), true)
	draw_rect(Rect2(p-Vector2(7,13),Vector2(14,6)), Color("#a77a4f"), true)

func _draw_world_props() -> void:
	var trees := [Vector2(45,35),Vector2(700,28),Vector2(825,130),Vector2(1965,405),Vector2(720,1170),Vector2(1435,1210),Vector2(1960,1280),Vector2(70,1250)]
	for p in trees:
		draw_texture_rect(TREE_TEX, Rect2(p,Vector2(144,180)), false)
	for p in [Vector2(900,1010),Vector2(1490,670),Vector2(1870,640),Vector2(770,382),Vector2(1140,1280),Vector2(590,940)]:
		_draw_bush(p)
	for p in [Vector2(952,945),Vector2(1560,650),Vector2(1820,760),Vector2(690,1010),Vector2(530,1420),Vector2(1480,1330)]:
		_draw_rock(p)
	for p in [Vector2(1180,744),Vector2(1260,756),Vector2(1510,748),Vector2(1890,736),Vector2(660,360),Vector2(850,350)]:
		_draw_flower_cluster(p)
	_draw_bench(Vector2(1500,1030))
	_draw_bench(Vector2(1880,700))
	_draw_sign(Vector2(940,430))

func _draw_grass_tuft(p: Vector2) -> void:
	for i in range(3):
		draw_line(p+Vector2(i*4,0), p+Vector2(i*4-2,-8-i*2), Color("#4f9147"), 2)

func _draw_bush(p: Vector2) -> void:
	_draw_pixel_ellipse(p+Vector2(0,18),Vector2(28,7),Color(0,0,0,0.12))
	draw_circle(p+Vector2(-16,0),18,Color("#4d9348"))
	draw_circle(p+Vector2(13,-5),20,Color("#62a956"))
	draw_circle(p+Vector2(0,-15),19,Color("#6cb55d"))
	draw_circle(p+Vector2(4,-9),4,Color("#f2cb70"))

func _draw_rock(p: Vector2) -> void:
	_draw_pixel_ellipse(p+Vector2(2,11),Vector2(21,6),Color(0,0,0,0.13))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-18,8),p+Vector2(-11,-10),p+Vector2(5,-17),p+Vector2(19,-4),p+Vector2(16,11)]),Color("#8d9187"))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-9,-7),p+Vector2(4,-13),p+Vector2(10,-6),p+Vector2(-2,-2)]),Color("#b5b7aa"))

func _draw_flower_cluster(p: Vector2) -> void:
	for i in range(4):
		var q := p + Vector2((i%2)*11,(i/2)*10)
		draw_line(q+Vector2(0,3),q+Vector2(0,11),Color("#3f7f42"),2)
		draw_circle(q,4,Color("#f6d36f") if i%2==0 else Color("#f1a8c1"))

func _draw_bench(p: Vector2) -> void:
	draw_rect(Rect2(p,Vector2(76,10)),Color("#80573b"),true)
	draw_rect(Rect2(p+Vector2(4,13),Vector2(68,8)),Color("#9c6b45"),true)
	draw_rect(Rect2(p+Vector2(10,20),Vector2(7,18)),Color("#64452f"),true)
	draw_rect(Rect2(p+Vector2(59,20),Vector2(7,18)),Color("#64452f"),true)

func _draw_sign(p: Vector2) -> void:
	draw_rect(Rect2(p+Vector2(-3,0),Vector2(6,35)),Color("#694a31"),true)
	draw_rect(Rect2(p+Vector2(-28,-20),Vector2(56,30)),Color("#b18452"),true)
	draw_rect(Rect2(p+Vector2(-24,-16),Vector2(48,22)),Color("#cba36b"),true)
	draw_string(ThemeDB.fallback_font,p+Vector2(-18,1),"TOWN",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#493523"))

func _draw_building_shadow(rect: Rect2) -> void:
	_draw_pixel_ellipse(rect.position+Vector2(rect.size.x*0.5,rect.size.y+12),Vector2(rect.size.x*0.46,14),Color(0,0,0,0.15))

func _draw_shipping_bin() -> void:
	_draw_pixel_ellipse(SHIPPING_BIN+Vector2(0,34),Vector2(45,9),Color(0,0,0,0.15))
	draw_rect(Rect2(SHIPPING_BIN-Vector2(42,31),Vector2(84,62)),Color("#805334"),true)
	draw_rect(Rect2(SHIPPING_BIN-Vector2(47,37),Vector2(94,13)),Color("#553b29"),true)
	draw_rect(Rect2(SHIPPING_BIN-Vector2(32,18),Vector2(64,6)),Color("#a46f44"),true)
	draw_string(ThemeDB.fallback_font,SHIPPING_BIN+Vector2(-34,52),"SHIP",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#403328"))

func _npc_position(base: Vector2, phase_offset: float) -> Vector2:
	return base + Vector2(sin(npc_phase*0.55+phase_offset)*24.0,cos(npc_phase*0.42+phase_offset)*10.0)

func _draw_npc(p: Vector2, shirt: Color, hair: Color, label: String) -> void:
	var bob := sin(npc_phase*3.0+p.x*0.01)*1.5
	_draw_pixel_ellipse(p+Vector2(0,29),Vector2(24,8),Color(0,0,0,0.18))
	draw_rect(Rect2(p+Vector2(-15,-5+bob),Vector2(30,35)),shirt,true)
	draw_rect(Rect2(p+Vector2(-13,26+bob),Vector2(9,18)),Color("#4a5570"),true)
	draw_rect(Rect2(p+Vector2(4,26+bob),Vector2(9,18)),Color("#4a5570"),true)
	draw_rect(Rect2(p+Vector2(-21,1+bob),Vector2(7,21)),Color("#efc39e"),true)
	draw_rect(Rect2(p+Vector2(14,1+bob),Vector2(7,21)),Color("#efc39e"),true)
	draw_rect(Rect2(p+Vector2(-16,-36+bob),Vector2(32,31)),Color("#efc39e"),true)
	draw_rect(Rect2(p+Vector2(-18,-42+bob),Vector2(36,12)),hair,true)
	draw_rect(Rect2(p+Vector2(-13,-45+bob),Vector2(26,7)),hair.lightened(0.06),true)
	draw_rect(Rect2(p+Vector2(-8,-23+bob),Vector2(4,4)),Color("#2f2925"),true)
	draw_rect(Rect2(p+Vector2(5,-23+bob),Vector2(4,4)),Color("#2f2925"),true)
	# label badge improves readability
	draw_rect(Rect2(p+Vector2(-34,52),Vector2(68,21)),Color(0.12,0.16,0.11,0.62),true)
	draw_string(ThemeDB.fallback_font,p+Vector2(-28,68),label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#f5efd9"))

func _draw_pixel_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU*float(i)/24.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)

func _tile_texture_in_rect(texture: Texture2D, rect: Rect2, step: int) -> void:
	for y in range(int(rect.position.y),int(rect.end.y),step):
		for x in range(int(rect.position.x),int(rect.end.x),step):
			var w := minf(float(step),rect.end.x-float(x))
			var h := minf(float(step),rect.end.y-float(y))
			if w > 0.0 and h > 0.0:
				draw_texture_rect(texture,Rect2(float(x),float(y),w,h),false)

func _draw_weather_fx() -> void:
	if weather == "Cloudy":
		draw_rect(Rect2(Vector2.ZERO,WORLD_SIZE),Color(0.42,0.49,0.52,0.07),true)
	elif weather == "Rain":
		draw_rect(Rect2(Vector2.ZERO,WORLD_SIZE),Color(0.18,0.27,0.38,0.10),true)
		var fall := fmod(npc_phase*220.0,80.0)
		for y in range(-80,int(WORLD_SIZE.y),80):
			for x in range(20,int(WORLD_SIZE.x),120):
				var rp := Vector2(float(x)+fmod(float(y),70.0),float(y)+fall)
				draw_line(rp,rp+Vector2(-7,18),Color(0.72,0.86,0.96,0.42),2.0)

func _draw_daylight_overlay() -> void:
	var hour := float(time_of_day)/60.0
	var alpha := 0.0
	if hour >= 19.0:
		alpha = clampf((hour-19.0)/4.0,0.0,0.43)
	elif hour < 7.0:
		alpha = clampf((7.0-hour)/4.0,0.0,0.36)
	if alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO,WORLD_SIZE),Color(0.09,0.12,0.25,alpha),true)
