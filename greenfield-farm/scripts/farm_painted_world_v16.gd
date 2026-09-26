extends "res://scripts/farm_painted_world_v15_active.gd"
class_name FarmPaintedWorldV16

const ROWAN_TEX_V16: Texture2D = preload("res://assets/art/npc_rowan.svg")
const LINA_TEX_V16: Texture2D = preload("res://assets/art/npc_lina.svg")
const MARNIE_TEX_V16: Texture2D = preload("res://assets/art/npc_marnie.svg")

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
	_draw_shipping_bin_v16()
	_draw_npcs_v16()

func _draw_painted_ground() -> void:
	# v1.6 deliberately does not tile the v1.5 grass image. The old image had
	# a stone/hedge stripe that repeated every tile and made the world look like wallpaper.
	draw_rect(Rect2(Vector2.ZERO, FarmWorld.WORLD_SIZE), Color("#87bd62"), true)

	var washes: Array[Dictionary] = [
		{"p":Vector2(310,245),"r":Vector2(430,255),"c":Color(0.95,0.83,0.39,0.075)},
		{"p":Vector2(780,320),"r":Vector2(520,285),"c":Color(0.44,0.70,0.31,0.070)},
		{"p":Vector2(470,930),"r":Vector2(520,340),"c":Color(0.93,0.81,0.38,0.055)},
		{"p":Vector2(1420,920),"r":Vector2(640,390),"c":Color(0.31,0.59,0.27,0.060)},
		{"p":Vector2(1900,300),"r":Vector2(360,250),"c":Color(0.95,0.86,0.52,0.045)}
	]
	for item: Dictionary in washes:
		_draw_blob(item["p"], item["r"], item["c"], 0.075)

	# Irregular low-contrast pigment speckles and grass marks. Coordinates are
	# deterministic but intentionally non-grid-like.
	for i in range(240):
		var x: float = 22.0 + fmod(float(i * 173 + (i % 11) * 41), 2250.0)
		var y: float = 28.0 + fmod(float(i * 97 + (i % 7) * 53), 1470.0)
		var s: float = 1.2 + float(i % 4) * 0.55
		var col: Color = Color(0.22,0.45,0.19,0.16) if i % 3 != 0 else Color(0.86,0.77,0.34,0.12)
		draw_circle(Vector2(x,y),s,col)
		if i % 4 == 0:
			var h: float = 5.0 + float(i % 5) * 1.5
			var lean: float = sin(float(i)*1.37 + t*0.18) * 1.8
			draw_line(Vector2(x,y+2),Vector2(x+lean,y-h),Color(0.20,0.43,0.19,0.32),1.1)

func _draw_paths() -> void:
	var sand: Color = Color("#dcb874")
	# Narrower paths restore the scale relationship between the farmer and the world.
	_draw_path_rect(Rect2(0,398,FarmWorld.WORLD_SIZE.x,64), sand, false)
	_draw_path_rect(Rect2(1034,430,70,846), sand, true)
	_draw_path_rect(Rect2(1034,810,1060,64), sand, false)
	_draw_path_rect(Rect2(1070,1130,1000,62), sand, false)

	for i in range(25):
		var x: float = 34.0 + float(i) * 92.0
		var top_y: float = 398.0 + sin(float(i)*1.31)*3.0
		var bottom_y: float = 462.0 + cos(float(i)*1.17)*3.0
		_draw_grass_cluster(Vector2(x,top_y),i)
		if i % 2 == 0:
			_draw_grass_cluster(Vector2(x+37.0,bottom_y+7.0),i+50)

func _draw_path_rect(rect: Rect2, color: Color, vertical: bool) -> void:
	draw_rect(rect,color,true)
	var highlight: Color = Color(1.0,0.89,0.65,0.18)
	var shade: Color = Color(0.38,0.30,0.19,0.12)
	if vertical:
		draw_line(rect.position+Vector2(3,0),Vector2(rect.position.x+3,rect.end.y),highlight,2.0)
		draw_line(Vector2(rect.end.x-3,rect.position.y),rect.end-Vector2(3,0),shade,2.0)
	else:
		draw_line(rect.position+Vector2(0,3),Vector2(rect.end.x,rect.position.y+3),highlight,2.0)
		draw_line(Vector2(rect.position.x,rect.end.y-3),rect.end-Vector2(0,3),shade,2.0)
	var count: int = 12 if vertical else 28
	for i in range(count):
		var px: float
		var py: float
		if vertical:
			px = rect.position.x + 12.0 + fmod(float(i*19),maxf(18.0,rect.size.x-24.0))
			py = rect.position.y + 24.0 + fmod(float(i*71),maxf(30.0,rect.size.y-48.0))
		else:
			px = rect.position.x + 24.0 + fmod(float(i*83),maxf(40.0,rect.size.x-48.0))
			py = rect.position.y + 12.0 + fmod(float(i*17),maxf(18.0,rect.size.y-24.0))
		draw_circle(Vector2(px,py),1.8+float(i%3),Color(0.47,0.35,0.22,0.15))

func _draw_pond_and_river() -> void:
	# River remains on the far-east edge but uses a softer, narrower bank.
	draw_rect(Rect2(2104,0,18,FarmWorld.WORLD_SIZE.y),Color("#cbb17b"),true)
	draw_rect(Rect2(2122,0,182,FarmWorld.WORLD_SIZE.y),Color("#4b9fba"),true)
	for i in range(34):
		var y: float = 30.0 + float(i)*44.0
		var width: float = 24.0 + float(i%4)*9.0
		draw_line(Vector2(2150.0,y),Vector2(2150.0+width,y+sin(t*.28+float(i))*1.7),Color(0.87,0.97,0.94,0.29),1.4)

	# Smaller pond, positioned so the existing fishing marker at x=1535 sits on its east bank.
	var c: Vector2 = Vector2(1405,570)
	_draw_blob(c+Vector2(5,8),Vector2(163,132),Color(0.16,0.23,0.16,0.15),0.050)
	_draw_blob(c,Vector2(157,127),Color("#d0b779"),0.047)
	_draw_blob(c,Vector2(147,118),Color("#6e9d5f"),0.043)
	_draw_blob(c+Vector2(-3,-2),Vector2(137,108),Color("#4ca4bb"),0.038)
	_draw_blob(c+Vector2(-8,-9),Vector2(124,91),Color(0.43,0.80,0.82,0.23),0.034)

	for i in range(10):
		var a: float = t*.16 + float(i)*.67
		var p: Vector2 = c + Vector2(cos(a*1.15)*(24.0+float(i)*8.0),sin(a)*(11.0+float(i)*4.0))
		var half_w: float = 7.0+float(i%3)*3.5
		draw_line(p-Vector2(half_w,0),p+Vector2(half_w,0),Color(0.93,0.99,0.95,0.28),1.4)

	for off: Vector2 in [Vector2(-45,-24),Vector2(38,28),Vector2(63,-29)]:
		_draw_ellipse(c+off,Vector2(12,7),Color("#6ca254"))
		draw_circle(c+off+Vector2(3,-2),2.2,Color("#f2b6cb"))

	# Small wooden dock on the west/south-west bank.
	for k in range(4):
		var board_pos: Vector2 = c + Vector2(-158.0+float(k)*22.0,58.0+float(k%2)*1.5)
		draw_rect(Rect2(board_pos,Vector2(27,14)),Color("#9f6f42"),true)
		draw_line(board_pos+Vector2(1,2),board_pos+Vector2(25,2),Color("#d2a36a"),1.7)
	for px: float in [-162.0,-75.0]:
		draw_rect(Rect2(c+Vector2(px,50),Vector2(7,36)),Color("#67472f"),true)

	for i in range(14):
		var aa: float = -2.75 + float(i)*0.38
		if i > 5 and i < 8:
			continue
		_draw_reeds(c+Vector2(cos(aa)*153.0,sin(aa)*121.0),i)

func _draw_field() -> void:
	var field_rect: Rect2 = Rect2(FarmWorld.ORIGIN-Vector2(14,4),Vector2(FarmWorld.COLS*FarmWorld.TILE_SIZE+28,FarmWorld.ROWS*FarmWorld.TILE_SIZE+18))
	# A single fertile clearing replaces any checkerboard impression.
	_draw_blob(field_rect.get_center(),field_rect.size*0.495,Color(0.52,0.72,0.35,0.095),0.020)
	_draw_blob(field_rect.get_center()+Vector2(-18,16),field_rect.size*Vector2(0.43,0.41),Color(0.76,0.78,0.38,0.030),0.032)

	# Sparse field-edge marks make the farm readable without drawing a grid.
	for i in range(18):
		var px: float = field_rect.position.x + 35.0 + float(i)*49.0
		if i % 3 == 0:
			_draw_grass_cluster(Vector2(px,field_rect.position.y+12.0),i+80)

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

func _draw_trees_and_gardens() -> void:
	# Trees are intentionally moved away from the very top camera edge and are a little smaller.
	var trees: Array[Vector2] = [
		Vector2(120,185),Vector2(735,175),Vector2(900,245),Vector2(2010,500),
		Vector2(780,1240),Vector2(1510,1280),Vector2(2020,1350),Vector2(145,1320)
	]
	for i in range(trees.size()):
		_draw_tree_v16(trees[i],i)

	var flower_spots: Array[Vector2] = [
		Vector2(225,365),Vector2(288,374),Vector2(515,367),Vector2(590,378),
		Vector2(840,370),Vector2(925,365),Vector2(1180,755),Vector2(1580,748),
		Vector2(1730,765),Vector2(1860,715),Vector2(1210,1015),Vector2(1510,1045)
	]
	for i in range(flower_spots.size()):
		_draw_wildflower(flower_spots[i],i+40)

	# Small shrubs visually break up large empty grass areas.
	for p: Vector2 in [Vector2(690,560),Vector2(880,1040),Vector2(1710,1010),Vector2(1880,620),Vector2(1540,1180)]:
		_draw_shrub_v16(p)

func _draw_tree_v16(p: Vector2, seed: int) -> void:
	_draw_ellipse(p+Vector2(0,69),Vector2(34,9),Color(0.08,0.10,0.06,0.14))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-10,15),p+Vector2(11,14),p+Vector2(15,68),p+Vector2(-14,68)]),Color("#775137"))
	draw_line(p+Vector2(-3,20),p+Vector2(-5,62),Color(0.88,0.67,0.43,0.20),2.2)
	var base: Color = Color("#4f8748") if seed%2==0 else Color("#5b904f")
	for j in range(7):
		var a: float = TAU*float(j)/7.0
		var cp: Vector2 = p+Vector2(cos(a)*29.0,sin(a)*21.0)+Vector2(0,-17)
		var r: float = 25.0+float((seed+j)%3)*4.0
		draw_circle(cp,r,base.lightened(float((j+seed)%3)*0.04))
	for j in range(8):
		var a2: float = TAU*float(j)/8.0
		var hp: Vector2 = p+Vector2(cos(a2)*27.0,sin(a2)*19.0)+Vector2(0,-24)
		draw_circle(hp,4.0+float(j%2),Color(0.83,0.92,0.50,0.13))

func _draw_shrub_v16(p: Vector2) -> void:
	_draw_ellipse(p+Vector2(0,10),Vector2(22,5),Color(0.08,0.10,0.05,0.12))
	draw_circle(p+Vector2(-10,0),13,Color("#4f8b48"))
	draw_circle(p+Vector2(9,-2),15,Color("#60a054"))
	draw_circle(p+Vector2(0,-10),13,Color("#6aab59"))

func _draw_farm_fence() -> void:
	var left: float = FarmWorld.ORIGIN.x-28.0
	var top: float = FarmWorld.ORIGIN.y-5.0
	var right: float = FarmWorld.ORIGIN.x+float(FarmWorld.COLS*FarmWorld.TILE_SIZE)+12.0
	var bottom: float = FarmWorld.ORIGIN.y+float(FarmWorld.ROWS*FarmWorld.TILE_SIZE)+12.0
	var rail: Color = Color(0.45,0.31,0.20,0.66)

	# Lighter, thinner fencing; the top rail now sits below the road rather than through it.
	draw_line(Vector2(left,top),Vector2(right,top),rail,2.5)
	draw_line(Vector2(left,bottom),Vector2(right,bottom),rail,2.5)
	draw_line(Vector2(left,top),Vector2(left,bottom),rail,2.5)
	draw_line(Vector2(right,top),Vector2(right,bottom-108.0),rail,2.5)

	for x in range(int(left),int(right)+1,128):
		_draw_post_v16(Vector2(float(x),top))
		_draw_post_v16(Vector2(float(x),bottom))
	for y in range(int(top),int(bottom)+1,128):
		_draw_post_v16(Vector2(left,float(y)))
		if float(y) < bottom-108.0:
			_draw_post_v16(Vector2(right,float(y)))

func _draw_post_v16(p: Vector2) -> void:
	draw_rect(Rect2(p-Vector2(4,11),Vector2(8,22)),Color("#67482f"),true)
	draw_circle(p+Vector2(0,-8),5.0,Color("#987049"))

func _draw_shipping_bin_v16() -> void:
	var p: Vector2 = FarmWorld.SHIPPING_BIN
	_draw_ellipse(p+Vector2(0,29),Vector2(37,7),Color(0.05,0.05,0.03,0.14))
	var body: PackedVector2Array = PackedVector2Array([
		p+Vector2(-32,-21),p+Vector2(31,-23),p+Vector2(34,24),p+Vector2(-30,25)
	])
	draw_colored_polygon(body,Color("#8b5d39"))
	for yy: float in [-13.0,0.0,13.0]:
		draw_line(p+Vector2(-26,yy),p+Vector2(26,yy-1),Color("#b47c4e"),2.2)
	draw_colored_polygon(PackedVector2Array([
		p+Vector2(-37,-28),p+Vector2(36,-30),p+Vector2(32,-20),p+Vector2(-34,-18)
	]),Color("#5d402d"))
	draw_rect(Rect2(p+Vector2(-10,-12),Vector2(20,18)),Color("#d5b77b"),true)
	draw_rect(Rect2(p+Vector2(-6,-8),Vector2(12,10)),Color("#725137"),true)

func _draw_npcs_v16() -> void:
	_draw_npc_v16(_npc_pos_v16(FarmWorld.MAYOR_SPOT,0.0),ROWAN_TEX_V16,"ROWAN")
	_draw_npc_v16(_npc_pos_v16(FarmWorld.LINA_SPOT,1.7),LINA_TEX_V16,"LINA")
	_draw_npc_v16(_npc_pos_v16(FarmWorld.MARNIE_SPOT,3.2),MARNIE_TEX_V16,"MARNIE")

func _npc_pos_v16(base: Vector2, phase: float) -> Vector2:
	return base + Vector2(sin(farm.npc_phase*0.55+phase)*20.0,cos(farm.npc_phase*0.42+phase)*8.0)

func _draw_npc_v16(p: Vector2, tex: Texture2D, label: String) -> void:
	_draw_ellipse(p+Vector2(0,36),Vector2(25,6),Color(0.04,0.05,0.03,0.17))
	draw_texture_rect(tex,Rect2(p+Vector2(-29,-49),Vector2(58,79)),false,Color(1.0,0.99,0.95,1.0))
	draw_rect(Rect2(p+Vector2(-28,39),Vector2(56,16)),Color(0.16,0.14,0.10,0.74),true)
	draw_line(p+Vector2(-21,39),p+Vector2(21,39),Color("#d6b267"),1.1)
	draw_string(ThemeDB.fallback_font,p+Vector2(-24,51),label,HORIZONTAL_ALIGNMENT_CENTER,48,8,Color("#fff0cf"))
