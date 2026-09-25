extends Node2D
class_name FarmWorld

const TILE_SIZE := 64
const COLS := 14
const ROWS := 8
const ORIGIN := Vector2(110, 470)
const WORLD_SIZE := Vector2(2304, 1536)

const HOUSE_RECT := Rect2(150, 120, 430, 230)
const STORE_RECT := Rect2(1580, 130, 400, 250)
const TOWN_HALL_RECT := Rect2(1650, 820, 430, 260)
const BARN_RECT := Rect2(220, 1110, 430, 250)

const HOUSE_DOOR := Vector2(365, 370)
const STORE_DOOR := Vector2(1780, 400)
const MAYOR_SPOT := Vector2(1450, 920)
const LINA_SPOT := Vector2(1160, 1030)
const MARNIE_SPOT := Vector2(1260, 690)
const SHIPPING_BIN := Vector2(1080, 680)

var cells: Dictionary = {}
var current_day := 1
var weather := "Sunny"
var time_of_day := 360
var npc_phase := 0.0

var crop_defs := {
	"turnip": {"days": 3, "leaf": Color("#58b947"), "fruit": Color("#e9e7da")},
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
	shape.size = rect.size
	shape_node.shape = shape
	body.position = rect.position + rect.size * 0.5
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
	if pos.distance_to(mayor) < 85.0:
		return {"type": "npc", "id": "mayor", "name": "Mayor Rowan"}
	if pos.distance_to(lina) < 85.0:
		return {"type": "npc", "id": "lina", "name": "Lina"}
	if pos.distance_to(marnie) < 85.0:
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
	_draw_building(HOUSE_RECT, Color("#d9c18f"), Color("#9e5c3c"), "FARMHOUSE")
	_draw_building(STORE_RECT, Color("#e2bf78"), Color("#7f4f36"), "GENERAL STORE")
	_draw_building(TOWN_HALL_RECT, Color("#d9d2c3"), Color("#6f596b"), "TOWN HALL")
	_draw_building(BARN_RECT, Color("#b95445"), Color("#7a3a31"), "BARN")
	_draw_shipping_bin()
	_draw_decorations()
	_draw_npc(_npc_position(MAYOR_SPOT, 0.0), Color("#754c8c"), "Rowan")
	_draw_npc(_npc_position(LINA_SPOT, 1.7), Color("#4b87a8"), "Lina")
	_draw_npc(_npc_position(MARNIE_SPOT, 3.2), Color("#b86c6f"), "Marnie")
	_draw_daylight_overlay()

func _draw_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#79b85d"), true)
	for y in range(0, int(WORLD_SIZE.y), 96):
		for x in range(0, int(WORLD_SIZE.x), 96):
			if (int(x / 96) + int(y / 96)) % 2 == 0:
				draw_circle(Vector2(x + 38, y + 42), 2.4, Color("#6bab52"))
			draw_line(Vector2(x + 62, y + 70), Vector2(x + 66, y + 61), Color("#5d9f49"), 2)

func _draw_paths() -> void:
	var path := Color("#d6bb86")
	draw_rect(Rect2(0, 390, WORLD_SIZE.x, 92), path, true)
	draw_rect(Rect2(1010, 390, 100, 900), path, true)
	draw_rect(Rect2(1010, 790, 1080, 96), path, true)
	draw_rect(Rect2(1060, 1110, 1010, 84), path, true)
	for x in range(0, int(WORLD_SIZE.x), 70):
		draw_circle(Vector2(x + 24, 434), 3.0, Color("#bca16f"))

func _draw_water() -> void:
	draw_rect(Rect2(2120, 0, 184, WORLD_SIZE.y), Color("#50a8cb"), true)
	for y in range(30, int(WORLD_SIZE.y), 70):
		draw_line(Vector2(2140, y), Vector2(2268, y + 10), Color(0.55,0.88,0.95,0.55), 3)
	draw_circle(Vector2(1360, 560), 150, Color("#4fa7c8"))
	draw_circle(Vector2(1360, 560), 126, Color("#5ab4d1"))
	draw_circle(Vector2(1310, 520), 11, Color("#76b858"))
	draw_circle(Vector2(1395, 600), 14, Color("#76b858"))

func _draw_farm() -> void:
	draw_rect(Rect2(ORIGIN - Vector2(12,12), Vector2(COLS*TILE_SIZE+24, ROWS*TILE_SIZE+24)), Color("#4f8f42"), true)
	for y in range(ROWS):
		for x in range(COLS):
			var c := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(x*TILE_SIZE, y*TILE_SIZE), Vector2(TILE_SIZE-3, TILE_SIZE-3))
			var data: Dictionary = get_cell(c)
			var base := Color("#78b75a") if (x+y)%2 == 0 else Color("#73af55")
			if bool(data["tilled"]):
				base = Color("#875d38")
			if bool(data["watered"]):
				base = Color("#60462f")
			draw_rect(rect, base, true)
			if bool(data["tilled"]):
				for row in 3:
					draw_line(rect.position + Vector2(8, 16 + row*16), rect.position + Vector2(rect.size.x-8, 16 + row*16), Color(0.24,0.16,0.10,0.28), 2)
			var crop := String(data["crop"])
			if crop != "":
				_draw_crop(rect.get_center(), crop, int(data["stage"]), int(data["age"]))

func _draw_crop(center: Vector2, crop: String, stage: int, age: int) -> void:
	var def: Dictionary = crop_defs[crop]
	var needed := int(def["days"])
	var maturity := clampf(float(age) / float(needed), 0.0, 1.0)
	var s: float = 7.0 + 13.0 * maxf(maturity, float(stage) / 3.0)
	draw_line(center + Vector2(0, 18), center + Vector2(0, -s), Color("#2d6b35"), 5)
	draw_circle(center + Vector2(-s*0.55,-s*0.20), s*0.48, def["leaf"])
	draw_circle(center + Vector2(s*0.55,-s*0.24), s*0.48, def["leaf"].lightened(0.08))
	if maturity >= 1.0:
		if crop == "corn":
			draw_rect(Rect2(center + Vector2(-5,-4), Vector2(10,25)), def["fruit"], true)
		elif crop == "carrot":
			var pts := PackedVector2Array([center+Vector2(-10,7), center+Vector2(10,7), center+Vector2(0,25)])
			draw_colored_polygon(pts, def["fruit"])
		else:
			draw_circle(center + Vector2(0, 10), 13, def["fruit"])
			draw_circle(center + Vector2(0, 13), 5, Color("#b98ac9"))

func _draw_building(rect: Rect2, wall: Color, roof: Color, title: String) -> void:
	draw_rect(rect, wall, true)
	var roof_pts := PackedVector2Array([
		rect.position + Vector2(-20, 18),
		rect.position + Vector2(rect.size.x * 0.5, -55),
		rect.position + Vector2(rect.size.x + 20, 18),
		rect.position + Vector2(rect.size.x, 72),
		rect.position + Vector2(0, 72)
	])
	draw_colored_polygon(roof_pts, roof)
	var door := Rect2(rect.position + Vector2(rect.size.x*0.5-30, rect.size.y-78), Vector2(60,78))
	draw_rect(door, Color("#694b37"), true)
	draw_circle(door.position + Vector2(48,39), 4, Color("#e9c56d"))
	for i in 2:
		var wp := rect.position + Vector2(62 + i*(rect.size.x-124), 112)
		draw_rect(Rect2(wp, Vector2(62,52)), Color("#9bd1e0"), true)
		draw_line(wp+Vector2(31,0), wp+Vector2(31,52), Color("#e7e2ce"), 4)
		draw_line(wp+Vector2(0,26), wp+Vector2(62,26), Color("#e7e2ce"), 4)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(28, 103), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#4b3a2f"))

func _draw_shipping_bin() -> void:
	draw_rect(Rect2(SHIPPING_BIN-Vector2(38,28), Vector2(76,56)), Color("#8a5d36"), true)
	draw_rect(Rect2(SHIPPING_BIN-Vector2(44,34), Vector2(88,12)), Color("#644328"), true)
	draw_string(ThemeDB.fallback_font, SHIPPING_BIN + Vector2(-34,48), "SHIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#3e3228"))

func _draw_decorations() -> void:
	for p in [Vector2(75,90),Vector2(690,120),Vector2(900,220),Vector2(2030,470),Vector2(790,1220),Vector2(1460,1250),Vector2(2020,1330)]:
		_draw_tree(p)
	for p in [Vector2(930,1030),Vector2(1500,690),Vector2(1870,650),Vector2(760,410)]:
		draw_circle(p, 24, Color("#5d9945"))
		draw_circle(p+Vector2(-17,-3), 18, Color("#66aa4e"))
		draw_circle(p+Vector2(16,-8), 19, Color("#70b657"))
	for x in range(1160, 2050, 180):
		draw_circle(Vector2(x, 760), 5, Color("#f2d85a"))
		draw_circle(Vector2(x+8, 766), 4, Color("#f4a7bd"))

func _draw_tree(p: Vector2) -> void:
	draw_rect(Rect2(p+Vector2(-9,25),Vector2(18,48)), Color("#765039"), true)
	draw_circle(p, 43, Color("#2f783d"))
	draw_circle(p+Vector2(-28,9), 30, Color("#3d8d48"))
	draw_circle(p+Vector2(25,7), 32, Color("#44994d"))
	draw_circle(p+Vector2(4,-28), 29, Color("#4ba254"))

func _npc_position(base: Vector2, phase_offset: float) -> Vector2:
	return base + Vector2(sin(npc_phase * 0.55 + phase_offset) * 34.0, cos(npc_phase * 0.42 + phase_offset) * 18.0)

func _draw_npc(p: Vector2, shirt: Color, label: String) -> void:
	_draw_custom_ellipse(p+Vector2(0,18), Vector2(22,8), Color(0,0,0,0.18))
	draw_rect(Rect2(p+Vector2(-14,-8), Vector2(28,34)), shirt, true)
	draw_circle(p+Vector2(0,-22), 14, Color("#efc29e"))
	draw_arc(p+Vector2(0,-27), 14, PI, TAU, 16, Color("#51382d"), 6)
	draw_string(ThemeDB.fallback_font, p+Vector2(-28,48), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#2e342b"))

func _draw_custom_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(points, color)

func _draw_daylight_overlay() -> void:
	var hour := float(time_of_day) / 60.0
	var alpha := 0.0
	if hour >= 19.0:
		alpha = clampf((hour - 19.0) / 4.0, 0.0, 0.48)
	elif hour < 7.0:
		alpha = clampf((7.0 - hour) / 1.5, 0.0, 0.35)
	if alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(0.08,0.12,0.26,alpha), true)
