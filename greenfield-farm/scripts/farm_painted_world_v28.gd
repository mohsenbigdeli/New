extends "res://scripts/farm_painted_world_v22.gd"
class_name FarmPaintedWorldV28

# v2.8 restores the authored watercolor tree used by the earlier painterly
# world. v2.2 had replaced these with simplified SVG silhouettes; this keeps
# the richer hand-painted asset while retaining the newer world composition.
const TREE_WATERCOLOR_V28: Texture2D = preload("res://assets/art/v17/watercolor_tree.png")

func _draw_trees_and_gardens_v19() -> void:
	var tree_rects: Array[Rect2] = [
		Rect2(640,84,158,205),
		Rect2(810,126,172,223),
		Rect2(1870,388,168,218),
		Rect2(1970,580,142,184),
		Rect2(705,1140,164,213),
		Rect2(1410,1150,180,234),
		Rect2(1845,1210,158,205),
		Rect2(90,1170,170,221)
	]

	for i in range(tree_rects.size()):
		var r: Rect2 = tree_rects[i]
		var tint := Color.WHITE
		if i % 3 == 1:
			tint = Color(1.0,0.965,0.90,0.99)
		elif i % 3 == 2:
			tint = Color(0.95,1.0,0.94,0.99)
		_draw_ellipse(
			Vector2(r.position.x + r.size.x * 0.5, r.end.y - 7.0),
			Vector2(r.size.x * 0.30, 11.0),
			Color(0.05,0.08,0.04,0.13)
		)
		draw_texture_rect(TREE_WATERCOLOR_V28, r, false, tint)

	# Keep the hand-painted meadow rhythm from v1.9 around the restored trees.
	for i in range(20):
		_draw_wildflower(Vector2(130.0 + float(i) * 98.0, 380.0 + sin(float(i) * 1.75) * 9.0), 1720 + i)
	for i in range(12):
		_draw_wildflower(Vector2(1170.0 + float(i) * 72.0, 870.0 + sin(float(i) * 1.23) * 10.0), 1760 + i)
	for p: Vector2 in [
		Vector2(610,306), Vector2(795,350), Vector2(1880,610),
		Vector2(1990,780), Vector2(690,1345), Vector2(1400,1370)
	]:
		_draw_grass_cluster(p, int(p.x + p.y))
