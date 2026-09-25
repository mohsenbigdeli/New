extends Node2D
class_name FarmStorageChest

const CHEST_POS := Vector2(650, 410)
const INTERACT_RADIUS := 88.0

var pulse := 0.0

func _ready() -> void:
	position = CHEST_POS
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func is_near(world_pos: Vector2) -> bool:
	return world_pos.distance_to(position) <= INTERACT_RADIUS

func get_interaction(world_pos: Vector2) -> Dictionary:
	if is_near(world_pos):
		return {"type": "chest", "name": "Farm Storage Chest"}
	return {}

func _draw() -> void:
	var glow := 0.08 + 0.04 * sin(pulse * 2.3)
	draw_circle(Vector2(0, 18), 42.0, Color(1.0, 0.84, 0.45, glow))
	draw_ellipse_shadow(Vector2(0, 26), Vector2(34, 10), Color(0,0,0,0.25))

	# body
	draw_rect(Rect2(-34,-14,68,46), Color("#86562f"), true)
	draw_rect(Rect2(-34,-14,68,46), Color("#4a2f1e"), false, 3.0)
	# lid
	draw_rect(Rect2(-37,-25,74,18), Color("#a86d39"), true)
	draw_rect(Rect2(-37,-25,74,18), Color("#4a2f1e"), false, 3.0)
	# metal bands
	draw_rect(Rect2(-27,-24,7,55), Color("#d2a25a"), true)
	draw_rect(Rect2(20,-24,7,55), Color("#d2a25a"), true)
	# lock
	draw_rect(Rect2(-8,2,16,18), Color("#e1bb69"), true)
	draw_rect(Rect2(-8,2,16,18), Color("#5b4325"), false, 2.0)
	draw_circle(Vector2(0,9), 2.2, Color("#4e3820"))

func draw_ellipse_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
