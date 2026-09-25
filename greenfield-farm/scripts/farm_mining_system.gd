extends Node2D
class_name FarmMiningSystem

var active := false
var rocks: Array[Dictionary] = []

const ROCK_POINTS := [
	Vector2(250,220), Vector2(470,210), Vector2(730,245), Vector2(980,220),
	Vector2(340,430), Vector2(610,420), Vector2(870,455), Vector2(1040,390)
]

func _ready() -> void:
	for i in range(ROCK_POINTS.size()):
		rocks.append({"broken":false, "variant":i % 3})
	visible = false
	z_index = 1

func set_active(value: bool) -> void:
	active = value
	visible = value
	queue_redraw()

func get_interaction(pos: Vector2) -> Dictionary:
	if not active:
		return {}
	for i in range(rocks.size()):
		if bool(rocks[i].get("broken",false)):
			continue
		if pos.distance_to(ROCK_POINTS[i]) < 78.0:
			return {"type":"mine_rock", "name":"Break rock", "index":i}
	return {}

func break_rock(index: int) -> Dictionary:
	if index < 0 or index >= rocks.size():
		return {}
	if bool(rocks[index].get("broken",false)):
		return {}
	rocks[index]["broken"] = true
	var stone: int = 1 + (randi() % 3)
	var copper: int = 1 if (randi() % 100) < 38 else 0
	if int(rocks[index].get("variant",0)) == 2 and (randi() % 100) < 45:
		copper += 1
	queue_redraw()
	return {"stone":stone, "copper":copper}

func next_day() -> void:
	for i in range(rocks.size()):
		rocks[i]["broken"] = false
	queue_redraw()

func get_save_data() -> Dictionary:
	var broken: Array = []
	for rock in rocks:
		broken.append(bool(rock.get("broken",false)))
	return {"broken":broken}

func load_save_data(data: Dictionary) -> void:
	var broken: Array = data.get("broken",[])
	for i in range(rocks.size()):
		rocks[i]["broken"] = bool(broken[i]) if i < broken.size() else false
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	for i in range(rocks.size()):
		if bool(rocks[i].get("broken",false)):
			_draw_rubble(ROCK_POINTS[i])
		else:
			_draw_rock(ROCK_POINTS[i], int(rocks[i].get("variant",0)))

func _draw_rock(pos: Vector2, variant: int) -> void:
	_draw_custom_ellipse(pos + Vector2(7,18), Vector2(43,15), Color(0,0,0,0.25))
	var base: Color = Color("#636168") if variant != 2 else Color("#70645f")
	draw_circle(pos,34,base)
	draw_circle(pos+Vector2(-20,8),20,base.darkened(0.06))
	draw_circle(pos+Vector2(18,4),24,base.lightened(0.04))
	draw_line(pos+Vector2(-14,-10),pos+Vector2(4,5),Color("#97939a"),3)
	draw_line(pos+Vector2(8,-17),pos+Vector2(18,-2),Color("#47464a"),3)
	if variant == 2:
		for p in [Vector2(-12,3),Vector2(12,-8),Vector2(19,10)]:
			draw_circle(pos+p,5,Color("#bf7650"))

func _draw_rubble(pos: Vector2) -> void:
	for p in [Vector2(-18,7),Vector2(0,11),Vector2(19,5),Vector2(-5,-3)]:
		draw_circle(pos+p,8,Color("#4e4c51"))

func _draw_custom_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		pts.append(center + Vector2(cos(a)*radii.x, sin(a)*radii.y))
	draw_colored_polygon(pts,color)
