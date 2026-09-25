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
	var pos := FarmWorld.ORIGIN + Vector2(target_cell.x * FarmWorld.TILE_SIZE + 4, target_cell.y * FarmWorld.TILE_SIZE + 4)
	var rect := Rect2(pos, Vector2(FarmWorld.TILE_SIZE - 8, FarmWorld.TILE_SIZE - 8))
	var accent := _tool_color(selected_tool)
	draw_rect(rect, Color(accent, 0.10), true)
	draw_rect(rect, Color(accent, 0.82), false, 3.0)
	var pulse := 0.42 + 0.18 * sin(Time.get_ticks_msec() * 0.006)
	var center := rect.get_center()
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var dir := (center - corner).normalized()
		draw_line(corner, corner + dir * 12.0, Color(accent, pulse), 4.0)

func _tool_color(index: int) -> Color:
	match index:
		0: return Color("#e7bf73")
		1, 2, 3: return Color("#8fd36c")
		4: return Color("#73c7e7")
		5: return Color("#ffd86c")
	return Color.WHITE
