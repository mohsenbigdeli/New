extends Node2D
class_name FarmMineInterior

const ROOM_SIZE := Vector2(1280,720)
const SPAWN := Vector2(640,610)

var active := false
var glow_time := 0.0

func _ready() -> void:
	visible = false
	z_index = -2

func set_active(value: bool) -> void:
	active = value
	visible = value
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	glow_time += delta
	queue_redraw()

func get_interaction(pos: Vector2) -> Dictionary:
	if not active:
		return {}
	if pos.distance_to(Vector2(640,655)) < 90.0:
		return {"type":"mine_exit", "name":"Leave Mine"}
	if pos.distance_to(Vector2(1120,535)) < 95.0:
		return {"type":"mine_sign", "name":"Read miner's note"}
	return {}

func _draw() -> void:
	if not active:
		return
	# cave shell
	draw_rect(Rect2(0,0,1280,720),Color("#100f12"),true)
	draw_rect(Rect2(70,55,1140,610),Color("#2a292d"),true)
	# rough stone floor
	for y in range(80,650,64):
		for x in range(92,1190,72):
			var shade := 0.02 * float((x/72 + y/64 as int) % 3)
			draw_circle(Vector2(x,y),27,Color(0.25+shade,0.24+shade,0.27+shade,1.0))
	# walls and ledges
	draw_rect(Rect2(72,56,1136,48),Color("#1d1c20"),true)
	draw_rect(Rect2(72,605,1136,58),Color("#1d1b1c"),true)
	for x in range(110,1180,120):
		draw_circle(Vector2(x,94),34,Color("#353238"))
	# mine tracks
	draw_line(Vector2(170,555),Vector2(1080,555),Color("#6c513d"),9)
	draw_line(Vector2(170,596),Vector2(1080,596),Color("#6c513d"),9)
	for x in range(180,1080,58):
		draw_line(Vector2(x,542),Vector2(x,608),Color("#8a684b"),7)
	# exit tunnel
	draw_circle(Vector2(640,662),72,Color("#09090a"))
	draw_rect(Rect2(585,620,110,70),Color("#09090a"),true)
	# lanterns
	for p in [Vector2(170,145),Vector2(1110,145),Vector2(640,120)]:
		draw_line(p-Vector2(0,42),p-Vector2(0,12),Color("#5e4938"),5)
		draw_circle(p,13,Color("#e9b95f"))
		var a := 0.055 + sin(glow_time*2.2 + p.x)*0.012
		draw_circle(p,60,Color(1.0,0.68,0.24,a))
	# miner note board
	draw_rect(Rect2(1045,488,150,95),Color("#5b402f"),true)
	draw_rect(Rect2(1060,500,120,66),Color("#d5c39d"),true)
	draw_line(Vector2(1072,519),Vector2(1168,519),Color("#756957"),3)
	draw_line(Vector2(1072,538),Vector2(1156,538),Color("#756957"),3)
