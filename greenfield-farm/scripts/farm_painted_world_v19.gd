extends "res://scripts/farm_painted_world_v18.gd"
class_name FarmPaintedWorldV19

func _draw() -> void:
	if not active or not farm:
		return
	_draw_painted_ground_v18()
	_draw_meadow_depth_v19()
	_draw_paths_v19()
	_draw_pond_and_river_v19()
	_draw_field_v18()
	_draw_buildings_v19()
	_draw_trees_and_gardens_v19()
	_draw_farm_fence_v19()
	_draw_shipping_bin_v18()
	_draw_npcs_v16()
	_draw_story_props_v19()

func _draw_meadow_depth_v19() -> void:
	# Stronger watercolor patches and visible meadow clusters fill the large empty lawn.
	var washes: Array[Dictionary] = [
		{"p":Vector2(300,650),"r":Vector2(250,125),"c":Color(0.30,0.56,0.20,0.075)},
		{"p":Vector2(640,735),"r":Vector2(285,145),"c":Color(0.78,0.72,0.28,0.052)},
		{"p":Vector2(405,930),"r":Vector2(270,130),"c":Color(0.38,0.63,0.22,0.060)},
		{"p":Vector2(790,980),"r":Vector2(250,120),"c":Color(0.84,0.73,0.33,0.045)},
		{"p":Vector2(1760,650),"r":Vector2(235,120),"c":Color(0.35,0.60,0.25,0.060)}
	]
	for item: Dictionary in washes:
		_draw_blob(item["p"],item["r"],item["c"],0.055)

	for i in range(128):
		var x: float = 55.0 + fmod(float(i*137 + (i%11)*47),1990.0)
		var y: float = 500.0 + fmod(float(i*97 + (i%7)*63),820.0)
		# Keep the pond and main paths readable.
		if x > 1140.0 and x < 1680.0 and y > 355.0 and y < 835.0:
			continue
		if x > 990.0 and x < 1175.0:
			continue
		if i % 9 == 0:
			_draw_shrub_v16(Vector2(x,y))
		elif i % 4 == 0:
			_draw_wildflower(Vector2(x,y),420+i)
		else:
			_draw_grass_cluster(Vector2(x,y),520+i)

	# A few pale stones give the meadow the illustrated reference's visual rhythm.
	for p: Vector2 in [Vector2(245,610),Vector2(575,670),Vector2(825,595),Vector2(330,880),Vector2(710,905),Vector2(1810,625),Vector2(1860,950)]:
		_draw_ellipse(p+Vector2(0,4),Vector2(13,5),Color(0.10,0.12,0.08,0.10))
		_draw_ellipse(p,Vector2(12,8),Color(0.76,0.75,0.63,0.48))

func _draw_paths_v19() -> void:
	# Soft, warmer paths with feathered watercolor edges instead of flat rectangles.
	_draw_soft_path_v19(Rect2(0,392,2304,88),false)
	_draw_soft_path_v19(Rect2(1028,392,94,900),true)
	_draw_soft_path_v19(Rect2(1028,792,1055,86),false)
	_draw_soft_path_v19(Rect2(1068,1112,1000,82),false)

func _draw_soft_path_v19(rect: Rect2, vertical: bool) -> void:
	var edge: Color = Color(0.67,0.53,0.31,0.20)
	var base: Color = Color("#d9b873")
	var wash: Color = Color(0.98,0.87,0.62,0.20)
	draw_rect(rect,base,true)
	if vertical:
		for y in range(int(rect.position.y)+15,int(rect.end.y),42):
			_draw_blob(Vector2(rect.position.x+2,float(y)),Vector2(12,22),edge,0.10)
			_draw_blob(Vector2(rect.end.x-2,float(y+17)),Vector2(13,24),edge,0.10)
	else:
		for x in range(int(rect.position.x)+20,int(rect.end.x),56):
			_draw_blob(Vector2(float(x),rect.position.y+2),Vector2(28,10),edge,0.10)
			_draw_blob(Vector2(float(x+23),rect.end.y-2),Vector2(30,10),edge,0.10)
	for i in range(22):
		var px: float = rect.position.x + 12.0 + fmod(float(i*73),maxf(22.0,rect.size.x-24.0))
		var py: float = rect.position.y + 10.0 + fmod(float(i*29),maxf(18.0,rect.size.y-20.0))
		_draw_ellipse(Vector2(px,py),Vector2(3.0+float(i%3),1.5+float(i%2)),Color(0.45,0.34,0.20,0.12))
	if vertical:
		draw_line(rect.position+Vector2(8,0),Vector2(rect.position.x+8,rect.end.y),wash,2.0)
	else:
		draw_line(rect.position+Vector2(0,8),Vector2(rect.end.x,rect.position.y+8),wash,2.0)

func _draw_pond_and_river_v19() -> void:
	# Keep the successful watercolor pond, with slightly more breathing room around it.
	draw_rect(Rect2(2104,0,18,FarmWorld.WORLD_SIZE.y),Color("#cbb17b"),true)
	draw_rect(Rect2(2122,0,182,FarmWorld.WORLD_SIZE.y),Color("#4b9fba"),true)
	for i in range(30):
		var yy: float = 34.0 + float(i)*48.0
		draw_line(Vector2(2148,yy),Vector2(2190+float(i%3)*7.0,yy+sin(t*.25+float(i))*1.6),Color(0.90,0.98,0.96,0.25),1.4)
	var pond_rect: Rect2 = Rect2(1240,418,356,360)
	_draw_ellipse(pond_rect.get_center()+Vector2(0,20),Vector2(155,43),Color(0.08,0.12,0.07,0.12))
	draw_texture_rect(POND_V17,pond_rect,false,Color.WHITE)
	for i in range(5):
		var a: float = t*0.14 + float(i)*1.03
		var p: Vector2 = pond_rect.get_center()+Vector2(cos(a)*float(28+i*12),sin(a*1.1)*float(13+i*6))
		draw_line(p-Vector2(7,0),p+Vector2(7,0),Color(0.96,1.0,0.95,0.18),1.2)

func _draw_buildings_v19() -> void:
	# Pull all buildings slightly inward and reduce their visual footprint so none are cropped.
	_draw_watercolor_building_v19(Rect2(185,92,420,304),Color.WHITE,"FARMHOUSE")
	_draw_watercolor_building_v19(Rect2(1600,95,360,262),Color(0.78,0.96,0.91,1.0),"GENERAL STORE")
	_draw_watercolor_building_v19(Rect2(1588,790,390,282),Color(0.89,0.93,1.0,1.0),"TOWN HALL")
	_draw_watercolor_building_v19(Rect2(260,1058,388,280),Color(1.0,0.73,0.66,1.0),"BARN")

func _draw_watercolor_building_v19(rect: Rect2, tint: Color, kind: String) -> void:
	_draw_ellipse(Vector2(rect.position.x+rect.size.x*0.5,rect.end.y-5),Vector2(rect.size.x*0.34,16),Color(0.06,0.08,0.04,0.12))
	draw_texture_rect(HOUSE_V17,rect,false,tint)
	if kind == "FARMHOUSE":
		for i in range(5):
			_draw_wildflower(rect.position+Vector2(75.0+float(i)*58.0,rect.size.y-13.0+sin(float(i))*4.0),610+i)
	elif kind == "GENERAL STORE":
		# Wide green awning and baskets make the shop instantly distinct from the farmhouse.
		var awning: Rect2 = Rect2(rect.position+Vector2(rect.size.x*0.50,rect.size.y*0.62),Vector2(rect.size.x*0.42,30))
		draw_rect(awning,Color(0.38,0.62,0.49,0.93),true)
		for i in range(6):
			if i % 2 == 0:
				draw_rect(Rect2(awning.position+Vector2(float(i)*awning.size.x/6.0,0),Vector2(awning.size.x/6.0,awning.size.y)),Color(0.94,0.82,0.58,0.78),true)
		for bx: float in [rect.position.x+rect.size.x*0.55,rect.position.x+rect.size.x*0.84]:
			_draw_ellipse(Vector2(bx,rect.end.y-10),Vector2(24,8),Color(0.25,0.18,0.10,0.14))
			draw_rect(Rect2(bx-20,rect.end.y-36,40,25),Color("#9b683d"),true)
		var sign_r: Rect2 = Rect2(rect.position+Vector2(rect.size.x*0.57,rect.size.y*0.46),Vector2(124,31))
		draw_rect(sign_r,Color(0.45,0.29,0.17,0.92),true)
		draw_string(ThemeDB.fallback_font,sign_r.position+Vector2(6,21),"GENERAL STORE",HORIZONTAL_ALIGNMENT_CENTER,112,11,Color("#fff1c9"))
	elif kind == "TOWN HALL":
		# Clock, pale stone steps and twin flag posts establish a civic silhouette.
		var clock_c: Vector2 = rect.position+Vector2(rect.size.x*0.50,rect.size.y*0.28)
		draw_circle(clock_c,23,Color(0.97,0.92,0.74,0.94))
		draw_circle(clock_c,23,Color("#615746"),false,3.0)
		draw_line(clock_c,clock_c+Vector2(0,-11),Color("#584836"),3.0)
		draw_line(clock_c,clock_c+Vector2(10,5),Color("#584836"),3.0)
		for k in range(3):
			draw_rect(Rect2(rect.position+Vector2(rect.size.x*0.34-float(k)*10.0,rect.size.y*0.83+float(k)*9.0),Vector2(rect.size.x*0.32+float(k)*20.0,9)),Color(0.72,0.69,0.60,0.72),true)
	elif kind == "BARN":
		# A strong red wash, oversized cross-braced doors and hay bundles distinguish the barn.
		draw_rect(Rect2(rect.position+Vector2(rect.size.x*0.08,rect.size.y*0.24),Vector2(rect.size.x*0.84,rect.size.y*0.60)),Color(0.60,0.20,0.16,0.20),true)
		var door: Rect2 = Rect2(rect.position+Vector2(rect.size.x*0.34,rect.size.y*0.51),Vector2(rect.size.x*0.32,rect.size.y*0.39))
		draw_rect(door,Color(0.36,0.20,0.12,0.93),true)
		draw_line(Vector2(door.position.x+door.size.x*0.5,door.position.y),Vector2(door.position.x+door.size.x*0.5,door.end.y),Color("#d2a06b"),3.0)
		draw_line(door.position+Vector2(8,8),door.end-Vector2(8,8),Color("#c88b57"),5.0)
		draw_line(Vector2(door.end.x-8,door.position.y+8),Vector2(door.position.x+8,door.end.y-8),Color("#c88b57"),5.0)
		for i in range(3):
			_draw_ellipse(rect.position+Vector2(62.0+float(i)*32.0,rect.size.y-19.0),Vector2(22,10),Color("#d8b35f"))

func _draw_trees_and_gardens_v19() -> void:
	# Keep trees away from screen edges and create clustered groves rather than isolated stamps.
	var tree_rects: Array[Rect2] = [
		Rect2(640,84,158,205),Rect2(810,126,172,223),Rect2(1870,388,168,218),
		Rect2(1970,580,142,184),Rect2(705,1140,164,213),Rect2(1410,1150,180,234),
		Rect2(1845,1210,158,205),Rect2(90,1170,170,221)
	]
	for i in range(tree_rects.size()):
		var r: Rect2 = tree_rects[i]
		var tint: Color = Color.WHITE
		if i % 3 == 1:
			tint = Color(1.0,0.96,0.86,0.98)
		elif i % 3 == 2:
			tint = Color(0.92,1.0,0.92,0.98)
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-7),Vector2(r.size.x*0.28,10),Color(0.05,0.08,0.04,0.12))
		draw_texture_rect(TREE_V17,r,false,tint)
	for i in range(20):
		_draw_wildflower(Vector2(130.0+float(i)*98.0,380.0+sin(float(i)*1.75)*9.0),720+i)
	for i in range(12):
		_draw_wildflower(Vector2(1170.0+float(i)*72.0,870.0+sin(float(i)*1.23)*10.0),760+i)

func _draw_farm_fence_v19() -> void:
	var left: float = FarmWorld.ORIGIN.x-28.0
	var top: float = FarmWorld.ORIGIN.y-5.0
	var right: float = FarmWorld.ORIGIN.x+float(FarmWorld.COLS*FarmWorld.TILE_SIZE)+12.0
	var bottom: float = FarmWorld.ORIGIN.y+float(FarmWorld.ROWS*FarmWorld.TILE_SIZE)+12.0
	var dark: Color = Color("#795638")
	var light: Color = Color("#b18759")
	# Rails are thinner, warmer and interrupted near the road entrance.
	for yy: float in [top,bottom]:
		draw_line(Vector2(left,yy),Vector2(right,yy+2),dark,4.0)
		draw_line(Vector2(left,yy-2),Vector2(right,yy),light,1.5)
	for x in range(int(left),int(right)+1,132):
		if float(x) > 980.0:
			continue
		_draw_post_v18(Vector2(float(x),top))
		_draw_post_v18(Vector2(float(x),bottom))
	for y in range(int(top),int(bottom)+1,135):
		_draw_post_v18(Vector2(left,float(y)))
		if float(y) < bottom-120.0:
			_draw_post_v18(Vector2(right,float(y)))

func _draw_story_props_v19() -> void:
	# Small, unobtrusive watercolor town sign.
	var sign_pos: Vector2 = Vector2(960,415)
	draw_line(sign_pos,sign_pos+Vector2(0,48),Color("#6e5037"),6.0)
	_draw_blob(sign_pos+Vector2(0,-1),Vector2(43,17),Color(0.76,0.58,0.36,0.94),0.04)
	draw_string(ThemeDB.fallback_font,sign_pos+Vector2(-29,4),"TOWN",HORIZONTAL_ALIGNMENT_CENTER,58,10,Color("#59412e"))
	for p: Vector2 in [Vector2(1120,468),Vector2(1120,850),Vector2(1540,850),Vector2(1940,850)]:
		draw_line(p,p+Vector2(0,-34),Color("#62503b"),4.0)
		_draw_blob(p+Vector2(0,-43),Vector2(9,11),Color(0.34,0.28,0.21,0.94),0.05)
		draw_circle(p+Vector2(0,-43),4.0,Color(1.0,0.80,0.38,0.85))
