extends Node2D
class_name FarmPlotPolish

var farm: FarmWorld
var active := true
var t := 0.0

func setup(world: FarmWorld) -> void:
	farm = world
	z_index = 1
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	queue_redraw()

func _process(delta: float) -> void:
	if not active or not farm:
		return
	t += delta
	queue_redraw()

func _draw() -> void:
	if not active or not farm:
		return
	for y in range(FarmWorld.ROWS):
		for x in range(FarmWorld.COLS):
			var c := Vector2i(x,y)
			var data: Dictionary = farm.get_cell(c)
			if not bool(data.get("tilled",false)):
				continue
			var origin := FarmWorld.ORIGIN + Vector2(x*FarmWorld.TILE_SIZE,y*FarmWorld.TILE_SIZE)
			_draw_soft_tile(origin,c,bool(data.get("watered",false)))

func _draw_soft_tile(origin: Vector2, cell: Vector2i, watered: bool) -> void:
	var inset := 5.0
	var rect := Rect2(origin+Vector2(inset,inset),Vector2(FarmWorld.TILE_SIZE-inset*2.0,FarmWorld.TILE_SIZE-inset*2.0))
	# Ground-contact shadow makes the bed read as worked earth rather than a pasted square.
	draw_line(Vector2(rect.position.x+8.0,rect.end.y-1.0),Vector2(rect.end.x-8.0,rect.end.y-1.0),Color(0.18,0.10,0.06,0.22),3.0)
	# Cut visual corners with tiny grass/weed clusters.
	var corners: Array[Vector2] = [rect.position+Vector2(3,4),Vector2(rect.end.x-4,rect.position.y+5),Vector2(rect.position.x+5,rect.end.y-3),rect.end-Vector2(4,3)]
	for i in range(corners.size()):
		if (cell.x+cell.y+i)%2 == 0:
			_draw_tuft(corners[i],float(cell.x*7+cell.y*11+i))
	# Furrow highlights break the large flat soil fill.
	var line_color := Color(0.80,0.61,0.40,0.20) if not watered else Color(0.56,0.69,0.66,0.16)
	for row in range(3):
		var yy := rect.position.y + 15.0 + float(row)*13.0
		var offset := float((cell.x*5+cell.y*3+row)%7)
		draw_line(Vector2(rect.position.x+9.0+offset,yy),Vector2(rect.end.x-10.0,yy+1.0),line_color,1.4)
	# A couple of tiny pebbles make adjacent beds less identical.
	for i in range(2):
		var px := rect.position.x + 13.0 + float((cell.x*17+cell.y*9+i*19)%34)
		var py := rect.position.y + 12.0 + float((cell.x*11+cell.y*15+i*13)%34)
		draw_circle(Vector2(px,py),1.6,Color(0.31,0.20,0.13,0.28))

func _draw_tuft(p: Vector2, seed: float) -> void:
	for i in range(3):
		var sway := sin(t*1.1+seed+float(i))*1.1
		draw_line(p+Vector2(float(i)*3.0,0),p+Vector2(float(i)*3.0+sway,-5.0-float(i%2)*2.0),Color(0.20,0.43,0.20,0.66),1.4)
