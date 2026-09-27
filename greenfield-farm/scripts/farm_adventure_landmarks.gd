extends Node2D
class_name FarmAdventureLandmarks

const MINE_ENTRANCE := Vector2(1900,1290)
const POND_FISH_SPOT := Vector2(1535,565)
const RIVER_FISH_SPOT := Vector2(2040,655)
const MINE_ART: Texture2D = preload("res://assets/art/v20/watercolor_mine.svg")

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
	# v2.0: authored watercolor mine replaces the old procedural cave bars/circles.
	var mine_rect := Rect2(MINE_ENTRANCE-Vector2(125,120),Vector2(250,208))
	_draw_ellipse(MINE_ENTRANCE+Vector2(0,71),Vector2(82,15),Color(0.05,0.05,0.04,0.16))
	draw_texture_rect(MINE_ART,mine_rect,false,Color.WHITE)

	_draw_fishing_marker_v20(POND_FISH_SPOT)
	_draw_fishing_marker_v20(RIVER_FISH_SPOT)

func _draw_fishing_marker_v20(pos: Vector2) -> void:
	# Tiny unobtrusive bobber only; no UI-like panel beside the painted pond.
	var bob: float = sin(t*2.2 + pos.x*0.01) * 2.0
	draw_line(pos+Vector2(-8,-25),pos+Vector2(-1,8+bob),Color("#74543c"),2.2)
	draw_circle(pos+Vector2(0,9+bob),5.2,Color("#df745c"))
	draw_circle(pos+Vector2(0,7+bob),2.5,Color("#f6e8c8"))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a: float = TAU*float(i)/28.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
