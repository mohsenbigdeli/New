extends Node2D
class_name FarmStorybookArt

const ROWAN_TEX: Texture2D = preload("res://assets/art/npc_rowan.svg")
const LINA_TEX: Texture2D = preload("res://assets/art/npc_lina.svg")
const MARNIE_TEX: Texture2D = preload("res://assets/art/npc_marnie.svg")

var farm: FarmWorld
var active := true
var t := 0.0

func setup(world: FarmWorld) -> void:
	farm = world
	z_index = 2
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
	_draw_storybook_pond()
	_draw_soft_meadow_details()
	_draw_fence_vines()
	_draw_storybook_shipping_bin()
	_draw_storybook_npc(_npc_pos(FarmWorld.MAYOR_SPOT, 0.0), ROWAN_TEX, "ROWAN")
	_draw_storybook_npc(_npc_pos(FarmWorld.LINA_SPOT, 1.7), LINA_TEX, "LINA")
	_draw_storybook_npc(_npc_pos(FarmWorld.MARNIE_SPOT, 3.2), MARNIE_TEX, "MARNIE")

func _npc_pos(base: Vector2, phase: float) -> Vector2:
	var p: float = farm.npc_phase
	return base + Vector2(sin(p * 0.55 + phase) * 24.0, cos(p * 0.42 + phase) * 10.0)

func _organic_points(center: Vector2, rx: float, ry: float, phase: float, wobble: float, count: int = 40) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count):
		var a: float = TAU * float(i) / float(count)
		var n: float = 1.0 + sin(a * 3.0 + phase) * wobble + sin(a * 7.0 - phase * 0.7) * wobble * 0.45
		points.append(center + Vector2(cos(a) * rx * n, sin(a) * ry * n))
	return points

func _draw_storybook_pond() -> void:
	var c := Vector2(1360, 560)
	# Cover the old geometric pond with a soft, asymmetrical storybook pond.
	draw_colored_polygon(_organic_points(c + Vector2(7, 10), 185, 151, 0.4, 0.055), Color(0.17,0.25,0.18,0.18))
	draw_colored_polygon(_organic_points(c, 181, 148, 0.8, 0.050), Color("#c8b680"))
	draw_colored_polygon(_organic_points(c, 169, 137, 1.1, 0.045), Color("#6d9b64"))
	draw_colored_polygon(_organic_points(c + Vector2(-2,-1), 157, 126, 1.5, 0.040), Color("#58a8b9"))
	draw_colored_polygon(_organic_points(c + Vector2(-5,-7), 149, 116, 2.0, 0.035), Color(0.40,0.74,0.76,0.35))

	# Water light and slow moving reflections.
	for i in range(9):
		var a: float = t * 0.22 + float(i) * 0.69
		var p: Vector2 = c + Vector2(cos(a * 1.2) * (35.0 + float(i) * 10.0), sin(a) * (18.0 + float(i) * 5.0))
		var half_w: float = 8.0 + float(i % 3) * 4.0
		draw_line(p - Vector2(half_w,0), p + Vector2(half_w,0), Color(0.88,0.98,0.94,0.32), 2.0)

	# Lily pads and flowers.
	for data in [[Vector2(-62,-26),15.0],[Vector2(52,34),18.0],[Vector2(72,-42),11.0]]:
		var off: Vector2 = data[0]
		var r: float = data[1]
		_draw_ellipse(c + off, Vector2(r, r * 0.58), Color("#679e58"))
		draw_colored_polygon(PackedVector2Array([c+off,c+off+Vector2(r,0),c+off+Vector2(r*.25,-r*.16)]),Color("#58a8b9"))
	draw_circle(c + Vector2(54,31), 4.0, Color("#f5b9cf"))
	draw_circle(c + Vector2(54,31), 1.7, Color("#f2df80"))

	# Reeds turn the hard shoreline into a natural edge.
	for i in range(18):
		var a: float = -2.8 + float(i) * 0.29
		if i > 7 and i < 11:
			continue
		var p: Vector2 = c + Vector2(cos(a) * 171.0, sin(a) * 139.0)
		var lean: float = sin(t * 0.7 + float(i)) * 2.0
		for j in range(3):
			var q := p + Vector2(float(j) * 4.0,0)
			draw_line(q, q + Vector2(lean + float(j)-1.0,-22.0-float(j%2)*7.0), Color("#426d43"), 2.0)
			if j == 1:
				draw_circle(q + Vector2(lean,-27),2.5,Color("#8b6846"))

func _can_decorate(p: Vector2) -> bool:
	var cell: Vector2i = farm.world_to_cell(p)
	if not farm.is_valid_cell(cell):
		return true
	var data: Dictionary = farm.get_cell(cell)
	return not bool(data.get("tilled", false))

func _draw_soft_meadow_details() -> void:
	var tufts: Array[Vector2] = [
		Vector2(260,570),Vector2(350,650),Vector2(450,745),Vector2(585,870),Vector2(720,610),
		Vector2(845,730),Vector2(905,905),Vector2(230,905),Vector2(735,930),Vector2(930,565),
		Vector2(1560,690),Vector2(1730,735),Vector2(1860,610),Vector2(1700,980),Vector2(1950,1060)
	]
	for i in range(tufts.size()):
		var p: Vector2 = tufts[i]
		if not _can_decorate(p):
			continue
		_draw_story_tuft(p, i)
	for i in range(8):
		var p := Vector2(1180.0 + float(i) * 108.0, 980.0 + sin(float(i) * 1.7) * 85.0)
		_draw_wildflower(p, i)

func _draw_story_tuft(p: Vector2, seed: int) -> void:
	_draw_ellipse(p+Vector2(0,3),Vector2(17,5),Color(0.10,0.22,0.10,0.08))
	for j in range(7):
		var x: float = (float(j)-3.0) * 4.0
		var h: float = 11.0 + float((seed+j)%4) * 3.0
		var sway: float = sin(t*0.8+float(seed+j))*2.3
		draw_line(p+Vector2(x,0),p+Vector2(x+sway,-h),Color("#4f8b47"),1.7)
		if j%3==0:
			draw_line(p+Vector2(x+sway*.5,-h*.55),p+Vector2(x+sway+5,-h*.72),Color("#72a85a"),1.3)

func _draw_wildflower(p: Vector2, seed: int) -> void:
	var stem: Color = Color("#4f8548")
	var petal: Color = Color("#f3c8d8") if seed%2==0 else Color("#f2d479")
	draw_line(p,p+Vector2(0,-18),stem,1.8)
	for k in range(5):
		var a: float = TAU*float(k)/5.0
		draw_circle(p+Vector2(0,-20)+Vector2(cos(a),sin(a))*4.2,2.8,petal)
	draw_circle(p+Vector2(0,-20),2.1,Color("#c88f42"))

func _draw_fence_vines() -> void:
	# Small vines soften the rigid fence without changing collision/gameplay.
	var posts: Array[Vector2] = [Vector2(80,442),Vector2(370,442),Vector2(660,442),Vector2(82,730),Vector2(82,920),Vector2(1034,540),Vector2(1034,830)]
	for i in range(posts.size()):
		var p: Vector2 = posts[i]
		var vine := PackedVector2Array()
		for s in range(7):
			vine.append(p+Vector2(sin(float(s)*1.2+float(i))*5.0,-float(s)*7.0))
		draw_polyline(vine,Color("#4d7841"),2.0)
		if i%2==0:
			draw_circle(vine[4]+Vector2(4,-2),2.8,Color("#e9bdca"))

func _draw_storybook_shipping_bin() -> void:
	var p := FarmWorld.SHIPPING_BIN
	# Paint over the blocky base bin with an irregular timber crate.
	_draw_ellipse(p+Vector2(0,31),Vector2(48,9),Color(0,0,0,0.15))
	var body := PackedVector2Array([p+Vector2(-43,-24),p+Vector2(40,-28),p+Vector2(43,27),p+Vector2(-39,30)])
	draw_colored_polygon(body,Color("#8b5c39"))
	for y in [-17,-2,13]:
		draw_line(p+Vector2(-36,y),p+Vector2(36,y-2),Color("#b77c4d"),3.0)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-48,-33),p+Vector2(45,-36),p+Vector2(39,-22),p+Vector2(-43,-20)]),Color("#5d402e"))
	draw_line(p+Vector2(-34,-30),p+Vector2(30,-32),Color("#c39461"),2.0)
	# little hanging tag
	draw_line(p+Vector2(31,5),p+Vector2(50,17),Color("#5c4735"),2.0)
	draw_rect(Rect2(p+Vector2(44,14),Vector2(27,18)),Color("#ead7a5"),true)
	draw_string(ThemeDB.fallback_font,p+Vector2(48,27),"SHIP",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("#60462f"))

func _draw_storybook_npc(p: Vector2, tex: Texture2D, label: String) -> void:
	# Cover the old placeholder character with authored storybook artwork.
	draw_texture_rect(tex, Rect2(p+Vector2(-34,-55),Vector2(68,91)), false)
	_draw_ellipse(p+Vector2(0,40),Vector2(31,7),Color(0.04,0.06,0.04,0.20))
	draw_rect(Rect2(p+Vector2(-31,43),Vector2(62,18)),Color(0.10,0.11,0.08,0.72),true)
	draw_line(p+Vector2(-24,43),p+Vector2(24,43),Color("#d8b56a"),1.4)
	draw_string(ThemeDB.fallback_font,p+Vector2(-25,56),label,HORIZONTAL_ALIGNMENT_CENTER,50,9,Color("#fff0cf"))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(30):
		var a: float = TAU*float(i)/30.0
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
