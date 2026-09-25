extends Node2D
class_name FarmInteriors

const ROOM_SIZE := Vector2(1280, 720)
const ROOM_ORIGIN := Vector2.ZERO
const HOME_SPAWN := Vector2(640, 560)
const STORE_SPAWN := Vector2(640, 560)

var active_room := "outside"
var animation_time := 0.0

func _ready() -> void:
	visible = false
	z_index = -2
	set_process(true)

func _process(delta: float) -> void:
	animation_time += delta
	if active_room != "outside":
		queue_redraw()

func enter_room(room: String) -> Vector2:
	active_room = room
	visible = room != "outside"
	queue_redraw()
	if room == "home":
		return HOME_SPAWN
	if room == "store":
		return STORE_SPAWN
	return Vector2.ZERO

func leave_room() -> void:
	active_room = "outside"
	visible = false

func get_interaction(pos: Vector2) -> Dictionary:
	if active_room == "home":
		if pos.distance_to(Vector2(640, 648)) < 88.0:
			return {"type":"interior_exit", "name":"Leave Farmhouse"}
		if pos.distance_to(Vector2(330, 230)) < 90.0:
			return {"type":"bed", "name":"Sleep until morning"}
		if pos.distance_to(Vector2(930, 220)) < 90.0:
			return {"type":"home_note", "name":"Read farm journal"}
	elif active_room == "store":
		if pos.distance_to(Vector2(640, 648)) < 88.0:
			return {"type":"interior_exit", "name":"Leave General Store"}
		if pos.distance_to(Vector2(640, 255)) < 108.0:
			return {"type":"shop", "name":"Talk to Willow"}
		if pos.distance_to(Vector2(250, 285)) < 85.0:
			return {"type":"store_sign", "name":"Read seed guide"}
	return {}

func _draw() -> void:
	if active_room == "home":
		_draw_home()
	elif active_room == "store":
		_draw_store()

func _draw_room_shell(wall: Color, floor_a: Color, floor_b: Color) -> void:
	draw_rect(Rect2(0,0,1280,720), Color("#15110f"), true)
	draw_rect(Rect2(92,70,1096,590), wall, true)
	# wooden floor with alternating planks
	var floor_rect := Rect2(112,150,1056,490)
	draw_rect(floor_rect, floor_a, true)
	for y in range(150, 640, 34):
		var row := int((y-150)/34)
		for x in range(112 - (row%2)*52, 1168, 104):
			draw_rect(Rect2(x,y,100,30), floor_b if ((x/104 + row) as int)%2==0 else floor_a.lightened(0.04), true)
			draw_line(Vector2(x,y+31), Vector2(x+100,y+31), Color(0.16,0.10,0.07,0.23), 2.0)
	# wall trim
	draw_rect(Rect2(112,132,1056,20), Color("#6e4b35"), true)
	draw_rect(Rect2(112,632,1056,10), Color("#3b291f"), true)
	# exit door
	draw_rect(Rect2(586,592,108,68), Color("#563a28"), true)
	draw_rect(Rect2(598,604,84,56), Color("#8a5d3d"), true)
	draw_circle(Vector2(667,632), 4, Color("#e1ba68"))
	_draw_shadow(Rect2(582,654,116,13), 0.18)

func _draw_home() -> void:
	_draw_room_shell(Color("#ead7b6"), Color("#b8875e"), Color("#a97954"))
	# rug
	draw_rect(Rect2(470,360,340,150), Color("#7b3f3f"), true)
	draw_rect(Rect2(486,376,308,118), Color("#c06a58"), true)
	for x in range(500,790,36):
		draw_line(Vector2(x,382),Vector2(x+24,488),Color(1,0.85,0.55,0.15),4)
	# bed
	_draw_shadow(Rect2(198,164,270,176), 0.20)
	draw_rect(Rect2(205,156,250,168), Color("#704d35"), true)
	draw_rect(Rect2(218,171,224,133), Color("#f3e3bf"), true)
	draw_rect(Rect2(218,226,224,78), Color("#7099a0"), true)
	draw_rect(Rect2(236,181,76,34), Color("#fff4d6"), true)
	# kitchen counter and stove
	_draw_shadow(Rect2(820,150,295,112), 0.18)
	draw_rect(Rect2(822,146,294,100), Color("#8c684c"), true)
	draw_rect(Rect2(836,160,72,70), Color("#c9a36f"), true)
	draw_rect(Rect2(926,160,72,70), Color("#c9a36f"), true)
	draw_rect(Rect2(1014,158,86,74), Color("#55514d"), true)
	for p in [Vector2(1036,179),Vector2(1078,179),Vector2(1036,211),Vector2(1078,211)]:
		draw_circle(p,10,Color("#262424"))
	# dining table
	_draw_shadow(Rect2(785,382,250,116),0.16)
	draw_rect(Rect2(800,372,220,100),Color("#6f4a32"),true)
	draw_rect(Rect2(817,387,186,68),Color("#a36d43"),true)
	draw_circle(Vector2(910,421),16,Color("#d6b168"))
	# journal desk
	draw_rect(Rect2(875,176,10,0),Color.TRANSPARENT)
	draw_rect(Rect2(880,274,160,70),Color("#725039"),true)
	draw_rect(Rect2(900,285,120,42),Color("#a66f45"),true)
	draw_rect(Rect2(930,291,62,30),Color("#efe1b8"),true)
	# windows with subtle daylight shimmer
	_draw_window(Vector2(560,92), 180)
	_draw_window(Vector2(860,92), 180)
	# potted plant
	_draw_plant(Vector2(1110,555))
	# warm lamp glow
	var pulse := 0.04 + sin(animation_time*2.0)*0.01
	draw_circle(Vector2(640,282),74,Color(1.0,0.76,0.36,pulse))
	draw_circle(Vector2(640,282),12,Color("#e8c778"))

func _draw_store() -> void:
	_draw_room_shell(Color("#dfcfaa"), Color("#aa7b50"), Color("#9a6e48"))
	# counter
	_draw_shadow(Rect2(425,205,430,112),0.22)
	draw_rect(Rect2(430,194,420,104),Color("#64452f"),true)
	draw_rect(Rect2(444,207,392,72),Color("#9e7049"),true)
	draw_rect(Rect2(456,218,370,14),Color("#d0a56d"),true)
	# shopkeeper
	draw_circle(Vector2(640,157),24,Color("#e5b889"))
	draw_rect(Rect2(612,176,56,50),Color("#6d8d62"),true)
	draw_circle(Vector2(632,153),3,Color("#3c2c24"))
	draw_circle(Vector2(648,153),3,Color("#3c2c24"))
	draw_line(Vector2(633,168),Vector2(647,168),Color("#8e5945"),2)
	# shelves left and right
	_draw_shelf(Rect2(155,178,190,306), [Color("#dbc45f"),Color("#8fc15d"),Color("#d8845d")])
	_draw_shelf(Rect2(935,178,190,306), [Color("#78a6c2"),Color("#e0ad55"),Color("#b882b1")])
	# middle display crates
	for i in range(3):
		var x := 445 + i*145
		_draw_crate(Vector2(x,405), [Color("#ece3d0"),Color("#e47733"),Color("#ecc94f")][i])
	# seed guide board
	draw_rect(Rect2(170,505,180,88),Color("#5f432f"),true)
	draw_rect(Rect2(183,516,154,64),Color("#e7d6a9"),true)
	draw_line(Vector2(200,534),Vector2(318,534),Color("#8b7658"),3)
	draw_line(Vector2(200,551),Vector2(304,551),Color("#8b7658"),3)
	# windows and hanging lamps
	_draw_window(Vector2(500,92),150)
	_draw_window(Vector2(780,92),150)
	for x in [475,805]:
		draw_line(Vector2(x,92),Vector2(x,128),Color("#49352a"),4)
		draw_circle(Vector2(x,138),13,Color("#e2b965"))
		draw_circle(Vector2(x,138),48,Color(1.0,0.75,0.32,0.035))

func _draw_window(pos: Vector2, width: float) -> void:
	draw_rect(Rect2(pos.x-width*0.5,pos.y,width,54),Color("#6a4b39"),true)
	draw_rect(Rect2(pos.x-width*0.5+8,pos.y+7,width-16,40),Color("#8ec4d4"),true)
	draw_line(Vector2(pos.x,pos.y+7),Vector2(pos.x,pos.y+47),Color("#efe0bd"),4)
	draw_line(Vector2(pos.x-width*0.5+8,pos.y+27),Vector2(pos.x+width*0.5-8,pos.y+27),Color("#efe0bd"),4)

func _draw_shelf(rect: Rect2, goods: Array) -> void:
	_draw_shadow(rect.grow(8),0.18)
	draw_rect(rect,Color("#60412e"),true)
	for y in range(int(rect.position.y+25),int(rect.end.y-20),70):
		draw_rect(Rect2(rect.position.x+10,y,rect.size.x-20,10),Color("#9d6b43"),true)
		for i in range(4):
			var c: Color = goods[(i + int(y/70)) % goods.size()]
			draw_rect(Rect2(rect.position.x+20+i*39,y-29,25,27),c,true)

func _draw_crate(pos: Vector2, crop_color: Color) -> void:
	draw_rect(Rect2(pos.x-52,pos.y-35,104,70),Color("#765034"),true)
	draw_rect(Rect2(pos.x-44,pos.y-26,88,50),Color("#a87245"),true)
	for i in range(7):
		var ox := -32 + (i%4)*21
		var oy := -12 + int(i/4)*20
		draw_circle(pos+Vector2(ox,oy),10,crop_color)

func _draw_plant(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x-20,pos.y,pos.x*0+40,34),Color("#9d6040"),true)
	for v in [Vector2(-20,-18),Vector2(0,-32),Vector2(18,-20),Vector2(-4,-10)]:
		draw_circle(pos+v,19,Color("#4f8a4d"))

func _draw_shadow(rect: Rect2, alpha: float) -> void:
	draw_rect(Rect2(rect.position+Vector2(8,10),rect.size),Color(0,0,0,alpha),true)
