extends "res://scripts/farm_painted_world_v17.gd"
class_name FarmPaintedWorldV18

func _draw() -> void:
	if not active or not farm:
		return
	_draw_painted_ground_v18()
	_draw_paths()
	_draw_pond_and_river_v18()
	_draw_field_v18()
	_draw_buildings_v18()
	_draw_trees_and_gardens_v18()
	_draw_farm_fence_v18()
	_draw_shipping_bin_v18()
	_draw_npcs_v16()
	_draw_story_props_v18()

func _draw_painted_ground_v18() -> void:
	_draw_painted_ground()
	# Layered watercolor meadow washes remove empty flat areas without creating a tile grid.
	var meadow_patches: Array[Dictionary] = [
		{"p":Vector2(360,640),"r":Vector2(290,150),"c":Color(0.42,0.65,0.27,0.055)},
		{"p":Vector2(760,860),"r":Vector2(360,210),"c":Color(0.80,0.75,0.29,0.045)},
		{"p":Vector2(1420,930),"r":Vector2(410,220),"c":Color(0.37,0.60,0.25,0.052)},
		{"p":Vector2(1840,600),"r":Vector2(270,170),"c":Color(0.88,0.78,0.38,0.038)}
	]
	for item: Dictionary in meadow_patches:
		_draw_blob(item["p"],item["r"],item["c"],0.060)
	# Dense but irregular storybook meadow details.
	for i in range(72):
		var x: float = 90.0 + fmod(float(i*181 + (i%7)*53),2050.0)
		var y: float = 520.0 + fmod(float(i*113 + (i%5)*71),850.0)
		if x > 1070.0 and x < 1650.0 and y > 360.0 and y < 850.0:
			continue
		if i % 4 == 0:
			_draw_wildflower(Vector2(x,y),i+200)
		elif i % 3 == 0:
			_draw_grass_cluster(Vector2(x,y),i+230)
		else:
			_draw_ellipse(Vector2(x,y),Vector2(7.0+float(i%4)*2.0,3.0+float(i%3)),Color(0.20,0.40,0.14,0.035))

func _draw_pond_and_river_v18() -> void:
	# Keep functional river but make pond about 13 percent smaller than v1.7.
	draw_rect(Rect2(2104,0,18,FarmWorld.WORLD_SIZE.y),Color("#cbb17b"),true)
	draw_rect(Rect2(2122,0,182,FarmWorld.WORLD_SIZE.y),Color("#4b9fba"),true)
	for i in range(30):
		var yy: float = 34.0 + float(i)*48.0
		draw_line(Vector2(2148,yy),Vector2(2190+float(i%3)*7.0,yy+sin(t*.25+float(i))*1.6),Color(0.90,0.98,0.96,0.25),1.4)
	var pond_rect: Rect2 = Rect2(1225,405,374,378)
	_draw_ellipse(pond_rect.get_center()+Vector2(0,20),Vector2(164,45),Color(0.08,0.12,0.07,0.12))
	draw_texture_rect(POND_V17,pond_rect,false,Color.WHITE)
	for i in range(5):
		var a: float = t*0.14 + float(i)*1.03
		var p: Vector2 = pond_rect.get_center()+Vector2(cos(a)*float(28+i*13),sin(a*1.1)*float(13+i*7))
		draw_line(p-Vector2(8,0),p+Vector2(8,0),Color(0.96,1.0,0.95,0.18),1.3)

func _draw_buildings_v18() -> void:
	# Every outdoor building now uses the authored watercolor cottage as the visual base,
	# then gets its own palette and storybook facade details. No legacy vector building remains.
	_draw_watercolor_building_v18(Rect2(140,78,470,340),Color.WHITE,"FARMHOUSE")
	_draw_watercolor_building_v18(Rect2(1570,78,420,304),Color(0.80,0.96,0.93,1.0),"GENERAL STORE")
	_draw_watercolor_building_v18(Rect2(1628,770,440,318),Color(0.89,0.92,1.0,1.0),"TOWN HALL")
	_draw_watercolor_building_v18(Rect2(216,1035,444,321),Color(1.0,0.76,0.70,1.0),"BARN")

func _draw_watercolor_building_v18(rect: Rect2, tint: Color, kind: String) -> void:
	_draw_ellipse(Vector2(rect.position.x+rect.size.x*0.5,rect.end.y-8),Vector2(rect.size.x*0.37,18),Color(0.06,0.08,0.04,0.13))
	draw_texture_rect(HOUSE_V17,rect,false,tint)
	if kind == "GENERAL STORE":
		# Soft cloth awning and hanging wooden sign.
		var y: float = rect.position.y + rect.size.y*0.69
		draw_rect(Rect2(rect.position+Vector2(rect.size.x*0.57,rect.size.y*0.67),Vector2(rect.size.x*0.30,22)),Color(0.91,0.78,0.55,0.86),true)
		for i in range(5):
			if i % 2 == 0:
				draw_rect(Rect2(rect.position+Vector2(rect.size.x*(0.58+float(i)*0.055),rect.size.y*0.67),Vector2(rect.size.x*0.04,22)),Color(0.40,0.63,0.57,0.82),true)
		var sign_pos: Vector2 = rect.position+Vector2(rect.size.x*0.64,rect.size.y*0.54)
		draw_line(sign_pos,sign_pos+Vector2(0,31),Color("#6b4a31"),4.0)
		draw_rect(Rect2(sign_pos+Vector2(-12,25),Vector2(128,34)),Color(0.55,0.34,0.19,0.92),true)
		draw_string(ThemeDB.fallback_font,sign_pos+Vector2(-2,47),"GENERAL STORE",HORIZONTAL_ALIGNMENT_CENTER,106,12,Color("#fff0c8"))
	elif kind == "TOWN HALL":
		var clock_c: Vector2 = rect.position+Vector2(rect.size.x*0.50,rect.size.y*0.28)
		draw_circle(clock_c,25,Color(0.97,0.91,0.73,0.90))
		draw_circle(clock_c,25,Color("#6b5b49"),false,3.0)
		draw_line(clock_c,clock_c+Vector2(0,-12),Color("#584836"),3.0)
		draw_line(clock_c,clock_c+Vector2(12,5),Color("#584836"),3.0)
	elif kind == "BARN":
		var door: Rect2 = Rect2(rect.position+Vector2(rect.size.x*0.37,rect.size.y*0.57),Vector2(rect.size.x*0.27,rect.size.y*0.33))
		draw_rect(door,Color(0.40,0.23,0.13,0.90),true)
		draw_line(Vector2(door.position.x+door.size.x*0.5,door.position.y),Vector2(door.position.x+door.size.x*0.5,door.end.y),Color("#d3a16b"),3.0)
		draw_line(door.position+Vector2(8,8),door.end-Vector2(8,8),Color("#c68a58"),5.0)
		draw_line(Vector2(door.end.x-8,door.position.y+8),Vector2(door.position.x+8,door.end.y-8),Color("#c68a58"),5.0)

func _draw_field_v18() -> void:
	var field_rect: Rect2 = Rect2(FarmWorld.ORIGIN-Vector2(18,10),Vector2(FarmWorld.COLS*FarmWorld.TILE_SIZE+36,FarmWorld.ROWS*FarmWorld.TILE_SIZE+26))
	_draw_blob(field_rect.get_center(),field_rect.size*0.50,Color(0.55,0.73,0.34,0.080),0.028)
	# A few natural flower/grass islands break the empty field without blocking farm cells.
	for p: Vector2 in [Vector2(190,570),Vector2(340,930),Vector2(690,565),Vector2(910,930),Vector2(540,1010)]:
		_draw_grass_cluster(p,int(p.x+p.y))
	for y in range(FarmWorld.ROWS):
		for x in range(FarmWorld.COLS):
			var cell: Vector2i = Vector2i(x,y)
			var data: Dictionary = farm.get_cell(cell)
			if not bool(data.get("tilled",false)):
				continue
			var center: Vector2 = farm.cell_to_world(cell)
			var wet: bool = bool(data.get("watered",false))
			_draw_watercolor_soil_v18(center,wet,x+y*FarmWorld.COLS)
			var crop: String = String(data.get("crop",""))
			if crop != "":
				_draw_watercolor_crop_v18(center,crop,int(data.get("stage",0)))

func _draw_watercolor_soil_v18(center: Vector2, wet: bool, seed: int) -> void:
	var base: Color = Color("#6f5548") if wet else Color("#9a6d4b")
	_draw_blob(center+Vector2(0,4),Vector2(28,21),Color(0.05,0.04,0.03,0.09),0.065)
	_draw_blob(center,Vector2(27,20),base,0.070)
	for i in range(3):
		var yy: float = center.y-10.0+float(i)*9.0
		draw_line(Vector2(center.x-19,yy),Vector2(center.x+20,yy+sin(float(seed+i))*1.5),Color(0.86,0.65,0.43,0.18 if not wet else 0.10),1.4)

func _draw_watercolor_crop_v18(center: Vector2, crop: String, stage: int) -> void:
	var s: int = clampi(stage,0,3)
	var sway: float = sin(t*1.2+center.x*0.013)*1.5
	var leaf: Color = Color("#4f8f4b")
	var accent: Color = Color("#f2eee3")
	if crop == "carrot":
		accent = Color("#ee8d39")
	elif crop == "corn":
		accent = Color("#efcb58")
	var count: int = 2+s*2
	for i in range(count):
		var ang: float = -0.75 + float(i)*1.5/maxf(1.0,float(count-1))
		var length: float = 10.0+float(s)*5.0+float(i%2)*2.0
		var tip: Vector2 = center+Vector2(sin(ang)*length*0.65+sway,-8.0-cos(ang)*length)
		draw_line(center+Vector2(0,-3),tip,leaf,2.2+float(s)*0.5)
		draw_circle(tip,3.0+float(s),leaf.lightened(0.08))
	if s >= 2:
		if crop == "turnip":
			draw_circle(center+Vector2(0,3),7.0+float(s),accent)
			draw_circle(center+Vector2(0,6),3.0,Color("#e9a9b7"))
		elif crop == "carrot":
			draw_colored_polygon(PackedVector2Array([center+Vector2(-6,0),center+Vector2(6,0),center+Vector2(0,18)]),accent)
		else:
			draw_rect(Rect2(center+Vector2(-5,-16),Vector2(10,26)),accent,true)

func _draw_trees_and_gardens_v18() -> void:
	# More size/position diversity than v1.7 gives the grove a less stamped appearance.
	var tree_rects: Array[Rect2] = [
		Rect2(20,135,155,201),Rect2(500,86,185,240),Rect2(690,118,150,195),Rect2(850,150,176,228),
		Rect2(1870,400,184,239),Rect2(2020,540,140,182),Rect2(660,1135,165,214),Rect2(1420,1150,188,244),
		Rect2(1888,1212,160,208),Rect2(50,1185,180,234)
	]
	for i in range(tree_rects.size()):
		var r: Rect2 = tree_rects[i]
		var tint: Color = Color.WHITE
		if i % 4 == 1:
			tint = Color(1.0,0.96,0.84,0.97)
		elif i % 4 == 2:
			tint = Color(0.91,1.0,0.91,0.97)
		elif i % 4 == 3:
			tint = Color(0.96,0.94,1.0,0.97)
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-7),Vector2(r.size.x*0.28,10),Color(0.05,0.08,0.04,0.12))
		draw_texture_rect(TREE_V17,r,false,tint)
	# Flower ribbons along roads and cottage garden.
	for i in range(18):
		_draw_wildflower(Vector2(160.0+float(i)*105.0,382.0+sin(float(i)*1.8)*8.0),i+300)
	for i in range(10):
		_draw_wildflower(Vector2(1190.0+float(i)*72.0,850.0+sin(float(i)*1.3)*9.0),i+340)

func _draw_farm_fence_v18() -> void:
	var left: float = FarmWorld.ORIGIN.x-28.0
	var top: float = FarmWorld.ORIGIN.y-5.0
	var right: float = FarmWorld.ORIGIN.x+float(FarmWorld.COLS*FarmWorld.TILE_SIZE)+12.0
	var bottom: float = FarmWorld.ORIGIN.y+float(FarmWorld.ROWS*FarmWorld.TILE_SIZE)+12.0
	var dark: Color = Color("#6f4b31")
	var light: Color = Color("#a97849")
	# Two hand-painted rails and uneven posts.
	for yy: float in [top,bottom]:
		draw_line(Vector2(left,yy),Vector2(right,yy+3),dark,5.0)
		draw_line(Vector2(left,yy-3),Vector2(right,yy),light,2.0)
	for x in range(int(left),int(right)+1,120):
		_draw_post_v18(Vector2(float(x),top))
		_draw_post_v18(Vector2(float(x),bottom))
	for y in range(int(top),int(bottom)+1,122):
		_draw_post_v18(Vector2(left,float(y)))
		if float(y) < bottom-108.0:
			_draw_post_v18(Vector2(right,float(y)))

func _draw_post_v18(p: Vector2) -> void:
	var lean: float = sin(p.x*0.017+p.y*0.013)*2.2
	draw_line(p+Vector2(lean,-12),p+Vector2(0,14),Color("#68452d"),9.0)
	draw_circle(p+Vector2(lean,-11),5.0,Color("#a57b50"))

func _draw_shipping_bin_v18() -> void:
	var p: Vector2 = FarmWorld.SHIPPING_BIN
	_draw_ellipse(p+Vector2(0,28),Vector2(39,8),Color(0.05,0.05,0.03,0.14))
	var body: PackedVector2Array = PackedVector2Array([p+Vector2(-35,-21),p+Vector2(31,-24),p+Vector2(37,24),p+Vector2(-30,28)])
	draw_colored_polygon(body,Color("#8a5a37"))
	for yy: float in [-14.0,-1.0,12.0]:
		draw_line(p+Vector2(-29,yy),p+Vector2(30,yy-2),Color("#c28a57"),3.0)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-40,-29),p+Vector2(37,-31),p+Vector2(32,-19),p+Vector2(-35,-17)]),Color("#5c3d2a"))
	draw_circle(p+Vector2(0,-1),8,Color("#d9b16d"))
	draw_circle(p+Vector2(0,-1),4,Color("#705039"))

func _draw_story_props_v18() -> void:
	# Town sign and lamps now share the warm hand-painted palette.
	var sign_pos: Vector2 = Vector2(965,410)
	draw_line(sign_pos,sign_pos+Vector2(0,56),Color("#684a31"),7.0)
	draw_rect(Rect2(sign_pos+Vector2(-48,-8),Vector2(96,33)),Color(0.72,0.55,0.34,0.92),true)
	draw_string(ThemeDB.fallback_font,sign_pos+Vector2(-37,14),"TOWN",HORIZONTAL_ALIGNMENT_CENTER,74,12,Color("#5a402b"))
	for p: Vector2 in [Vector2(1120,468),Vector2(1120,850),Vector2(1540,850),Vector2(1940,850)]:
		draw_line(p,p+Vector2(0,-40),Color("#554431"),5.0)
		draw_rect(Rect2(p+Vector2(-8,-52),Vector2(16,17)),Color("#5e4a35"),true)
		draw_rect(Rect2(p+Vector2(-4,-48),Vector2(8,9)),Color(1.0,0.80,0.36,0.88),true)
