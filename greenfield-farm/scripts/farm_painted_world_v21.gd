extends "res://scripts/farm_painted_world_v20.gd"
class_name FarmPaintedWorldV21

const TREE_ROUND_V21: Texture2D = preload("res://assets/art/v21/tree_round.svg")
const TREE_TALL_V21: Texture2D = preload("res://assets/art/v21/tree_tall.svg")
const TREE_LEANING_V21: Texture2D = preload("res://assets/art/v21/tree_leaning.svg")
const TREE_BLOSSOM_V21: Texture2D = preload("res://assets/art/v21/tree_blossom.svg")

func _draw_trees_and_gardens_v19() -> void:
	# v2.1: true silhouette variety. These are four separate authored tree assets,
	# not one sprite repeated with scale/tint changes.
	var trees: Array[Dictionary] = [
		{"tex":TREE_TALL_V21,"r":Rect2(610,74,138,208)},
		{"tex":TREE_ROUND_V21,"r":Rect2(765,108,170,220)},
		{"tex":TREE_BLOSSOM_V21,"r":Rect2(1830,375,168,217)},
		{"tex":TREE_LEANING_V21,"r":Rect2(1960,560,156,200)},
		{"tex":TREE_ROUND_V21,"r":Rect2(675,1120,154,200)},
		{"tex":TREE_TALL_V21,"r":Rect2(1360,1120,145,218)},
		{"tex":TREE_BLOSSOM_V21,"r":Rect2(1805,1180,160,207)},
		{"tex":TREE_LEANING_V21,"r":Rect2(92,1145,165,211)},
		{"tex":TREE_ROUND_V21,"r":Rect2(1730,980,138,180)},
		{"tex":TREE_TALL_V21,"r":Rect2(2030,950,125,188)}
	]
	for item: Dictionary in trees:
		var r: Rect2 = item["r"]
		var tex: Texture2D = item["tex"]
		_draw_ellipse(Vector2(r.position.x+r.size.x*0.5,r.end.y-6),Vector2(r.size.x*0.27,9),Color(0.05,0.08,0.04,0.12))
		draw_texture_rect(tex,r,false,Color.WHITE)

	# Small orchard/flower groupings make the tree layout feel intentionally planted.
	for i in range(20):
		_draw_wildflower(Vector2(130.0+float(i)*98.0,380.0+sin(float(i)*1.75)*9.0),1220+i)
	for i in range(12):
		_draw_wildflower(Vector2(1170.0+float(i)*72.0,870.0+sin(float(i)*1.23)*10.0),1260+i)
	for p: Vector2 in [Vector2(594,292),Vector2(744,324),Vector2(1818,593),Vector2(1952,760),Vector2(1348,1328)]:
		_draw_grass_cluster(p,int(p.x+p.y))
