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
	# v1.8: softer, asymmetrical painted chest instead of the old blocky rectangle.
	var glow: float = 0.045 + 0.018 * sin(pulse * 2.1)
	draw_circle(Vector2(0,17),43.0,Color(1.0,0.78,0.34,glow))
	_draw_ellipse_shadow(Vector2(0,29),Vector2(39,9),Color(0.05,0.04,0.02,0.18))

	var body := PackedVector2Array([
		Vector2(-35,-13),Vector2(31,-16),Vector2(36,29),Vector2(-31,31)
	])
	draw_colored_polygon(body,Color("#8a5a36"))
	for yy: float in [-6.0,7.0,20.0]:
		draw_line(Vector2(-28,yy),Vector2(29,yy-2),Color("#c48953"),3.0)
	# slightly curved dark lid made from two washes
	var lid := PackedVector2Array([
		Vector2(-40,-22),Vector2(-29,-31),Vector2(28,-33),Vector2(39,-23),Vector2(34,-12),Vector2(-35,-10)
	])
	draw_colored_polygon(lid,Color("#65412b"))
	draw_line(Vector2(-29,-26),Vector2(29,-28),Color(0.84,0.59,0.34,0.30),2.0)
	# brass lock and hand-painted bands
	draw_line(Vector2(-23,-16),Vector2(-20,28),Color("#c99a53"),4.0)
	draw_line(Vector2(22,-17),Vector2(24,27),Color("#c99a53"),4.0)
	draw_rect(Rect2(-9,1,18,19),Color("#dfb965"),true)
	draw_rect(Rect2(-9,1,18,19),Color("#6a4b2b"),false,2.0)
	draw_circle(Vector2(0,8),2.2,Color("#5b4028"))
	# tiny painted scratches keep it from looking vector-flat
	for i in range(7):
		var x: float = -24.0 + float(i)*8.0
		draw_line(Vector2(x,13+sin(float(i))*3.0),Vector2(x+5,12+sin(float(i))*3.0),Color(0.95,0.75,0.48,0.16),1.2)

func _draw_ellipse_shadow(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
