extends Node2D
class_name FarmFocusOverlay

var target_cell := Vector2i(-999, -999)
var target_valid := false
var selected_tool := 0

func _ready() -> void:
	z_index = 1
	queue_redraw()

func set_target(cell: Vector2i, valid: bool, tool_index: int) -> void:
	if cell == target_cell and valid == target_valid and tool_index == selected_tool:
		return
	target_cell = cell
	target_valid = valid
	selected_tool = tool_index
	queue_redraw()

func clear_target() -> void:
	if not target_valid:
		return
	target_valid = false
	queue_redraw()

func _draw() -> void:
	if not target_valid:
		return
	var pos: Vector2 = FarmWorld.ORIGIN + Vector2(target_cell.x * FarmWorld.TILE_SIZE + 6, target_cell.y * FarmWorld.TILE_SIZE + 6)
	var size: Vector2 = Vector2(FarmWorld.TILE_SIZE - 12, FarmWorld.TILE_SIZE - 12)
	var rect: Rect2 = Rect2(pos, size)
	var accent: Color = _tool_color(selected_tool)
	var pulse: float = 0.34 + 0.16 * sin(Time.get_ticks_msec() * 0.006)
	var center: Vector2 = rect.get_center()
	var blob := PackedVector2Array([
		center+Vector2(-size.x*.46,-size.y*.28),center+Vector2(-size.x*.25,-size.y*.47),
		center+Vector2(size.x*.19,-size.y*.45),center+Vector2(size.x*.46,-size.y*.22),
		center+Vector2(size.x*.43,size.y*.24),center+Vector2(size.x*.20,size.y*.45),
		center+Vector2(-size.x*.24,size.y*.43),center+Vector2(-size.x*.45,size.y*.20)
	])
	draw_colored_polygon(blob,Color(accent,0.055))
	# Four short brush-like corner marks instead of a hard rectangle.
	var corners: Array[Vector2] = [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for corner: Vector2 in corners:
		var inward: Vector2 = (center-corner).normalized()
		var side: Vector2 = Vector2(-inward.y,inward.x)
		draw_line(corner+inward*4.0,corner+inward*14.0,Color(accent,pulse),2.2)
		draw_line(corner+inward*4.0,corner+inward*4.0+side*7.0,Color(accent,pulse*.78),1.8)
	# Tiny center glint reads as interactable without dominating the artwork.
	draw_circle(center,2.4,Color(accent,pulse*.9))

func _tool_color(index: int) -> Color:
	match index:
		0: return Color("#dfb66a")
		1, 2, 3: return Color("#87bb65")
		4: return Color("#72b7cf")
		5: return Color("#e9c766")
	return Color.WHITE
