extends "res://scripts/farm_painted_world_v19.gd"
class_name FarmPaintedWorldV22

const TREE_APPLE_V22: Texture2D = preload("res://assets/art/v22/tree_apple.svg")
const TREE_TALL_V22: Texture2D = preload("res://assets/art/v22/tree_tall.svg")
const TREE_LEANING_V22: Texture2D = preload("res://assets/art/v22/tree_leaning.svg")
const TREE_BLOSSOM_V22: Texture2D = preload("res://assets/art/v22/tree_blossom.svg")
const TREE_OAK_V22: Texture2D = preload("res://assets/art/v22/tree_oak.svg")

func _draw_trees_and_gardens_v19() -> void:
	# v2.2 deliberately returns to the painterly v1.9 world composition and replaces
	# the simplified v2.1 trees with five genuinely different illustrated silhouettes.
	var trees: Array[Dictionary] = [
		{"tex":TREE_TALL_V22,"r":Rect2(600,76,136,225)},
		{"tex":TREE_APPLE_V22,"r":Rect2(760,105,184,228)},
		{"tex":TREE_BLOSSOM_V22,"r":Rect2(1815,365,176,221)},
		{"tex":TREE_LEANING_V22,"r":Rect2(1950,555,184,220)},
		{"tex":TREE_OAK_V22,"r":Rect2(650,1110,198,222)},
		{"tex":TREE_TALL_V22,"r":Rect2(1375,1102,142,232)},
		{"tex":TREE_BLOSSOM_V22,"r":Rect2(1792,1170,170,215)},
		{"tex":TREE_LEANING_V22,"r":Rect2(80,1138,188,224)},
		{"tex":TREE_APPLE_V22,"r":Rect2(1718,970,156,194)},
		{"tex":TREE_OAK_V22,"r":Rect2(1995,940,176,198)}
	]
	for item: Dictionary in trees:
		var r: Rect2 = item["r"]
		var tex: Texture2D = item["tex"]
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-5),Vector2(r.size.x*0.31,10),Color(0.05,0.08,0.04,0.13))
		draw_texture_rect(tex,r,false,Color.WHITE)

	# Painterly garden ribbons from v1.9 plus small mixed clusters near tree roots.
	for i in range(20):
		_draw_wildflower(Vector2(130.0+float(i)*98.0,380.0+sin(float(i)*1.75)*9.0),1420+i)
	for i in range(12):
		_draw_wildflower(Vector2(1170.0+float(i)*72.0,870.0+sin(float(i)*1.23)*10.0),1460+i)
	for p: Vector2 in [Vector2(585,300),Vector2(748,333),Vector2(1805,590),Vector2(1940,765),Vector2(640,1332),Vector2(1360,1333)]:
		_draw_grass_cluster(p,int(p.x+p.y))
