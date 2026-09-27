extends Node2D
class_name FarmAdventureLandmarks

const MINE_ENTRANCE := Vector2(1900,1290)
const POND_FISH_SPOT := Vector2(1535,565)
const RIVER_FISH_SPOT := Vector2(2040,655)

var active := true
var t := 0.0

func _ready() -> void:
	z_index = 2
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	t += delta
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	# Softer mine entrance to match the painted exterior world.
	_draw_ellipse(MINE_ENTRANCE+Vector2(0,56),Vector2(72,16),Color(0.05,0.05,0.04,0.18))
	draw_circle(MINE_ENTRANCE+Vector2(0,10),64,Color("#4b4a45"))
	draw_circle(MINE_ENTRANCE,55,Color("#232528"))
	draw_rect(Rect2(MINE_ENTRANCE.x-49,MINE_ENTRANCE.y,98,69),Color("#232528"),true)
	for dx in [-36,-12,12,36]:
		draw_line(MINE_ENTRANCE+Vector2(dx,-36),MINE_ENTRANCE+Vector2(dx,58),Color("#78583d"),6)
	draw_line(MINE_ENTRANCE+Vector2(-54,-14),MINE_ENTRANCE+Vector2(54,-14),Color("#95704c"),8)

	_draw_fishing_marker_v19(POND_FISH_SPOT)
	_draw_fishing_marker_v19(RIVER_FISH_SPOT)

func _draw_fishing_marker_v19(pos: Vector2) -> void:
	# v1.9 removes the large gray placeholder panel. A tiny floating bobber and
	# slim wood post communicate the fishing spot without breaking the watercolor art.
	var bob: float = sin(t*2.2 + pos.x*0.01) * 2.2
	draw_line(pos+Vector2(-9,-30),pos+Vector2(-1,9+bob),Color("#75523a"),2.5)
	draw_circle(pos+Vector2(0,10+bob),6.0,Color("#e36f58"))
	draw_circle(pos+Vector2(0,8+bob),3.0,Color("#f8edd0"))
	draw_line(pos+Vector2(26,-17),pos+Vector2(26,18),Color("#6b4d36"),4.0)
	# little fish-shaped plaque
	var plaque: Rect2 = Rect2(pos+Vector2(12,-29),Vector2(38,17))
	draw_rect(plaque,Color(0.67,0.52,0.32,0.82),true)
	draw_circle(pos+Vector2(27,-21),3.4,Color("#4e7880"))
	draw_colored_polygon(PackedVector2Array([pos+Vector2(30,-21),pos+Vector2(37,-25),pos+Vector2(37,-17)]),Color("#4e7880"))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a: float = TAU*float(i)/28.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
