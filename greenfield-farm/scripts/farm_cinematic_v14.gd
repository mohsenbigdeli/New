extends Node2D
class_name FarmCinematicV14

var farm: FarmWorld
var active: bool = true
var t: float = 0.0

const LIGHT_PATCHES: Array[Vector2] = [
	Vector2(260,330),Vector2(520,520),Vector2(780,430),Vector2(960,700),
	Vector2(1240,900),Vector2(1510,690),Vector2(1760,980),Vector2(1980,640)
]
const MIST_PATCHES: Array[Vector2] = [
	Vector2(260,250),Vector2(830,250),Vector2(1450,300),Vector2(1880,320),
	Vector2(620,1120),Vector2(1680,1180)
]
const FOREGROUND_ANCHORS: Array[Vector2] = [
	Vector2(40,1490),Vector2(310,1500),Vector2(710,1495),Vector2(1420,1495),Vector2(1810,1490),Vector2(2220,1490)
]

func setup(world: FarmWorld) -> void:
	farm = world
	z_index = 3
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
	_draw_atmospheric_wash()
	_draw_tree_cast_light()
	_draw_path_light()
	_draw_pond_magic()
	_draw_house_warmth()
	_draw_pollen()
	_draw_falling_leaves()
	_draw_foreground_foliage()

func _draw_atmospheric_wash() -> void:
	var hour: float = float(farm.time_of_day) / 60.0
	var day_strength: float = 1.0
	if hour < 7.0 or hour > 18.5:
		day_strength = 0.35
	var warm: Color = Color(1.0,0.80,0.50,0.022 * day_strength)
	var cool: Color = Color(0.48,0.69,0.64,0.018)
	for i in range(MIST_PATCHES.size()):
		var c: Vector2 = MIST_PATCHES[i] + Vector2(sin(t*0.06+float(i))*8.0,cos(t*0.05+float(i))*5.0)
		var col: Color = warm if i % 2 == 0 else cool
		draw_colored_polygon(_blob(c,170.0+float(i%3)*40.0,70.0+float(i%2)*28.0,float(i)*0.7,0.16,42),col)

func _draw_tree_cast_light() -> void:
	if farm.weather == "Rain":
		return
	var hour: float = float(farm.time_of_day) / 60.0
	if hour < 7.0 or hour > 18.5:
		return
	for i in range(LIGHT_PATCHES.size()):
		var drift: Vector2 = Vector2(sin(t*0.11+float(i))*4.0,cos(t*0.09+float(i))*3.0)
		var c: Vector2 = LIGHT_PATCHES[i] + drift
		var alpha: float = 0.030 + 0.008*sin(t*0.23+float(i))
		draw_colored_polygon(_blob(c,68.0+float(i%3)*18.0,22.0+float(i%2)*8.0,float(i)*1.1,0.18,30),Color(1.0,0.91,0.62,alpha))
		if i % 2 == 0:
			draw_colored_polygon(_blob(c+Vector2(45,-17),33,12,float(i)*0.8,0.20,24),Color(1.0,0.95,0.72,alpha*0.7))

func _draw_path_light() -> void:
	# soft ochre and green bleed at path edges, like watercolor pigment spreading into paper
	var edge_points: Array[Vector2] = [
		Vector2(170,386),Vector2(430,486),Vector2(690,390),Vector2(920,487),
		Vector2(1020,620),Vector2(1120,750),Vector2(1370,790),Vector2(1660,883),Vector2(1950,1110)
	]
	for i in range(edge_points.size()):
		var c: Vector2 = edge_points[i]
		var col: Color = Color(0.89,0.70,0.39,0.025) if i%2==0 else Color(0.24,0.46,0.22,0.026)
		draw_colored_polygon(_blob(c,54.0+float(i%3)*17.0,18.0+float(i%2)*8.0,float(i),0.20,26),col)

func _draw_pond_magic() -> void:
	var c := Vector2(1360,560)
	# faint sky reflection and moving caustic strokes
	draw_colored_polygon(_blob(c+Vector2(-18,-22),112,66,0.7,0.12,36),Color(0.78,0.94,0.90,0.035))
	for i in range(11):
		var a: float = t*0.18 + float(i)*0.61
		var p: Vector2 = c + Vector2(cos(a*1.27)*(32.0+float(i)*9.0),sin(a)*(18.0+float(i)*4.2))
		var width: float = 7.0 + float(i%4)*4.0
		draw_line(p-Vector2(width,0),p+Vector2(width,0),Color(0.90,0.98,0.92,0.24),1.6)
	# warm reflected flecks near the bank
	for i in range(7):
		var ang: float = -0.8 + float(i)*0.24
		var p2: Vector2 = c + Vector2(cos(ang)*142.0,sin(ang)*112.0)
		draw_circle(p2,2.2,Color(1.0,0.82,0.48,0.20+0.05*sin(t*1.3+float(i))))

func _draw_house_warmth() -> void:
	# subtle garden light around the farmhouse and entry stones
	var c := Vector2(365,318)
	draw_colored_polygon(_blob(c,210,48,1.2,0.11,36),Color(0.97,0.78,0.48,0.024))
	for i in range(5):
		var p := Vector2(285.0+float(i)*40.0,366.0+sin(float(i))*4.0)
		draw_colored_polygon(_blob(p,16,7,float(i),0.14,20),Color(0.56,0.49,0.35,0.16))
		draw_line(p-Vector2(9,1),p+Vector2(9,-1),Color(0.92,0.81,0.58,0.15),1.2)

func _draw_pollen() -> void:
	var hour: float = float(farm.time_of_day)/60.0
	if hour < 7.5 or hour > 18.0 or farm.weather == "Rain":
		return
	for i in range(18):
		var x: float = 120.0 + fmod(float(i)*139.0 + t*(2.0+float(i%3)),2050.0)
		var y: float = 260.0 + fmod(float(i)*83.0 + sin(t*0.4+float(i))*24.0,1030.0)
		var alpha: float = 0.10 + 0.08*(0.5+0.5*sin(t*1.1+float(i)))
		draw_circle(Vector2(x,y),1.2+float(i%2)*0.5,Color(1.0,0.88,0.55,alpha))

func _draw_falling_leaves() -> void:
	for i in range(7):
		var phase: float = t*0.18 + float(i)*1.7
		var x: float = 210.0 + fmod(float(i)*293.0 + sin(phase)*46.0,1860.0)
		var y: float = 180.0 + fmod(t*(7.0+float(i%3)*2.0)+float(i)*177.0,1080.0)
		var p := Vector2(x,y)
		var a: float = phase*2.1
		var side := Vector2(-sin(a),cos(a))
		var fwd := Vector2(cos(a),sin(a))
		var pts := PackedVector2Array([p-side*3.2,p+fwd*7.0,p+side*3.2,p-fwd*2.0])
		var col: Color = Color(0.54,0.69,0.32,0.26) if i%2==0 else Color(0.75,0.63,0.31,0.20)
		draw_colored_polygon(pts,col)

func _draw_foreground_foliage() -> void:
	for i in range(FOREGROUND_ANCHORS.size()):
		var p: Vector2 = FOREGROUND_ANCHORS[i]
		for j in range(8):
			var ang: float = -2.2 + float(j)*0.23 + sin(t*0.22+float(i+j))*0.035
			var length: float = 38.0 + float((i*3+j)%4)*12.0
			var end := p + Vector2(cos(ang)*length,sin(ang)*length)
			draw_line(p,end,Color(0.11,0.27,0.13,0.62),3.0+float(j%2))
			_draw_leaf(end,ang,Color(0.25,0.46,0.22,0.68) if j%2==0 else Color(0.35,0.54,0.28,0.60))

func _draw_leaf(p: Vector2, angle: float, color: Color) -> void:
	var side := Vector2(-sin(angle),cos(angle))
	var fwd := Vector2(cos(angle),sin(angle))
	var pts := PackedVector2Array([p-side*5.0,p+fwd*12.0,p+side*5.0,p-fwd*2.0])
	draw_colored_polygon(pts,color)
	draw_line(p-fwd*1.0,p+fwd*8.0,Color(0.78,0.86,0.55,0.18),1.0)

func _blob(center: Vector2, rx: float, ry: float, phase: float, wobble: float, count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(count):
		var a: float = TAU*float(i)/float(count)
		var n: float = 1.0 + sin(a*3.0+phase)*wobble + sin(a*7.0-phase*0.6)*wobble*0.34
		pts.append(center+Vector2(cos(a)*rx*n,sin(a)*ry*n))
	return pts
