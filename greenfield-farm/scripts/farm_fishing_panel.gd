extends CanvasLayer
class_name FarmFishingPanel

signal open_state_changed(open: bool)
signal fishing_finished(success: bool, bait_used: bool)

var panel: Panel
var status_label: Label
var hint_label: Label
var bar: Control
var reel_button: Button
var is_open := false
var bait_used := false
var cursor_value: float = 0.0
var cursor_dir: float = 1.0
var target_start: float = 0.35
var target_width: float = 0.18
var elapsed: float = 0.0

func _ready() -> void:
	layer = 18
	_build_ui()
	set_process(true)

func _style(fill: Color, border: Color, radius: int = 14, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0,0,0,0.32)
	s.shadow_size = 8
	return s

func _build_ui() -> void:
	panel = Panel.new()
	panel.position = Vector2(310,155)
	panel.size = Vector2(660,410)
	panel.add_theme_stylebox_override("panel", _style(Color("#1f2d32f4"), Color("#7fc7d3"), 20, 3))
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "FISHING"
	title.position = Vector2(24,18)
	title.size = Vector2(420,36)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#d9f6f7"))
	panel.add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(24,62)
	status_label.size = Vector2(610,54)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("#bfe6e9"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status_label)

	bar = Control.new()
	bar.position = Vector2(48,142)
	bar.size = Vector2(564,92)
	bar.draw.connect(_draw_bar)
	panel.add_child(bar)

	hint_label = Label.new()
	hint_label.text = "Press REEL when the white marker is inside the green catch zone."
	hint_label.position = Vector2(48,250)
	hint_label.size = Vector2(564,48)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color("#d5e9e7"))
	panel.add_child(hint_label)

	reel_button = Button.new()
	reel_button.text = "REEL"
	reel_button.position = Vector2(190,315)
	reel_button.size = Vector2(280,62)
	reel_button.add_theme_font_size_override("font_size", 22)
	reel_button.add_theme_stylebox_override("normal", _style(Color("#376f69"), Color("#9be0c8"), 14, 2))
	reel_button.add_theme_stylebox_override("pressed", _style(Color("#29554f"), Color.WHITE, 14, 2))
	reel_button.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(reel_button)
	reel_button.pressed.connect(_on_reel_pressed)

	var close := Button.new()
	close.text = "X"
	close.position = Vector2(596,18)
	close.size = Vector2(42,42)
	close.add_theme_font_size_override("font_size", 16)
	close.add_theme_stylebox_override("normal", _style(Color("#5f4542"), Color("#c99c91"), 10, 2))
	panel.add_child(close)
	close.pressed.connect(close_panel)

func start_fishing(use_bait: bool, weather: String, minute_of_day: int) -> void:
	bait_used = use_bait
	target_width = 0.28 if bait_used else 0.18
	target_start = randf_range(0.10, 0.90 - target_width)
	cursor_value = randf_range(0.02, 0.12)
	cursor_dir = 1.0
	elapsed = 0.0
	is_open = true
	panel.visible = true
	var hour := int(minute_of_day / 60)
	var bait_text := "Bait equipped: catch zone is wider." if bait_used else "No bait: the catch zone is smaller."
	status_label.text = "%s  •  %02d:00  •  %s" % [weather, hour, bait_text]
	bar.queue_redraw()
	open_state_changed.emit(true)

func close_panel() -> void:
	if not is_open:
		return
	is_open = false
	panel.visible = false
	open_state_changed.emit(false)

func _process(delta: float) -> void:
	if not is_open:
		return
	elapsed += delta
	var speed := 0.62 + minf(elapsed * 0.012, 0.22)
	cursor_value += cursor_dir * speed * delta
	if cursor_value >= 1.0:
		cursor_value = 1.0
		cursor_dir = -1.0
	elif cursor_value <= 0.0:
		cursor_value = 0.0
		cursor_dir = 1.0
	bar.queue_redraw()

func _draw_bar() -> void:
	if not bar:
		return
	var base := Rect2(0,20,bar.size.x,52)
	bar.draw_rect(base, Color("#0e1c22"), true)
	bar.draw_rect(base, Color("#6c9aa1"), false, 3.0)
	var zone := Rect2(target_start * bar.size.x, 24, target_width * bar.size.x, 44)
	bar.draw_rect(zone, Color("#5eaa6c"), true)
	bar.draw_rect(zone, Color("#b9ef9e"), false, 3.0)
	var x := cursor_value * bar.size.x
	bar.draw_line(Vector2(x,12), Vector2(x,80), Color.WHITE, 6.0)
	bar.draw_circle(Vector2(x,12), 7.0, Color("#f7edc8"))

func _on_reel_pressed() -> void:
	if not is_open:
		return
	var success := cursor_value >= target_start and cursor_value <= target_start + target_width
	is_open = false
	panel.visible = false
	open_state_changed.emit(false)
	fishing_finished.emit(success, bait_used)
