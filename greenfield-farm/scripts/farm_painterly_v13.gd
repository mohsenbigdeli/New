extends Node2D
class_name FarmPainterlyV13

var farm: FarmWorld
var active: bool = true
var t: float = 0.0

const WASH_CENTERS: Array[Vector2] = [
	Vector2(360,610),Vector2(760,560),Vector2(940,910),Vector2(490,1040),
	Vector2(1330,1010),Vector2(1680,1010),Vector2(1840,620),Vector2(1970,1260)
]
const SUN_PATCHES: Array[Vector2] = [
	Vector2(520,560),Vector2(820,690),Vector2(640,930),Vector2(1510,640),
	Vector2(1760,910),Vector2(1850,1180),Vector2(1260,1260)
]

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
	_draw_meadow_washes()
	_draw_dappled_light()
	_draw_path_edge_growth()
	_draw_field_edge_growth()
	_draw_foreground_leaves()

func _organic_blob(center: Vector2, rx: float, ry: float, phase: float, wobble: float, count: int = 36) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count):
		var a: float = TAU * float(i) / float(count)
		var n: float = 1.0 + sin(a*3.0+phase)*wobble + sin(a*5.0-phase*.8)*wobble*.38
		points.append(center + Vector2(cos(a)*rx*n,sin(a)*ry*n))
	return points

func _draw_meadow_washes() -> void:
	for i in range(WASH_CENTERS.size()):
		var c: Vector2 = WASH_CENTERS[i]
		var rx: float = 110.0 + float((i*37)%85)
		var ry: float = 52.0 + float((i*23)%42)
		var col: Color = Color(0.16,0.35,0.17,0.045) if i%2==0 else Color(0.88,0.82,0.47,0.035)
		draw_colored_polygon(_organic_blob(c,rx,ry,float(i)*0.73,0.075),col)
		if i%3==0:
			draw_colored_polygon(_organic_blob(c+Vector2(18,-8),rx*.62,ry*.54,float(i)+1.2,0.09),Color(0.95,0.90,0.63,0.025))

func _draw_dappled_light() -> void:
	var hour: float = float(farm.time_of_day)/60.0
	if hour < 7.0 or hour > 18.5 or farm.weather == "Rain":
		return
	var strength: float = 0.026 + sin(t*.17)*0.004
	for i in range(SUN_PATCHES.size()):
		var c: Vector2 = SUN_PATCHES[i] + Vector2(sin(t*.11+float(i))*5.0,cos(t*.13+float(i))*3.0)
		draw_colored_polygon(_organic_blob(c,54.0+float(i%3)*12.0,21.0+float(i%2)*7.0,float(i)*.9,0.12),Color(1.0,0.92,0.58,strength))
		if i%2==0:
			draw_circle(c+Vector2(28,-12),8.0,Color(1.0,0.94,0.70,strength*.7))

func _draw_path_edge_growth() -> void:
	# Horizontal northern road edges.
	for i in range(20):
		var x: float = 52.0 + float(i)*103.0
		var y: float = 386.0 + float((i*7)%8)
		_draw_grass_cluster(Vector2(x,y),i,0.72)
		if i%2==0:
			_draw_grass_cluster(Vector2(x+37.0,490.0-float((i*5)%7)),i+31,0.55)
	# Main vertical lane.
	for i in range(9):
		var y2: float = 530.0 + float(i)*91.0
		_draw_grass_cluster(Vector2(1008.0+float(i%3)*4.0,y2),i+55,0.62)
		if i%2==1:
			_draw_flower_sprig(Vector2(1121.0-float(i%2)*4.0,y2+24.0),i)

func _draw_field_edge_growth() -> void:
	var left: float = FarmWorld.ORIGIN.x - 22.0
	var top: float = FarmWorld.ORIGIN.y - 20.0
	var right: float = FarmWorld.ORIGIN.x + float(FarmWorld.COLS*FarmWorld.TILE_SIZE) + 22.0
	var bottom: float = FarmWorld.ORIGIN.y + float(FarmWorld.ROWS*FarmWorld.TILE_SIZE) + 22.0
	for i in range(14):
		var x: float = left + 34.0 + float(i)*70.0
		if i%3 != 1:
			_draw_grass_cluster(Vector2(x,top+7.0),90+i,0.50)
		if i%4==0:
			_draw_flower_sprig(Vector2(x+18.0,bottom-4.0),100+i)
	for i in range(7):
		var y: float = top + 62.0 + float(i)*72.0
		if i%2==0:
			_draw_grass_cluster(Vector2(left+6.0,y),120+i,0.52)
		if i%3==0:
			_draw_flower_sprig(Vector2(right-2.0,y+19.0),130+i)

func _draw_grass_cluster(p: Vector2, seed: int, alpha: float) -> void:
	for j in range(6):
		var x: float = (float(j)-2.5)*3.5
		var h: float = 7.0 + float((seed+j)%4)*3.0
		var sway: float = sin(t*.72+float(seed+j))*1.7
		var c: Color = Color(0.18,0.40,0.19,alpha) if j%2==0 else Color(0.34,0.55,0.25,alpha*.85)
		draw_line(p+Vector2(x,0),p+Vector2(x+sway,-h),c,1.6)

func _draw_flower_sprig(p: Vector2, seed: int) -> void:
	var stem: Color = Color(0.20,0.42,0.21,0.72)
	var petal: Color = Color("#efc1cf") if seed%2==0 else Color("#efd87b")
	draw_line(p,p+Vector2(0,-16),stem,1.5)
	for k in range(4):
		var a: float = TAU*float(k)/4.0
		draw_circle(p+Vector2(0,-18)+Vector2(cos(a),sin(a))*3.6,2.3,petal)
	draw_circle(p+Vector2(0,-18),1.7,Color("#a96f3f"))

func _draw_foreground_leaves() -> void:
	# Decorative leaves along the far edges give a foreground layer when the camera travels.
	var anchors: Array[Vector2] = [Vector2(120,1460),Vector2(390,1450),Vector2(760,1470),Vector2(1550,1455),Vector2(1940,1445)]
	for i in range(anchors.size()):
		var p: Vector2 = anchors[i]
		for j in range(5):
			var a: float = -1.9 + float(j)*0.42
			var len: float = 28.0 + float((i+j)%3)*9.0
			var end: Vector2 = p + Vector2(cos(a)*len,sin(a)*len)
			draw_line(p,end,Color(0.17,0.34,0.17,0.58),3.0)
			_draw_leaf(end,a,float((i+j)%2))

func _draw_leaf(p: Vector2, angle: float, variant: float) -> void:
	var side: Vector2 = Vector2(-sin(angle),cos(angle))
	var fwd: Vector2 = Vector2(cos(angle),sin(angle))
	var pts := PackedVector2Array([p-side*5.0,p+fwd*10.0,p+side*5.0,p-fwd*2.0])
	var c: Color = Color("#4c7b45") if variant<0.5 else Color("#638b4d")
	draw_colored_polygon(pts,c)
