extends Node2D
class_name FarmVisualPolish

var farm: FarmWorld
var active: bool = true
var t: float = 0.0

const FLOWERS: Array[Vector2] = [
	Vector2(620,350),Vector2(690,365),Vector2(760,345),Vector2(900,515),
	Vector2(1160,760),Vector2(1210,780),Vector2(1510,730),Vector2(1580,750),
	Vector2(1820,720),Vector2(1870,745),Vector2(680,1010),Vector2(750,1030),
	Vector2(1460,1320),Vector2(1520,1340),Vector2(1900,1230),Vector2(1960,1260)
]

const LAMPS: Array[Vector2] = [Vector2(980,430),Vector2(1110,820),Vector2(1510,820),Vector2(1900,820)]
const FLOWER_COLORS: Array[Color] = [Color("#f2c45f"),Color("#ef9fb8"),Color("#d9c0ef"),Color("#f2efcf")]

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
	_draw_meadow_details()
	_draw_water_glints()
	_draw_lamps()
	_draw_chimney_smoke()
	_draw_npc_portrait(_npc_pos(FarmWorld.MAYOR_SPOT,0.0),"rowan","ROWAN")
	_draw_npc_portrait(_npc_pos(FarmWorld.LINA_SPOT,1.7),"lina","LINA")
	_draw_npc_portrait(_npc_pos(FarmWorld.MARNIE_SPOT,3.2),"marnie","MARNIE")
	_draw_night_particles()

func _npc_pos(base: Vector2, phase: float) -> Vector2:
	var phase_time: float = farm.npc_phase
	return base + Vector2(sin(phase_time*0.55+phase)*24.0,cos(phase_time*0.42+phase)*10.0)

func _draw_meadow_details() -> void:
	for i in range(FLOWERS.size()):
		var p: Vector2 = FLOWERS[i]
		var sway: float = sin(t*1.6 + float(i))*1.8
		draw_line(p+Vector2(0,4),p+Vector2(sway,-8),Color("#3d7d42"),2.0)
		var c: Color = FLOWER_COLORS[i%FLOWER_COLORS.size()]
		for petal_index in range(4):
			var ang: float = TAU*float(petal_index)/4.0
			draw_circle(p+Vector2(sway,-10)+Vector2(cos(ang),sin(ang))*4.0,3.0,c)
		draw_circle(p+Vector2(sway,-10),2.4,Color("#f1b94e"))
	# foreground grass clusters
	for i in range(18):
		var x: float = 70.0 + float((i*127)%1950)
		var y: float = 330.0 + float((i*173)%1030)
		var grass_pos: Vector2 = Vector2(x,y)
		for j in range(4):
			var lean: float = sin(t*1.2+float(i+j))*1.7
			draw_line(grass_pos+Vector2(j*4,0),grass_pos+Vector2(j*4+lean,-10-j%2*3),Color(0.22,0.45,0.22,0.62),2.0)

func _draw_water_glints() -> void:
	# pond glints
	for i in range(7):
		var angle: float = t*0.35 + float(i)*0.91
		var p: Vector2 = Vector2(1360,560)+Vector2(cos(angle)*float(42+i*11),sin(angle*1.3)*float(22+i*7))
		var width: float = 10.0 + float(i%3)*6.0
		draw_line(p-Vector2(width,0),p+Vector2(width,0),Color(0.84,0.97,0.98,0.35),2.0)
	# river travelling highlights
	for i in range(11):
		var y: float = fmod(t*34.0 + float(i)*143.0,1500.0)
		var x: float = 2160.0 + sin(float(i)*2.1)*34.0
		draw_line(Vector2(x-18,y),Vector2(x+18,y),Color(0.82,0.96,1.0,0.30),2.0)

func _draw_lamps() -> void:
	var hour: float = float(farm.time_of_day)/60.0
	var night: bool = hour >= 18.0 or hour < 7.0
	for lamp_pos in LAMPS:
		var p: Vector2 = lamp_pos
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
		var smoke_pos: Vector2 = base + Vector2(sin(age*8.0+float(i))*9.0,-age*82.0)
		draw_circle(smoke_pos,7.0+age*8.0,Color(0.86,0.84,0.79,0.19*(1.0-age)))

func _draw_npc_portrait(p: Vector2, kind: String, label: String) -> void:
	var bob: float = sin(t*3.0+p.x*0.01)*1.8
	var skin: Color = Color("#efbd91")
	var shirt: Color = Color("#735487")
	var hair: Color = Color("#d1a45e")
	var pants: Color = Color("#46566c")
	if kind == "lina":
		shirt = Color("#4d8fa8")
		hair = Color("#6b4335")
		pants = Color("#465766")
	elif kind == "marnie":
		shirt = Color("#b9656e")
		hair = Color("#9b6636")
		pants = Color("#5c4f63")
	# opaque silhouette covers the old placeholder NPC
	_draw_ellipse(p+Vector2(0,31),Vector2(27,8),Color(0,0,0,0.24))
	draw_rect(Rect2(p+Vector2(-13,22+bob),Vector2(10,23)),pants,true)
	draw_rect(Rect2(p+Vector2(4,22+bob),Vector2(10,23)),pants,true)
	draw_rect(Rect2(p+Vector2(-18,-8+bob),Vector2(36,34)),shirt,true)
	draw_circle(p+Vector2(0,-27+bob),18,skin)
	# arms
	draw_line(p+Vector2(-16,0+bob),p+Vector2(-23,20+bob),skin,7.0)
	draw_line(p+Vector2(16,0+bob),p+Vector2(23,20+bob),skin,7.0)
	# hair silhouettes
	if kind == "lina":
		draw_circle(p+Vector2(0,-36+bob),19,hair)
		draw_rect(Rect2(p+Vector2(-18,-36+bob),Vector2(10,25)),hair,true)
		draw_rect(Rect2(p+Vector2(9,-36+bob),Vector2(10,25)),hair,true)
	elif kind == "marnie":
		draw_circle(p+Vector2(0,-38+bob),18,hair)
		draw_circle(p+Vector2(-13,-28+bob),9,hair)
		draw_circle(p+Vector2(13,-28+bob),9,hair)
	else:
		draw_rect(Rect2(p+Vector2(-18,-43+bob),Vector2(36,12)),hair,true)
		draw_rect(Rect2(p+Vector2(-13,-47+bob),Vector2(26,7)),hair.lightened(0.08),true)
	# face and clothing details
	draw_circle(p+Vector2(-6,-26+bob),2.2,Color("#302a27"))
	draw_circle(p+Vector2(6,-26+bob),2.2,Color("#302a27"))
	draw_line(p+Vector2(-4,-18+bob),p+Vector2(4,-18+bob),Color("#b96c62"),1.7)
	draw_line(p+Vector2(-11,4+bob),p+Vector2(11,4+bob),shirt.lightened(0.18),2.0)
	# clean nameplate
	draw_rect(Rect2(p+Vector2(-39,51),Vector2(78,23)),Color(0.08,0.10,0.08,0.82),true)
	draw_line(p+Vector2(-32,51),p+Vector2(32,51),Color("#d8b56a"),2.0)
	draw_string(ThemeDB.fallback_font,p+Vector2(-31,68),label,HORIZONTAL_ALIGNMENT_CENTER,62,12,Color("#fff1ce"))

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
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(28):
		var angle: float = TAU*float(i)/28.0
		points.append(center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
	draw_colored_polygon(points,color)
