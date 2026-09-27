extends "res://scripts/farm_painted_world_v19.gd"
class_name FarmPaintedWorldV20

const STORE_V20: Texture2D = preload("res://assets/art/v20/watercolor_store.svg")
const BARN_V20: Texture2D = preload("res://assets/art/v20/watercolor_barn.svg")
const TOWNHALL_V20: Texture2D = preload("res://assets/art/v20/watercolor_townhall.svg")

func _draw_meadow_depth_v19() -> void:
	super._draw_meadow_depth_v19()
	# v2.0 adds illustrated meadow islands rather than uniform noise.
	var islands: Array[Dictionary] = [
		{"p":Vector2(215,655),"r":Vector2(110,48),"c":Color(0.88,0.78,0.28,0.060)},
		{"p":Vector2(515,815),"r":Vector2(150,56),"c":Color(0.31,0.61,0.24,0.072)},
		{"p":Vector2(790,690),"r":Vector2(118,50),"c":Color(0.84,0.71,0.28,0.050)},
		{"p":Vector2(1650,660),"r":Vector2(110,48),"c":Color(0.36,0.66,0.28,0.060)},
		{"p":Vector2(1775,1035),"r":Vector2(150,56),"c":Color(0.80,0.68,0.27,0.045)}
	]
	for item: Dictionary in islands:
		_draw_blob(item["p"],item["r"],item["c"],0.055)
	# Hand-placed clusters create focal points like the watercolor reference.
	for p: Vector2 in [Vector2(178,612),Vector2(235,655),Vector2(470,786),Vector2(535,824),Vector2(758,671),Vector2(822,714),Vector2(1672,644),Vector2(1760,1008)]:
		_draw_shrub_v16(p)
	for i in range(24):
		var p := Vector2(170.0+float(i%8)*105.0,590.0+float(i/8)*145.0+sin(float(i)*1.7)*10.0)
		if i % 3 == 0:
			_draw_wildflower(p,900+i)
		else:
			_draw_grass_cluster(p,940+i)

func _draw_buildings_v19() -> void:
	# Farmhouse keeps the original painted cottage; every other building now has a
	# genuinely different authored silhouette instead of reusing the same cottage.
	_draw_ellipse(Vector2(390,383),Vector2(145,15),Color(0.05,0.07,0.04,0.12))
	draw_texture_rect(HOUSE_V17,Rect2(185,92,420,304),false,Color.WHITE)
	for i in range(6):
		_draw_wildflower(Vector2(238.0+float(i)*55.0,384.0+sin(float(i))*4.0),1010+i)

	_draw_asset_building_v20(STORE_V20,Rect2(1585,76,392,283),Vector2(1782,352))
	_draw_asset_building_v20(TOWNHALL_V20,Rect2(1575,765,404,292),Vector2(1778,1050))
	_draw_asset_building_v20(BARN_V20,Rect2(240,1030,420,304),Vector2(450,1328))

func _draw_asset_building_v20(tex: Texture2D, rect: Rect2, foot: Vector2) -> void:
	_draw_ellipse(foot,Vector2(rect.size.x*0.34,15),Color(0.05,0.07,0.04,0.13))
	draw_texture_rect(tex,rect,false,Color.WHITE)

func _draw_story_props_v19() -> void:
	# Small painted sign and warm lamps; labels never overlap the buildings anymore.
	var sign_pos: Vector2 = Vector2(960,415)
	draw_line(sign_pos,sign_pos+Vector2(0,48),Color("#715139"),5.0)
	_draw_blob(sign_pos+Vector2(0,-1),Vector2(43,17),Color(0.76,0.59,0.37,0.94),0.04)
	draw_string(ThemeDB.fallback_font,sign_pos+Vector2(-29,4),"TOWN",HORIZONTAL_ALIGNMENT_CENTER,58,10,Color("#59412e"))
	for p: Vector2 in [Vector2(1120,468),Vector2(1120,850),Vector2(1540,850),Vector2(1940,850)]:
		draw_line(p,p+Vector2(0,-34),Color("#66503b"),3.5)
		_draw_blob(p+Vector2(0,-43),Vector2(8,10),Color(0.34,0.28,0.21,0.92),0.05)
		draw_circle(p+Vector2(0,-43),3.5,Color(1.0,0.80,0.38,0.82))
	# Decorative flower beds around civic/shop areas to tie assets into the ground.
	for i in range(7):
		_draw_wildflower(Vector2(1600.0+float(i)*54.0,364.0+sin(float(i)*1.5)*5.0),1060+i)
	for i in range(8):
		_draw_wildflower(Vector2(1595.0+float(i)*48.0,1061.0+sin(float(i)*1.2)*5.0),1080+i)
