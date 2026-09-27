extends Node2D
class_name FarmLifeV27

# Lightweight world-space ambience for the outside map. It deliberately uses
# procedural drawing so it adds motion and life without increasing APK size.
var active := true
var phase := 0.0

const BUTTERFLY_POINTS := [
	Vector2(520, 440), Vector2(690, 360), Vector2(930, 580),
	Vector2(1160, 430), Vector2(1330, 770), Vector2(1510, 520),
	Vector2(1740, 700), Vector2(1960, 570), Vector2(720, 1180),
	Vector2(1120, 1120), Vector2(1550, 1240), Vector2(1910, 1160)
]

const POLLEN_POINTS := [
	Vector2(760, 510), Vector2(815, 470), Vector2(910, 455),
	Vector2(1015, 520), Vector2(1190, 870), Vector2(1260, 910),
	Vector2(1370, 840), Vector2(1660, 920), Vector2(1740, 880),
	Vector2(1840, 940), Vector2(520, 1260), Vector2(650, 1320)
]

func _ready() -> void:
	z_index = 1
	queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	set_process(value)
	if value:
		queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	phase += delta
	queue_redraw()

func _draw() -> void:
	if not active:
		return

	# Small painterly butterflies that drift around flower/tree pockets.
	for i in range(BUTTERFLY_POINTS.size()):
		var base: Vector2 = BUTTERFLY_POINTS[i]
		var p := base + Vector2(
			sin(phase * 1.35 + float(i) * 0.83) * (15.0 + float(i % 3) * 5.0),
			cos(phase * 1.72 + float(i) * 0.57) * (7.0 + float(i % 2) * 3.0)
		)
		var flap := 2.8 + absf(sin(phase * 8.0 + float(i))) * 3.2
		var wing_color := Color("#f2c56f") if i % 3 == 0 else (Color("#ef9fb0") if i % 3 == 1 else Color("#d8e992"))
		wing_color.a = 0.82
		draw_circle(p + Vector2(-flap, -1.0), 3.4, wing_color)
		draw_circle(p + Vector2(flap, -1.0), 3.4, wing_color)
		draw_circle(p, 2.0, Color(0.28, 0.23, 0.16, 0.90))

	# Warm pollen motes near gardens and the pond. Their motion is intentionally
	# subtle so they read as ambience rather than UI particles.
	for i in range(POLLEN_POINTS.size()):
		var base: Vector2 = POLLEN_POINTS[i]
		var drift := Vector2(
			sin(phase * 0.85 + float(i) * 0.91) * 10.0,
			cos(phase * 0.62 + float(i) * 0.47) * 6.0
		)
		var alpha := 0.34 + 0.22 * (0.5 + 0.5 * sin(phase * 2.4 + float(i)))
		draw_circle(base + drift, 2.2, Color(1.0, 0.92, 0.58, alpha))

	# A few distant birds crossing the map. Tiny V silhouettes are enough at the
	# current camera zoom and make the large open areas feel less static.
	for i in range(4):
		var travel := fmod(phase * (42.0 + float(i) * 7.0) + float(i) * 510.0, 2500.0) - 100.0
		var p := Vector2(travel, 265.0 + float(i) * 95.0 + sin(phase + float(i)) * 16.0)
		var spread := 7.0 + sin(phase * 4.0 + float(i)) * 1.5
		draw_polyline(PackedVector2Array([p + Vector2(-spread, 2), p, p + Vector2(spread, 2)]), Color(0.22, 0.19, 0.16, 0.52), 1.8, true)
