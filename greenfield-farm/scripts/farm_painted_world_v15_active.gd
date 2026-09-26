extends Node2D
class_name FarmPaintedWorldV15Active

const FARMHOUSE_TEX: Texture2D = preload("res://assets/art/farmhouse.svg")
const STORE_TEX: Texture2D = preload("res://assets/art/store.svg")
const BARN_TEX: Texture2D = preload("res://assets/art/barn.svg")
const TOWNHALL_TEX: Texture2D = preload("res://assets/art/townhall.svg")

var farm: FarmWorld
var active: bool = true
var t: float = 0.0
var grass_tex: Texture2D

func setup(world: FarmWorld) -> void:
	farm = world
	grass_tex = FarmPaintedGrassV15.texture()
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
	_draw_painted_ground()
	_draw_paths()
	_draw_pond_and_river()
	_draw_field()
	_draw_buildings()
	_draw_trees_and_gardens()
	_draw_farm_fence()

func _draw_painted_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, FarmWorld.WORLD_SIZE), Color("#92c86a"), true)
	if grass_tex:
		for y in range(0, int(FarmWorld.WORLD_SIZE.y), 256):
			for x in range(0, int(FarmWorld.WORLD_SIZE.x), 256):
				var tint: Color = Color(1.0,1.0,1.0,0.76)
				if ((x / 256) + (y / 256)) as int % 3 == 0:
					tint = Color(1.0,0.98,0.90,0.73)
				draw_texture_rect(grass_tex, Rect2(x,y,256,256), false, tint)
	var washes: Array[Dictionary] = [
		{"p":Vector2(300,250),"r":Vector2(360,220),"c":Color(1.0,0.86,0.42,0.07)},
		{"p":Vector2(820,280),"r":Vector2(430,260),"c":Color(0.36,0.65,0.27,0.07)},
		{"p":Vector2(560,920),"r":Vector2(470,320),"c":Color(0.94,0.84,0.40,0.055)},
		{"p":Vector2(1530,930),"r":Vector2(520,330),"c":Color(0.27,0.57,0.26,0.06)}
	]
	for item: Dictionary in washes:
		_draw_blob(item["p"], item["r"], item["c"], 0.08)
	for i in range(150):
		var x: float = 24.0 + fmod(float(i * 149), 2220.0)
		var y: float = 30.0 + fmod(float(i * 89), 1460.0)
		var h: float = 5.0 + float(i % 4) * 2.0
		var sway: float = sin(t * 0.24 + float(i)) * 1.3
		draw_line(Vector2(x,y), Vector2(x+sway,y-h), Color(0.20,0.43,0.18,0.30), 1.2)

func _draw_paths() -> void:
	var sand: Color = Color("#e2bd76")
	_draw_soft_rect(Rect2(0,392,FarmWorld.WORLD_SIZE.x,92), sand)
	_draw_soft_rect(Rect2(1016,392,102,892), sand)
	_draw_soft_rect(Rect2(1016,792,1076,90), sand)
	_draw_soft_rect(Rect2(1060,1112,1010,84), sand)
	for i in range(46):
		var x: float = 18.0 + float(i) * 50.0
		var yy: float = 430.0 + sin(float(i)*1.57) * 20.0
		draw_circle(Vector2(x,yy),2.0+float(i%3),Color(0.45,0.33,0.20,0.18))
		if i % 4 == 0:
			draw_line(Vector2(x-13,408),Vector2(x+18,406),Color(1.0,0.88,0.60,0.28),2.0)
	for i in range(31):
		var x2: float = 32.0 + float(i)*72.0
		_draw_grass_cluster(Vector2(x2,390),i)
		_draw_grass_cluster(Vector2(x2+27.0,489),i+40)

func _draw_pond_and_river() -> void:
	draw_rect(Rect2(2094,0,26,FarmWorld.WORLD_SIZE.y),Color("#c7aa73"),true)
	draw_rect(Rect2(2120,0,184,FarmWorld.WORLD_SIZE.y),Color("#4b9fbd"),true)
	for i in range(35):
		var y: float = 24.0 + float(i)*44.0
		draw_line(Vector2(2150,y),Vector2(2200+float(i%3)*10.0,y+sin(t*.25+float(i))*2.0),Color(0.84,0.96,0.93,0.30),1.5)
	var c: Vector2 = Vector2(1360,560)
	_draw_blob(c+Vector2(5,10),Vector2(196,158),Color(0.17,0.25,0.17,0.16),0.05)
	_draw_blob(c,Vector2(189,153),Color("#d7bb7a"),0.045)
	_draw_blob(c,Vector2(176,143),Color("#709d61"),0.043)
	_draw_blob(c+Vector2(-4,-2),Vector2(162,131),Color("#4ca4bd"),0.038)
	_draw_blob(c+Vector2(-9,-11),Vector2(147,112),Color(0.40,0.78,0.81,0.27),0.034)
	for i in range(13):
		var a: float = t*.16 + float(i)*.59
		var p: Vector2 = c + Vector2(cos(a*1.21)*(28.0+float(i)*8.0),sin(a)*(14.0+float(i)*4.0))
		var hw: float = 8.0+float(i%3)*4.0
		draw_line(p-Vector2(hw,0),p+Vector2(hw,0),Color(0.91,0.98,0.93,0.31),1.6)
	for off: Vector2 in [Vector2(-65,-28),Vector2(54,38),Vector2(78,-39)]:
		_draw_ellipse(c+off,Vector2(15,8),Color("#6aa353"))
		draw_circle(c+off+Vector2(4,-2),2.6,Color("#f3b8cc"))
	for k in range(4):
		draw_rect(Rect2(c+Vector2(-180+float(k)*24,63+float(k%2)*2),Vector2(29,17)),Color("#a97542"),true)
		draw_line(c+Vector2(-178+float(k)*24,65),c+Vector2(-153+float(k)*24,65),Color("#d8aa6a"),2.0)
	for px: float in [-184.0,-84.0]:
		draw_rect(Rect2(c+Vector2(px,54),Vector2(8,43)),Color("#68482f"),true)
	for i in range(19):
		var aa: float = -2.8 + float(i)*0.30
		if i > 7 and i < 11:
			continue
		_draw_reeds(c+Vector2(cos(aa)*180.0,sin(aa)*145.0),i)

func _draw_field() -> void:
	var field_rect: Rect2 = Rect2(FarmWorld.ORIGIN-Vector2(12,12),Vector2(FarmWorld.COLS*FarmWorld.TILE_SIZE+24,FarmWorld.ROWS*FarmWorld.TILE_SIZE+24))
	_draw_blob(field_rect.get_center(),field_rect.size*0.51,Color(0.43,0.69,0.31,0.13),0.025)
	for y in range(FarmWorld.ROWS):
		for x in range(FarmWorld.COLS):
			var cell: Vector2i = Vector2i(x,y)
			var data: Dictionary = farm.get_cell(cell)
			if not bool(data.get("tilled",false)):
				continue
			var center: Vector2 = farm.cell_to_world(cell)
			var wet: bool = bool(data.get("watered",false))
			_draw_soil_plot(center,wet,x+y*FarmWorld.COLS)
			var crop: String = String(data.get("crop",""))
			if crop != "":
				_draw_crop(center,crop,int(data.get("stage",0)),int(data.get("age",0)))

func _draw_soil_plot(center: Vector2, wet: bool, seed: int) -> void:
	var base: Color = Color("#6d553f") if wet else Color("#94704a")
	_draw_blob(center,Vector2(28,27),base,0.055)
	for i in range(4):
		var y: float = -15.0+float(i)*10.0
		draw_line(center+Vector2(-20,y),center+Vector2(20,y+sin(float(seed+i))*1.5),Color(0.33,0.22,0.16,0.25),1.6)
	for i in range(5):
		var p: Vector2 = center+Vector2(-18+float((seed*7+i*11)%36),-16+float((seed*5+i*13)%31))
		draw_circle(p,1.4,Color(0.82,0.69,0.48,0.24))

func _draw_crop(center: Vector2, crop: String, stage: int, age: int) -> void:
	if not farm.crop_defs.has(crop):
		return
	var def: Dictionary = farm.crop_defs[crop]
	var needed: int = int(def["days"])
	var maturity: float = clampf(float(age)/float(needed),0.0,1.0)
	var growth: float = maxf(maturity,float(stage)/3.0)
	var scale_v: float = 0.55 + growth*0.65
	var leaf: Color = def["leaf"]
	var fruit: Color = def["fruit"]
	_draw_ellipse(center+Vector2(0,17),Vector2(13*scale_v,5*scale_v),Color(0.10,0.07,0.04,0.20))
	var stem_h: float = 16.0*scale_v
	draw_line(center+Vector2(0,8),center+Vector2(0,-stem_h),Color("#397b3c"),3.2)
	for side: float in [-1.0,1.0]:
		var p: Vector2 = center+Vector2(side*8.0,-stem_h*0.55)
		_draw_leaf(p,side,leaf)
	if growth > 0.62:
		_draw_leaf(center+Vector2(-3,-stem_h),-1.0,leaf.lightened(0.08))
	if maturity >= 1.0:
		if crop == "carrot":
			draw_colored_polygon(PackedVector2Array([center+Vector2(-8,7),center+Vector2(8,7),center+Vector2(0,27)]),fruit)
		elif crop == "corn":
			draw_colored_polygon(PackedVector2Array([center+Vector2(4,-3),center+Vector2(14,0),center+Vector2(13,21),center+Vector2(4,18)]),fruit)
		else:
			draw_circle(center+Vector2(0,12),12,fruit)

func _draw_leaf(center: Vector2, side: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([center+Vector2(0,0),center+Vector2(side*13,-6),center+Vector2(side*16,4),center+Vector2(side*5,9)])
	draw_colored_polygon(pts,color)

func _draw_buildings() -> void:
	_draw_shadow(FarmWorld.HOUSE_RECT)
	_draw_shadow(FarmWorld.STORE_RECT)
	_draw_shadow(FarmWorld.TOWN_HALL_RECT)
	_draw_shadow(FarmWorld.BARN_RECT)
	draw_texture_rect(FARMHOUSE_TEX,FarmWorld.HOUSE_RECT,false,Color(1.0,0.98,0.92,1.0))
	draw_texture_rect(STORE_TEX,FarmWorld.STORE_RECT,false,Color(1.0,0.97,0.90,1.0))
	draw_texture_rect(TOWNHALL_TEX,FarmWorld.TOWN_HALL_RECT,false,Color(1.0,0.97,0.90,1.0))
	draw_texture_rect(BARN_TEX,FarmWorld.BARN_RECT,false,Color(1.0,0.97,0.90,1.0))
	for i in range(9):
		_draw_wildflower(Vector2(176.0+float(i)*48.0,374.0+sin(float(i)*1.4)*5.0),i)
	for i in range(5):
		_draw_ellipse(Vector2(327.0+float(i)*20.0,386.0+float(i)*13.0),Vector2(14,6),Color(0.54,0.47,0.35,0.28))

func _draw_trees_and_gardens() -> void:
	var trees: Array[Vector2] = [Vector2(115,110),Vector2(770,105),Vector2(900,205),Vector2(2025,470),Vector2(790,1240),Vector2(1505,1280),Vector2(2025,1345),Vector2(140,1320)]
	for i in range(trees.size()):
		_draw_tree(trees[i],i)
	var flower_spots: Array[Vector2] = [Vector2(245,350),Vector2(540,352),Vector2(865,355),Vector2(955,350),Vector2(1185,742),Vector2(1510,730),Vector2(1730,740),Vector2(1880,700),Vector2(1180,1000),Vector2(1510,1040),Vector2(1830,1090)]
	for i in range(flower_spots.size()):
		_draw_wildflower(flower_spots[i],i+20)

func _draw_tree(p: Vector2, seed: int) -> void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(-13,22),p+Vector2(14,20),p+Vector2(19,88),p+Vector2(-19,88)]),Color("#785237"))
	draw_line(p+Vector2(-4,27),p+Vector2(-7,82),Color(0.82,0.61,0.38,0.22),3.0)
	var base: Color = Color("#4b8245") if seed%2==0 else Color("#5a904c")
	for j in range(8):
		var a: float = TAU*float(j)/8.0
		var cp: Vector2 = p+Vector2(cos(a)*37.0,sin(a)*28.0)+Vector2(0,-20)
		var r: float = 32.0+float((seed+j)%3)*5.0
		draw_circle(cp,r,base.lightened(float((j+seed)%3)*0.045))
	for j in range(12):
		var a2: float = TAU*float(j)/12.0
		var hp: Vector2 = p+Vector2(cos(a2)*37.0,sin(a2)*27.0)+Vector2(0,-30)
		draw_circle(hp,5.0+float(j%3),Color(0.82,0.92,0.48,0.14))

func _draw_farm_fence() -> void:
	var left: float = FarmWorld.ORIGIN.x-30.0
	var top: float = FarmWorld.ORIGIN.y-28.0
	var right: float = FarmWorld.ORIGIN.x+float(FarmWorld.COLS*FarmWorld.TILE_SIZE)+28.0
	var bottom: float = FarmWorld.ORIGIN.y+float(FarmWorld.ROWS*FarmWorld.TILE_SIZE)+28.0
	var rail: Color = Color("#87603f")
	draw_line(Vector2(left,top),Vector2(right,top),rail,4.0)
	draw_line(Vector2(left,bottom),Vector2(right,bottom),rail,4.0)
	draw_line(Vector2(left,top),Vector2(left,bottom),rail,4.0)
	draw_line(Vector2(right,top),Vector2(right,bottom-92),rail,4.0)
	for x in range(int(left),int(right)+1,96):
		_draw_post(Vector2(x,top))
		_draw_post(Vector2(x,bottom))
	for y in range(int(top),int(bottom)+1,96):
		_draw_post(Vector2(left,y))
		if y < int(bottom)-92:
			_draw_post(Vector2(right,y))

func _draw_post(p: Vector2) -> void:
	draw_rect(Rect2(p-Vector2(5,15),Vector2(10,30)),Color("#68482f"),true)
	draw_circle(p+Vector2(0,-11),7,Color("#a87b4f"))

func _draw_wildflower(p: Vector2, seed: int) -> void:
	var stem: Color = Color(0.26,0.48,0.24,0.75)
	var petal: Color = Color("#f3bfd0") if seed%3==0 else (Color("#f1d276") if seed%3==1 else Color("#f7f0d1"))
	draw_line(p,p+Vector2(0,-16),stem,1.6)
	for k in range(5):
		var a: float = TAU*float(k)/5.0
		draw_circle(p+Vector2(0,-18)+Vector2(cos(a),sin(a))*3.8,2.6,petal)
	draw_circle(p+Vector2(0,-18),1.9,Color("#b77e3c"))

func _draw_grass_cluster(p: Vector2, seed: int) -> void:
	for j in range(6):
		var x: float = (float(j)-2.5)*3.2
		var h: float = 7.0+float((seed+j)%4)*2.6
		var sway: float = sin(t*.45+float(seed+j))*1.5
		draw_line(p+Vector2(x,0),p+Vector2(x+sway,-h),Color(0.24,0.49,0.21,0.56),1.4)

func _draw_reeds(p: Vector2, seed: int) -> void:
	for j in range(3):
		var q: Vector2 = p+Vector2(float(j)*4.0,0)
		var lean: float = sin(t*.45+float(seed+j))*1.5
		draw_line(q,q+Vector2(lean,-20.0-float(j%2)*7.0),Color("#466d41"),1.8)
		if j==1:
			draw_circle(q+Vector2(lean,-24),2.3,Color("#82603f"))

func _draw_shadow(rect: Rect2) -> void:
	_draw_ellipse(rect.position+Vector2(rect.size.x*0.5,rect.size.y+10),Vector2(rect.size.x*0.44,14),Color(0.08,0.10,0.06,0.14))

func _draw_soft_rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect,color,true)
	draw_line(rect.position+Vector2(0,3),Vector2(rect.end.x,rect.position.y+3),Color(1.0,0.88,0.62,0.16),3.0)
	draw_line(Vector2(rect.position.x,rect.end.y-3),rect.end-Vector2(0,3),Color(0.28,0.43,0.20,0.13),3.0)

func _draw_blob(center: Vector2, radius: Vector2, color: Color, wobble: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(40):
		var a: float = TAU*float(i)/40.0
		var n: float = 1.0+sin(a*3.0+center.x*.01)*wobble+sin(a*7.0-center.y*.008)*wobble*.35
		pts.append(center+Vector2(cos(a)*radius.x*n,sin(a)*radius.y*n))
	draw_colored_polygon(pts,color)

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(30):
		var a: float = TAU*float(i)/30.0
		pts.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(pts,color)
