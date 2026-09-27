extends "res://scripts/farm_painted_world_v16.gd"
class_name FarmPaintedWorldV17

const HOUSE_V17: Texture2D = preload("res://assets/art/v17/watercolor_house.png")
const TREE_V17: Texture2D = preload("res://assets/art/v17/watercolor_tree.png")
const POND_V17: Texture2D = preload("res://assets/art/v17/watercolor_pond.png")
const ROWAN_V17: Texture2D = preload("res://assets/art/v17/watercolor_rowan.png")
const LINA_V17: Texture2D = preload("res://assets/art/v17/watercolor_lina.png")
const MARNIE_V17: Texture2D = preload("res://assets/art/v17/watercolor_marnie.png")
const STORE_V17: Texture2D = preload("res://assets/art/store.svg")
const BARN_V17: Texture2D = preload("res://assets/art/barn.svg")
const TOWNHALL_V17: Texture2D = preload("res://assets/art/townhall.svg")

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

func _draw_pond_and_river() -> void:
	# Keep the far-east river functional, but replace the pond itself with the
	# authored watercolor asset including stones, reeds, lilies and wooden dock.
	draw_rect(Rect2(2104,0,18,FarmWorld.WORLD_SIZE.y),Color("#cbb17b"),true)
	draw_rect(Rect2(2122,0,182,FarmWorld.WORLD_SIZE.y),Color("#4b9fba"),true)
	for i in range(34):
		var yy: float = 30.0 + float(i)*44.0
		var width: float = 24.0 + float(i%4)*9.0
		draw_line(Vector2(2150.0,yy),Vector2(2150.0+width,yy+sin(t*.28+float(i))*1.7),Color(0.87,0.97,0.94,0.29),1.4)

	var pond_rect: Rect2 = Rect2(1198,382,430,435)
	_draw_ellipse(pond_rect.get_center()+Vector2(0,24),Vector2(190,54),Color(0.08,0.12,0.07,0.13))
	draw_texture_rect(POND_V17,pond_rect,false,Color(1.0,1.0,1.0,1.0))

	# A few moving glints keep the painted water alive without obscuring the art.
	var c: Vector2 = Vector2(1410,590)
	for i in range(6):
		var a: float = t*0.15 + float(i)*0.83
		var p: Vector2 = c + Vector2(cos(a)*float(34+i*11),sin(a*1.12)*float(17+i*6))
		var half_w: float = 7.0 + float(i%3)*3.0
		draw_line(p-Vector2(half_w,0),p+Vector2(half_w,0),Color(0.95,0.99,0.94,0.20),1.3)

func _draw_buildings() -> void:
	# The farmhouse is now the actual hand-painted cottage. Other buildings keep
	# their existing gameplay-safe art until their dedicated painted pass.
	_draw_shadow(FarmWorld.HOUSE_RECT)
	_draw_shadow(FarmWorld.STORE_RECT)
	_draw_shadow(FarmWorld.TOWN_HALL_RECT)
	_draw_shadow(FarmWorld.BARN_RECT)

	var house_rect: Rect2 = Rect2(112,62,500,361)
	draw_texture_rect(HOUSE_V17,house_rect,false,Color.WHITE)
	draw_texture_rect(STORE_V17,FarmWorld.STORE_RECT,false,Color(1.0,0.97,0.91,1.0))
	draw_texture_rect(TOWNHALL_V17,FarmWorld.TOWN_HALL_RECT,false,Color(1.0,0.97,0.91,1.0))
	draw_texture_rect(BARN_V17,FarmWorld.BARN_RECT,false,Color(1.0,0.97,0.91,1.0))

	# Cottage garden visually connects the painted house to the meadow.
	for i in range(9):
		_draw_wildflower(Vector2(175.0+float(i)*48.0,386.0+sin(float(i)*1.4)*5.0),i+100)
	for i in range(5):
		_draw_ellipse(Vector2(305.0+float(i)*28.0,405.0+float(i%2)*5.0),Vector2(13,5),Color(0.52,0.44,0.33,0.20))

func _draw_trees_and_gardens() -> void:
	# Authored watercolor trees replace the procedural circles/trunks. Repeated
	# instances use slightly different sizes and tints to avoid a stamp-like look.
	var tree_rects: Array[Rect2] = [
		Rect2(34,122,174,226),
		Rect2(650,103,168,218),
		Rect2(826,174,184,239),
		Rect2(1916,420,178,231),
		Rect2(694,1135,176,229),
		Rect2(1430,1165,184,239),
		Rect2(1922,1228,174,226),
		Rect2(58,1195,182,236)
	]
	for i in range(tree_rects.size()):
		var tint: Color = Color(1.0,1.0,1.0,0.98)
		if i % 3 == 1:
			tint = Color(1.0,0.96,0.88,0.98)
		elif i % 3 == 2:
			tint = Color(0.92,1.0,0.91,0.98)
		var r: Rect2 = tree_rects[i]
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-8.0),Vector2(r.size.x*0.32,12),Color(0.07,0.10,0.05,0.13))
		draw_texture_rect(TREE_V17,r,false,tint)

	var flower_spots: Array[Vector2] = [
		Vector2(225,365),Vector2(288,374),Vector2(515,367),Vector2(590,378),
		Vector2(840,370),Vector2(925,365),Vector2(1160,755),Vector2(1640,748),
		Vector2(1750,765),Vector2(1875,715),Vector2(1210,1015),Vector2(1510,1045)
	]
	for i in range(flower_spots.size()):
		_draw_wildflower(flower_spots[i],i+140)

	for p: Vector2 in [Vector2(690,560),Vector2(880,1040),Vector2(1710,1010),Vector2(1880,620),Vector2(1540,1180)]:
		_draw_shrub_v16(p)

func _draw_npcs_v16() -> void:
	_draw_watercolor_npc(_npc_pos_v16(FarmWorld.MAYOR_SPOT,0.0),ROWAN_V17,"ROWAN",Vector2(78,121))
	_draw_watercolor_npc(_npc_pos_v16(FarmWorld.LINA_SPOT,1.7),LINA_V17,"LINA",Vector2(76,110))
	_draw_watercolor_npc(_npc_pos_v16(FarmWorld.MARNIE_SPOT,3.2),MARNIE_V17,"MARNIE",Vector2(76,116))

func _draw_watercolor_npc(p: Vector2, tex: Texture2D, label: String, display_size: Vector2) -> void:
	var bob: float = sin(t*2.7+p.x*0.012)*1.5
	var foot_y: float = p.y + 34.0 + bob
	_draw_ellipse(Vector2(p.x,foot_y+5.0),Vector2(display_size.x*0.30,6),Color(0.04,0.05,0.03,0.17))
	var rect: Rect2 = Rect2(Vector2(p.x-display_size.x*0.5,foot_y-display_size.y+5.0),display_size)
	draw_texture_rect(tex,rect,false,Color.WHITE)
	# Small paper name tag, deliberately subtler than the old black label.
	var tag_w: float = 52.0
	draw_rect(Rect2(p+Vector2(-tag_w*0.5,42),Vector2(tag_w,14)),Color(0.94,0.86,0.67,0.78),true)
	draw_string(ThemeDB.fallback_font,p+Vector2(-22,52),label,HORIZONTAL_ALIGNMENT_CENTER,44,7,Color("#57402c"))
