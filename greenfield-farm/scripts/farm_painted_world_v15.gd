extends Node2D
class_name FarmPaintedWorldV15

const GRASS_TEX: Texture2D = preload("res://assets/art/grass_tile.svg")
const PATH_TEX: Texture2D = preload("res://assets/art/path_tile.svg")
const WATER_TEX: Texture2D = preload("res://assets/art/water_tile.svg")
const TREE_TEX: Texture2D = preload("res://assets/art/tree.svg")
const STORE_TEX: Texture2D = preload("res://assets/art/store.svg")
const BARN_TEX: Texture2D = preload("res://assets/art/barn.svg")
const TOWNHALL_TEX: Texture2D = preload("res://assets/art/townhall.svg")

var farm: FarmWorld
var active: bool = true
var t: float = 0.0

func setup(world: FarmWorld) -> void:
	farm = world
	z_index = 0
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
	_draw_watercolor_ground()
	_draw_painterly_paths()
	_draw_painterly_water()
	_draw_static_buildings()
	_draw_story_trees()
	_draw_flower_borders()

func _draw_watercolor_ground() -> void:
	# Large, overlapping translucent washes reduce the visible tile/grid feeling.
	draw_rect(Rect2(Vector2.ZERO, FarmWorld.WORLD_SIZE), Color("#8fc66a"), true)
	var washes: Array[Dictionary] = [
		{"p":Vector2(260,250),"r":Vector2(340,210),"c":Color(0.93,0.85,0.37,0.10)},
		{"p":Vector2(780,330),"r":Vector2(420,250),"c":Color(0.49,0.72,0.31,0.10)},
		{"p":Vector2(540,900),"r":Vector2(430,280),"c":Color(0.85,0.79,0.35,0.08)},
		{"p":Vector2(1520,980),"r":Vector2(500,320),"c":Color(0.36,0.64,0.30,0.09)},
		{"p":Vector2(1850,360),"r":Vector2(360,250),"c":Color(0.95,0.83,0.48,0.07)}
	]
	for item: Dictionary in washes:
		_draw_blob(item["p"], item["r"], item["c"], 0.09)
	# Fine irregular grass strokes.
	for i in range(180):
		var x: float = 28.0 + fmod(float(i * 137), 2210.0)
		var y: float = 34.0 + fmod(float(i * 83), 1450.0)
		var h: float = 4.0 + float(i % 5) * 1.8
		var sway: float = sin(float(i) * 1.73 + t * 0.25) * 1.3
		var col: Color = Color(0.24,0.48,0.22,0.34) if i % 2 == 0 else Color(0.61,0.72,0.30,0.28)
		draw_line(Vector2(x,y),Vector2(x+sway,y-h),col,1.15)

func _draw_painterly_paths() -> void:
	var path_color := Color("#dfbd78")
	var path_light := Color(0.96,0.84,0.56,0.34)
	# North road.
	draw_rect(Rect2(0,392,FarmWorld.WORLD_SIZE.x,92),path_color,true)
	# Vertical lane and eastern connectors.
	draw_rect(Rect2(1016,392,102,892),path_color,true)
	draw_rect(Rect2(1016,792,1076,90),path_color,true)
	draw_rect(Rect2(1060,1112,1010,84),path_color,true)
	# Watercolor edge bleed and stone flecks.
	for i in range(42):
		var x: float = 18.0 + float(i) * 54.0
		var yy: float = 420.0 + sin(float(i)*1.7) * 19.0
		draw_circle(Vector2(x,yy),2.0+float(i%3),Color(0.47,0.36,0.22,0.20))
		if i % 3 == 0:
			draw_line(Vector2(x-12,407),Vector2(x+18,404),path_light,2.0)
	for i in range(16):
		var y: float = 430.0 + float(i) * 50.0
		draw_circle(Vector2(1066.0+sin(float(i))*21.0,y),3.0,Color(0.45,0.35,0.24,0.18))
	# Soft grass along the road edges.
	for i in range(33):
		var x2: float = 30.0 + float(i) * 68.0
		_draw_grass_cluster(Vector2(x2,390),i)
		_draw_grass_cluster(Vector2(x2+29.0,489),i+50)

func _draw_painterly_water() -> void:
	# East river.
	draw_rect(Rect2(2092,0,28,FarmWorld.WORLD_SIZE.y),Color("#c6a66f"),true)
	draw_rect(Rect2(2120,0,184,FarmWorld.WORLD_SIZE.y),Color("#4d9fbc"),true)
	for i in range(35):
		var y: float = 24.0 + float(i)*44.0
		var w: float = 26.0 + float(i%4)*10.0
		draw_line(Vector2(2160.0,y),Vector2(2160.0+w,y+sin(t*.3+float(i))*2.0),Color(0.78,0.94,0.91,0.35),1.5)
	# Storybook pond with irregular shoreline.
	var c := Vector2(1360,560)
	_draw_blob(c+Vector2(5,9),Vector2(190,154),Color(0.22,0.31,0.20,0.18),0.05)
	_draw_blob(c,Vector2(184,149),Color("#d3b775"),0.045)
	_draw_blob(c+Vector2(-3,0),Vector2(172,139),Color("#6f9e61"),0.042)
	_draw_blob(c+Vector2(-5,-3),Vector2(158,127),Color("#4ea6bf"),0.038)
	_draw_blob(c+Vector2(-10,-12),Vector2(142,104),Color(0.42,0.77,0.80,0.26),0.034)
	for i in range(12):
		var a: float = t*.16 + float(i)*.61
		var p: Vector2 = c + Vector2(cos(a*1.2)*(25.0+float(i)*8.0),sin(a)*(12.0+float(i)*4.0))
		draw_line(p-Vector2(8+float(i%3)*4,0),p+Vector2(8+float(i%3)*4,0),Color(0.91,0.98,0.92,0.30),1.5)
	# Lily pads.
	for off in [Vector2(-62,-28),Vector2(54,38),Vector2(78,-39)]:
		_draw_ellipse(c+off,Vector2(15,8),Color("#6ca455"))
		draw_circle(c+off+Vector2(4,-2),2.4,Color("#f1b5ca"))
	# Dock.
	for k in range(4):
		draw_rect(Rect2(c+Vector2(-179+float(k)*24,62+float(k%2)*2),Vector2(29,17)),Color("#a87543"),true)
		draw_line(c+Vector2(-178+float(k)*24,64),c+Vector2(-152+float(k)*24,65),Color("#d6aa6d"),2.0)
	for px in [-183.0,-83.0]:
		draw_rect(Rect2(c+Vector2(px,54),Vector2(8,43)),Color("#694a31"),true)
	# Reeds around the bank.
	for i in range(20):
		var a2: float = -2.8 + float(i)*0.29
		if i > 7 and i < 11:
			continue
		var q: Vector2 = c + Vector2(cos(a2)*175.0,sin(a2)*141.0)
		_draw_reeds(q,i)

func _draw_static_buildings() -> void:
	# The v1.4 authored house remains the hero building; soften it with garden light and flowers.
	var house_rect := FarmWorld.HOUSE_RECT
	var store_rect := FarmWorld.STORE_RECT
	var hall_rect := FarmWorld.TOWN_HALL_RECT
	var barn_rect := FarmWorld.BARN_RECT
	# Repaint base rectangles softly before authored textures from lower layer show through around edges.
	draw_rect(Rect2(house_rect.position-Vector2(16,14),house_rect.size+Vector2(32,30)),Color(0.82,0.75,0.49,0.08),true)
	# Flower beds and stepping stones around the farmhouse.
	for i in range(8):
		var p := Vector2(175.0+float(i)*53.0,370.0+sin(float(i)*1.4)*5.0)
		_draw_wildflower(p,i)
	for i in range(5):
		var p2 := Vector2(326.0+float(i)*20.0,386.0+float(i)*13.0)
		_draw_ellipse(p2,Vector2(14,6),Color(0.56,0.49,0.37,0.28))
	# Do not repaint building bodies here; base authored SVG textures remain visible through this overlay.

func _draw_story_trees() -> void:
	# Layered canopies drawn over the older trees make silhouettes more organic and watercolor-like.
	var trees: Array[Vector2] = [Vector2(117,118),Vector2(772,112),Vector2(898,214),Vector2(2038,490),Vector2(793,1254),Vector2(1508,1294),Vector2(2034,1360),Vector2(143,1335)]
	for i in range(trees.size()):
		var p: Vector2 = trees[i]
		_draw_tree_canopy(p,i)

func _draw_tree_canopy(p: Vector2, seed: int) -> void:
	# trunk peek
	draw_colored_polygon(PackedVector2Array([p+Vector2(-12,20),p+Vector2(13,19),p+Vector2(19,82),p+Vector2(-18,82)]),Color("#785338"))
	var base_col: Color = Color("#4f8648") if seed%2==0 else Color("#5c914f")
	for j in range(7):
		var a: float = TAU*float(j)/7.0
		var center: Vector2 = p+Vector2(cos(a)*34.0,sin(a)*25.0)+Vector2(0,-16)
		var r: float = 31.0+float((seed+j)%3)*5.0
		draw_circle(center,r,base_col.lightened(float((j+seed)%3)*0.035))
	for j in range(10):
		var a2: float = TAU*float(j)/10.0
		var hp: Vector2 = p+Vector2(cos(a2)*35.0,sin(a2)*25.0)+Vector2(0,-28)
		draw_circle(hp,6.0+float(j%3),Color(0.78,0.88,0.42,0.16))

func _draw_flower_borders() -> void:
	var spots: Array[Vector2] = [Vector2(180,345),Vector2(245,356),Vector2(530,350),Vector2(610,365),Vector2(875,360),Vector2(955,350),Vector2(1140,390),Vector2(1210,735),Vector2(1530,705),Vector2(1760,730),Vector2(1890,690),Vector2(1160,940),Vector2(1490,1030),Vector2(1840,1100)]
	for i in range(spots.size()):
		_draw_wildflower(spots[i],i)

func _draw_grass_cluster(p: Vector2, seed: int) -> void:
	for j in range(5):
		var x: float = (float(j)-2.0)*3.0
		var h: float = 7.0+float((seed+j)%3)*3.0
		var sway: float = sin(t*.4+float(seed+j))*1.4
		draw_line(p+Vector2(x,0),p+Vector2(x+sway,-h),Color(0.27,0.50,0.23,0.55),1.4)

func _draw_wildflower(p: Vector2, seed: int) -> void:
	var stem := Color(0.28,0.48,0.25,0.65)
	var petal := Color("#f3c7d4") if seed%3==0 else (Color("#f2d775") if seed%3==1 else Color("#f4f1cf"))
	draw_line(p,p+Vector2(0,-14),stem,1.5)
	for k in range(5):
		var a: float = TAU*float(k)/5.0
		draw_circle(p+Vector2(0,-16)+Vector2(cos(a),sin(a))*3.4,2.3,petal)
	draw_circle(p+Vector2(0,-16),1.7,Color("#b9843e"))

func _draw_reeds(p: Vector2, seed: int) -> void:
	for j in range(3):
		var q := p+Vector2(float(j)*4.0,0)
		var lean: float = sin(t*.45+float(seed+j))*1.5
		draw_line(q,q+Vector2(lean,-18.0-float(j%2)*7.0),Color("#466e42"),1.7)
		if j==1:
			draw_circle(q+Vector2(lean,-22),2.2,Color("#82603f"))

func _draw_blob(center: Vector2, radius: Vector2, color: Color, wobble: float) -> void:
	var pts := PackedVector2Array()
	for i in range(40):
		var a: float = TAU*float(i)/40.0
		var n: float = 1.0+sin(a*3.0+center.x*.01)*wobble+sin(a*7.0-center.y*.008)*wobble*.35
		pts.append(center+Vector2(cos(a)*radius.x*n,sin(a)*radius.y*n))
	draw_colored_polygon(pts,color)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(28):
		var a: float = TAU*float(i)/28.0
		pts.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(pts,color)
