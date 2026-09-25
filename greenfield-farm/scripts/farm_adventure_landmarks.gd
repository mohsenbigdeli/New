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
	# mine entrance
	draw_circle(MINE_ENTRANCE + Vector2(0,14), 78, Color("#524a46"))
	draw_circle(MINE_ENTRANCE, 64, Color("#1d1b1d"))
	draw_rect(Rect2(MINE_ENTRANCE.x-58,MINE_ENTRANCE.y,116,76),Color("#1d1b1d"),true)
	for dx in [-44,-16,16,44]:
		draw_line(MINE_ENTRANCE+Vector2(dx,-42),MINE_ENTRANCE+Vector2(dx,62),Color("#72563d"),7)
	draw_line(MINE_ENTRANCE+Vector2(-62,-18),MINE_ENTRANCE+Vector2(62,-18),Color("#8e6947"),9)
	draw_rect(Rect2(MINE_ENTRANCE.x-76,MINE_ENTRANCE.y+67,152,14),Color(0,0,0,0.20),true)
	# mine sign
	draw_rect(Rect2(MINE_ENTRANCE.x+88,MINE_ENTRANCE.y+4,92,54),Color("#6e4b31"),true)
	draw_line(MINE_ENTRANCE+Vector2(134,58),MINE_ENTRANCE+Vector2(134,98),Color("#5b3c29"),7)

	_draw_fishing_marker(POND_FISH_SPOT)
	_draw_fishing_marker(RIVER_FISH_SPOT)

func _draw_fishing_marker(pos: Vector2) -> void:
	var bob: float = sin(t*2.2 + pos.x*0.01) * 3.0
	draw_line(pos+Vector2(-18,-44),pos+Vector2(-2,12+bob),Color("#6f4a2d"),4)
	draw_circle(pos+Vector2(-1,13+bob),8,Color("#e26d55"))
	draw_circle(pos+Vector2(-1,13+bob),4,Color("#f4e7c2"))
	draw_line(pos+Vector2(28,-18),pos+Vector2(28,18),Color("#5c432f"),5)
	draw_rect(Rect2(pos.x+6,pos.y-44,88,34),Color("#d7c58e"),true)
	draw_rect(Rect2(pos.x+10,pos.y-40,80,26),Color("#587f84"),true)
