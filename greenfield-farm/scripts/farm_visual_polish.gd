extends Node2D
class_name FarmVisualPolish

var farm: FarmWorld
var active := true
var t := 0.0

const FLOWERS: Array[Vector2] = [
	Vector2(620,350),Vector2(690,365),Vector2(760,345),Vector2(900,515),Vector2(1160,760),Vector2(1210,780),Vector2(1510,730),Vector2(1580,750),Vector2(1820,720),Vector2(1870,745),Vector2(680,1010),Vector2(750,1030),Vector2(1460,1320),Vector2(1520,1340),Vector2(1900,1230),Vector2(1960,1260),Vector2(330,360),Vector2(430,348),Vector2(560,980),Vector2(880,1110),Vector2(1280,970),Vector2(1370,1010),Vector2(1710,1020),Vector2(2010,980)
]
const LAMPS: Array[Vector2] = [Vector2(980,430),Vector2(1110,820),Vector2(1510,820),Vector2(1900,820)]
const SMALL_ROCKS: Array[Vector2] = [Vector2(380,520),Vector2(840,540),Vector2(1180,980),Vector2(1640,980),Vector2(1780,1320),Vector2(560,1210),Vector2(940,1290)]

func setup(world: FarmWorld) -> void:
	farm = world
	z_index = 1
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	queue_redraw()

func _process(delta: float) -> void:
	if not active or not farm:
		return
	t += delta
	queue_redraw()

func _draw() -> void:
	if not active or not farm:
		return
	_draw_meadow_patches()
	_draw_path_edges()
	_draw_meadow_details()
	_draw_water_glints()
	_draw_lamps()
	_draw_chimney_smoke()
	_draw_butterflies()
	_draw_npc_portrait(_npc_pos(FarmWorld.MAYOR_SPOT,0.0),"rowan","ROWAN")
	_draw_npc_portrait(_npc_pos(FarmWorld.LINA_SPOT,1.7),"lina","LINA")
	_draw_npc_portrait(_npc_pos(FarmWorld.MARNIE_SPOT,3.2),"marnie","MARNIE")
	_draw_night_particles()

func _npc_pos(base: Vector2, phase: float) -> Vector2:
	var phase_value: float = farm.npc_phase
	return base + Vector2(sin(phase_value*0.55+phase)*24.0,cos(phase_value*0.42+phase)*10.0)

func _draw_meadow_patches() -> void:
	var patches: Array[Vector2] = [Vector2(330,590),Vector2(630,1140),Vector2(910,1000),Vector2(1320,1040),Vector2(1700,1120),Vector2(1920,560)]
	for i in range(patches.size()):
		var p: Vector2 = patches[i]
		_draw_ellipse(p,Vector2(78+float(i%3)*18,30+float(i%2)*8),Color(0.18,0.36,0.15,0.055))
		for j in range(6):
			var ang: float = float(j)*1.047 + float(i)*0.31
			var q: Vector2 = p + Vector2(cos(ang)*float(28+j*6),sin(ang)*float(12+j*3))
			draw_line(q,q+Vector2(sin(t+ang)*2.0,-8.0-float(j%3)*2.0),Color(0.20,0.42,0.19,0.50),1.6)

func _draw_path_edges() -> void:
	# Irregular stones and weeds soften the long straight roads from the base map.
	for i in range(18):
		var x: float = 86.0 + float(i)*111.0
		var y_top: float = 386.0 + float((i*7)%9)
		var y_bottom: float = 489.0 - float((i*5)%8)
		_draw_pebble(Vector2(x,y_top),i)
		if i % 2 == 0:
			_draw_tuft(Vector2(x+29.0,y_bottom),i)
	for i in range(8):
		var y: float = 520.0 + float(i)*104.0
		_draw_pebble(Vector2(1008.0+float((i%2)*7),y),i+20)
		_draw_tuft(Vector2(1121.0-float((i%3)*5),y+25.0),i+30)
	for i in range(8):
		var x2: float = 1170.0 + float(i)*108.0
		_draw_pebble(Vector2(x2,786.0+float(i%3)*5.0),i+40)

func _draw_pebble(p: Vector2, seed: int) -> void:
	var s: float = 3.0 + float(seed%3)
	_draw_ellipse(p,Vector2(s*1.6,s),Color("#8e8065aa"))
	draw_circle(p-Vector2(1.0,1.0),maxf(1.0,s*0.35),Color(0.86,0.80,0.66,0.35))

func _draw_tuft(p: Vector2, seed: int) -> void:
	for j in range(4):
		var lean: float = sin(t*1.15+float(seed+j))*1.5
		draw_line(p+Vector2(float(j)*3.5,0),p+Vector2(float(j)*3.5+lean,-7.0-float(j%2)*4.0),Color("#3e843fc0"),1.7)

func _draw_meadow_details() -> void:
	var palette: Array[Color] = [Color("#f2c45f"),Color("#ef9fb8"),Color("#d9c0ef"),Color("#f2efcf")]
	for i in range(FLOWERS.size()):
		var p: Vector2 = FLOWERS[i]
		var sway: float = sin(t*1.6 + float(i))*1.8
		draw_line(p+Vector2(0,4),p+Vector2(sway,-8),Color("#3d7d42"),2.0)
		var c: Color = palette[i%palette.size()]
		for a in range(4):
			var ang: float = TAU*float(a)/4.0
			draw_circle(p+Vector2(sway,-10)+Vector2(cos(ang),sin(ang))*4.0,3.0,c)
		draw_circle(p+Vector2(sway,-10),2.4,Color("#f1b94e"))
	for p in SMALL_ROCKS:
		_draw_ellipse(p+Vector2(0,3),Vector2(10,4),Color(0,0,0,0.10))
		var rock_points := PackedVector2Array([p+Vector2(-8,2),p+Vector2(-4,-6),p+Vector2(4,-8),p+Vector2(9,-1),p+Vector2(6,5)])
		draw_colored_polygon(rock_points,Color("#879083"))
		draw_line(p+Vector2(-3,-5),p+Vector2(3,-6),Color("#b8bea9"),1.5)

func _draw_water_glints() -> void:
	for i in range(8):
		var a: float = t*0.35 + float(i)*0.91
		var p: Vector2 = Vector2(1360,560)+Vector2(cos(a)*float(42+i*11),sin(a*1.3)*float(22+i*7))
		var w: float = 9.0 + float(i%3)*5.0
		draw_line(p-Vector2(w,0),p+Vector2(w,0),Color(0.84,0.97,0.98,0.34),2.0)
	for i in range(12):
		var y: float = fmod(t*34.0 + float(i)*129.0,1500.0)
		var x: float = 2160.0 + sin(float(i)*2.1)*34.0
		draw_line(Vector2(x-18,y),Vector2(x+18,y),Color(0.82,0.96,1.0,0.28),2.0)

func _draw_lamps() -> void:
	var hour: float = float(farm.time_of_day)/60.0
	var night: bool = hour >= 18.0 or hour < 7.0
	for p in LAMPS:
		draw_line(p,p+Vector2(0,-42),Color("#4d4034"),5.0)
		draw_rect(Rect2(p+Vector2(-10,-54),Vector2(20,18)),Color("#5d4936"),true)
		draw_rect(Rect2(p+Vector2(-6,-50),Vector2(12,10)),Color("#f1cf72"),true)
		if night:
			var pulse: float = 0.055 + sin(t*2.0+p.x)*0.012
			draw_circle(p+Vector2(0,-45),48,Color(1.0,0.72,0.30,pulse))

func _draw_chimney_smoke() -> void:
	var base: Vector2 = Vector2(468,143)
	for i in range(5):
		var age: float = fmod(t*0.28+float(i)*0.19,1.0)
		var p: Vector2 = base + Vector2(sin(age*8.0+float(i))*9.0,-age*82.0)
		draw_circle(p,7.0+age*8.0,Color(0.86,0.84,0.79,0.19*(1.0-age)))

func _draw_butterflies() -> void:
	var hour: float = float(farm.time_of_day)/60.0
	if hour < 7.0 or hour > 18.5 or farm.weather == "Rain":
		return
	for i in range(5):
		var base: Vector2 = Vector2(540.0+float(i)*300.0,620.0+float((i*137)%410))
		var p: Vector2 = base + Vector2(sin(t*0.8+float(i))*42.0,cos(t*1.05+float(i))*18.0)
		var flap: float = 3.0+absf(sin(t*6.0+float(i)))*3.0
		var bc: Color = Color("#f3c46b") if i%2==0 else Color("#e7a7c6")
		draw_circle(p-Vector2(flap,0),2.6,bc)
		draw_circle(p+Vector2(flap,0),2.6,bc.lightened(0.08))
		draw_circle(p,1.5,Color("#604633"))

func _draw_npc_portrait(p: Vector2, kind: String, label: String) -> void:
	var bob: float = sin(t*3.0+p.x*0.01)*1.6
	var skin := Color("#efbd91")
	var shirt := Color("#735487")
	var hair := Color("#d1a45e")
	var pants := Color("#46566c")
	if kind == "lina":
		shirt = Color("#4d8fa8")
		hair = Color("#6b4335")
	elif kind == "marnie":
		shirt = Color("#b9656e")
		hair = Color("#9b6636")
		pants = Color("#5c4f63")
	_draw_ellipse(p+Vector2(0,29),Vector2(24,7),Color(0,0,0,0.20))
	draw_rect(Rect2(p+Vector2(-12,20+bob),Vector2(9,22)),pants,true)
	draw_rect(Rect2(p+Vector2(4,20+bob),Vector2(9,22)),pants,true)
	draw_rect(Rect2(p+Vector2(-17,-8+bob),Vector2(34,33)),shirt,true)
	draw_circle(p+Vector2(0,-27+bob),17,skin)
	draw_line(p+Vector2(-15,0+bob),p+Vector2(-21,18+bob),skin,6.0)
	draw_line(p+Vector2(15,0+bob),p+Vector2(21,18+bob),skin,6.0)
	if kind == "lina":
		draw_circle(p+Vector2(0,-36+bob),18,hair)
		draw_rect(Rect2(p+Vector2(-17,-35+bob),Vector2(9,23)),hair,true)
		draw_rect(Rect2(p+Vector2(9,-35+bob),Vector2(9,23)),hair,true)
	elif kind == "marnie":
		draw_circle(p+Vector2(0,-37+bob),17,hair)
		draw_circle(p+Vector2(-12,-28+bob),8,hair)
		draw_circle(p+Vector2(12,-28+bob),8,hair)
	else:
		draw_rect(Rect2(p+Vector2(-17,-42+bob),Vector2(34,11)),hair,true)
		draw_rect(Rect2(p+Vector2(-12,-46+bob),Vector2(24,6)),hair.lightened(0.06),true)
	draw_circle(p+Vector2(-6,-26+bob),2.1,Color("#302a27"))
	draw_circle(p+Vector2(6,-26+bob),2.1,Color("#302a27"))
	draw_line(p+Vector2(-4,-18+bob),p+Vector2(4,-18+bob),Color("#b96c62"),1.6)
	draw_rect(Rect2(p+Vector2(-34,48),Vector2(68,20)),Color(0.08,0.10,0.08,0.72),true)
	draw_line(p+Vector2(-27,48),p+Vector2(27,48),Color("#d8b56a"),1.6)
	draw_string(ThemeDB.fallback_font,p+Vector2(-27,63),label,HORIZONTAL_ALIGNMENT_CENTER,54,10,Color("#fff1ce"))

func _draw_night_particles() -> void:
	var hour: float = float(farm.time_of_day)/60.0
	if hour < 18.5 and hour >= 6.5:
		return
	for i in range(16):
		var x: float = 120.0 + fmod(float(i)*173.0 + sin(t*.7+float(i))*26.0,1900.0)
		var y: float = 310.0 + fmod(float(i)*109.0 + cos(t*.9+float(i))*18.0,930.0)
		var pulse: float = 0.35+0.35*sin(t*3.0+float(i))
		draw_circle(Vector2(x,y),2.4,Color(1.0,0.88,0.42,pulse))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a: float = TAU*float(i)/28.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
