extends Node2D
class_name FarmBarnInterior

const ROOM_SIZE := Vector2(1280, 720)
const SPAWN := Vector2(640, 568)

var animation_time := 0.0

func _ready() -> void:
	visible = false
	z_index = -2

func _process(delta: float) -> void:
	animation_time += delta
	if visible:
		queue_redraw()

func get_interaction(pos: Vector2) -> Dictionary:
	if not visible:
		return {}
	if pos.distance_to(Vector2(640, 650)) < 90.0:
		return {"type":"barn_exit", "name":"Leave Barn"}
	if pos.distance_to(Vector2(235, 255)) < 105.0:
		return {"type":"animal_ledger", "name":"Animal Ledger"}
	if pos.distance_to(Vector2(1000, 275)) < 115.0:
		return {"type":"feed_trough", "name":"Feed Animals"}
	if pos.distance_to(Vector2(1040, 510)) < 105.0:
		return {"type":"animal_products", "name":"Collect Animal Products"}
	return {}

func _draw() -> void:
	if not visible:
		return
	# dark shell and warm timber walls
	draw_rect(Rect2(0,0,1280,720), Color("#17120f"), true)
	draw_rect(Rect2(82,62,1116,604), Color("#a56d43"), true)
	draw_rect(Rect2(102,132,1076,514), Color("#c89662"), true)
	# plank floor
	for y in range(142, 646, 42):
		var row := int((y - 142) / 42)
		for x in range(102 - (row % 2) * 54, 1178, 108):
			var c := Color("#9b6844") if ((int(x / 108) + row) % 2 == 0) else Color("#a8734b")
			draw_rect(Rect2(x,y,104,38), c, true)
			draw_line(Vector2(x,y+39), Vector2(x+104,y+39), Color(0.17,0.10,0.06,0.28), 2)
	# timber beams
	for x in [126, 386, 646, 906, 1150]:
		draw_rect(Rect2(x,72,18,568), Color("#5e3d2a"), true)
	draw_rect(Rect2(96,116,1088,20), Color("#5a3827"), true)
	# hay stalls left and center
	_draw_stall(Rect2(350,190,250,230))
	_draw_stall(Rect2(650,190,250,230))
	# ledger desk
	_draw_shadow(Rect2(142,180,190,150),0.20)
	draw_rect(Rect2(150,170,176,134),Color("#6f4930"),true)
	draw_rect(Rect2(166,186,144,98),Color("#a26b43"),true)
	draw_rect(Rect2(194,205,88,58),Color("#ead9a9"),true)
	draw_line(Vector2(210,221),Vector2(266,221),Color("#7d6a4e"),3)
	draw_line(Vector2(210,239),Vector2(254,239),Color("#7d6a4e"),3)
	# feed trough
	_draw_shadow(Rect2(914,204,210,128),0.19)
	draw_rect(Rect2(924,214,190,96),Color("#65432e"),true)
	draw_rect(Rect2(938,230,162,56),Color("#8b5d3c"),true)
	for i in range(11):
		var px := 950 + (i%6)*27
		var py := 239 + int(i/6)*24
		draw_line(Vector2(px,py),Vector2(px+15,py+12),Color("#d8b35d"),5)
	# product crate
	_draw_shadow(Rect2(946,442,196,132),0.18)
	draw_rect(Rect2(958,450,172,112),Color("#6d4931"),true)
	draw_rect(Rect2(972,466,144,82),Color("#9b6943"),true)
	draw_circle(Vector2(1000,500),16,Color("#f3eee0"))
	draw_rect(Rect2(1030,483,30,38),Color("#e7ecf2"),true)
	draw_rect(Rect2(1068,478,24,43),Color("#f4f6f8"),true)
	# hay bales and tools
	for p in [Vector2(188,470),Vector2(300,500),Vector2(815,505)]:
		draw_rect(Rect2(p-Vector2(54,30),Vector2(108,60)),Color("#c99a49"),true)
		for j in range(4):
			draw_line(p+Vector2(-44+j*28,-22),p+Vector2(-36+j*28,22),Color("#e3bd63"),4)
	draw_line(Vector2(1140,360),Vector2(1140,470),Color("#6d4930"),7)
	draw_line(Vector2(1118,383),Vector2(1162,383),Color("#b9a48a"),8)
	# windows
	_draw_window(Vector2(500,78),150)
	_draw_window(Vector2(780,78),150)
	# exit door
	draw_rect(Rect2(582,586,116,80),Color("#5d3d29"),true)
	draw_rect(Rect2(596,598,88,68),Color("#8c5d3a"),true)
	draw_circle(Vector2(668,632),4,Color("#e0ba69"))
	# warm light shafts
	var pulse := 0.035 + sin(animation_time * 1.6) * 0.008
	draw_circle(Vector2(500,170),92,Color(1.0,0.80,0.46,pulse))
	draw_circle(Vector2(780,170),92,Color(1.0,0.80,0.46,pulse))

func _draw_stall(rect: Rect2) -> void:
	_draw_shadow(rect.grow(8),0.18)
	draw_rect(rect,Color("#714a31"),true)
	draw_rect(Rect2(rect.position+Vector2(12,12),rect.size-Vector2(24,24)),Color("#b67c4b"),true)
	draw_rect(Rect2(rect.position+Vector2(24,112),Vector2(rect.size.x-48,86)),Color("#d0a652"),true)
	for i in range(10):
		var x := rect.position.x + 32 + (i%5)*39
		var y := rect.position.y + 126 + int(i/5)*35
		draw_line(Vector2(x,y),Vector2(x+24,y+13),Color("#e5c16d"),4)

func _draw_window(pos: Vector2, width: float) -> void:
	draw_rect(Rect2(pos.x-width*0.5,pos.y,width,50),Color("#5e4030"),true)
	draw_rect(Rect2(pos.x-width*0.5+8,pos.y+7,width-16,36),Color("#9bc5cf"),true)
	draw_line(Vector2(pos.x,pos.y+7),Vector2(pos.x,pos.y+43),Color("#eee0bb"),4)

func _draw_shadow(rect: Rect2, alpha: float) -> void:
	draw_rect(Rect2(rect.position+Vector2(8,10),rect.size),Color(0,0,0,alpha),true)
