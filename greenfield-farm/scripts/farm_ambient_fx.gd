extends Node2D
class_name FarmAmbientFX

var phase := 0.0
var minute_of_day := 360
var weather := "Sunny"
var absolute_day := 1

func _ready() -> void:
	z_index = 1
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func update_environment(day: int, current_weather: String, minute: int) -> void:
	absolute_day = maxi(1, day)
	weather = current_weather
	minute_of_day = minute

func _draw() -> void:
	_draw_water_shimmer()
	_draw_ambient_life()
	_draw_season_particles()
	_draw_cloud_shadows()

func _draw_water_shimmer() -> void:
	var shimmer := 0.28 + 0.10 * sin(phase * 1.8)
	# river ripples
	for y in range(90, 1500, 96):
		var drift := fmod(phase * 19.0 + float(y) * 0.21, 42.0)
		var start := Vector2(2140 + drift, y)
		draw_line(start, start + Vector2(62, 0), Color(0.78, 0.94, 1.0, shimmer), 3.0)
		draw_line(start + Vector2(82, 26), start + Vector2(126, 26), Color(0.73, 0.91, 0.98, shimmer * 0.75), 2.0)
	# pond ripples clipped by simple horizontal spans
	var center := Vector2(1360, 560)
	for oy in [-88.0, -44.0, 0.0, 44.0, 88.0]:
		var half_width := sqrt(maxf(0.0, 138.0 * 138.0 - oy * oy))
		var shift := sin(phase * 1.35 + oy * 0.03) * 12.0
		var p1 := center + Vector2(-half_width * 0.54 + shift, oy)
		var p2 := center + Vector2(half_width * 0.54 + shift, oy)
		draw_line(p1, p2, Color(0.79, 0.94, 1.0, shimmer * 0.72), 2.0)

func _draw_ambient_life() -> void:
	if weather == "Rain":
		return
	var hour := float(minute_of_day) / 60.0
	if hour >= 7.0 and hour < 18.5:
		var anchors := [Vector2(720, 330), Vector2(1510, 690), Vector2(1820, 560), Vector2(860, 1160)]
		for i in range(anchors.size()):
			var base: Vector2 = anchors[i]
			var p := base + Vector2(sin(phase * (1.1 + i * 0.08) + i) * 38.0, cos(phase * (1.5 + i * 0.05) + i * 1.8) * 18.0)
			_draw_butterfly(p, i)
	elif hour >= 19.0 or hour < 5.0:
		var firefly_anchors := [Vector2(520, 840), Vector2(850, 1080), Vector2(1470, 720), Vector2(1840, 1020), Vector2(1180, 1250), Vector2(1650, 430)]
		for i in range(firefly_anchors.size()):
			var a: Vector2 = firefly_anchors[i]
			var p := a + Vector2(sin(phase * 0.9 + i * 1.7) * 28.0, cos(phase * 1.2 + i) * 19.0)
			var glow := 0.50 + 0.35 * sin(phase * 3.2 + i)
			draw_circle(p, 8.0, Color(1.0, 0.89, 0.35, 0.06 + glow * 0.10))
			draw_circle(p, 2.6, Color(1.0, 0.93, 0.44, 0.55 + glow * 0.35))

func _draw_butterfly(p: Vector2, index: int) -> void:
	var flap := 4.0 + absf(sin(phase * 8.0 + index)) * 4.0
	var body := Color("#59412f")
	var wing := Color("#f3cf70") if index % 2 == 0 else Color("#e8a6c5")
	draw_line(p + Vector2(0, -3), p + Vector2(0, 4), body, 2.0)
	draw_circle(p + Vector2(-flap, -1), 4.5, Color(wing, 0.80))
	draw_circle(p + Vector2(flap, -1), 4.5, Color(wing.lightened(0.08), 0.80))

func _draw_season_particles() -> void:
	var season := int(floor(float(absolute_day - 1) / 28.0)) % 4
	if season == 0:
		# spring petals
		for i in range(10):
			var x := fmod(float(i * 241) + phase * (12.0 + i), FarmWorld.WORLD_SIZE.x)
			var y := fmod(float(i * 137) + phase * (18.0 + i * 0.7), FarmWorld.WORLD_SIZE.y)
			draw_circle(Vector2(x, y), 2.5, Color(1.0, 0.76, 0.86, 0.34))
	elif season == 2:
		# autumn leaves
		for i in range(15):
			var x := fmod(float(i * 173) + phase * (22.0 + i * 0.3), FarmWorld.WORLD_SIZE.x)
			var y := fmod(float(i * 113) + phase * (28.0 + i * 0.6), FarmWorld.WORLD_SIZE.y)
			var leaf_color := Color("#d78b43") if i % 2 == 0 else Color("#c85e3b")
			draw_circle(Vector2(x, y), 3.2, Color(leaf_color, 0.44))
	elif season == 3:
		# winter snow
		for i in range(28):
			var x := fmod(float(i * 97) + sin(i * 1.2) * 40.0 + phase * 8.0, FarmWorld.WORLD_SIZE.x)
			var y := fmod(float(i * 61) + phase * (24.0 + float(i % 4) * 4.0), FarmWorld.WORLD_SIZE.y)
			draw_circle(Vector2(x, y), 2.0 + float(i % 3), Color(0.96, 0.98, 1.0, 0.42))

func _draw_cloud_shadows() -> void:
	if weather != "Cloudy":
		return
	for i in range(4):
		var x := fmod(phase * (34.0 + i * 3.0) + float(i * 610), FarmWorld.WORLD_SIZE.x + 420.0) - 210.0
		var y := 250.0 + float(i) * 310.0
		_draw_soft_ellipse(Vector2(x, y), Vector2(170, 58), Color(0.11, 0.18, 0.16, 0.055))

func _draw_soft_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)
