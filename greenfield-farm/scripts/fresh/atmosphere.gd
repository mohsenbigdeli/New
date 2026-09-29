extends Node2D
class_name FarmAtmosphere
var clock := 0.0
var enabled := true
var target: Node2D
var particles: Array[Dictionary] = []
var motes: Array[Vector3] = []
func _ready() -> void:
	z_index = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = 4902
	for i in range(34):
		motes.append(Vector3(rng.randf_range(50,1870), rng.randf_range(70,1010), rng.randf_range(0, TAU)))
func burst(where: Vector2, kind: String) -> void:
	if not enabled:
		return
	var color := Color("acddef") if kind == "water" else (Color("f3cf74") if kind == "harvest" else Color("c4a170"))
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		particles.append({"p":where, "v":Vector2(cos(angle)*45, sin(angle)*35-35),"life":0.65,"color":color})
func _process(delta: float) -> void:
	clock += delta
	for i in range(particles.size()-1,-1,-1):
		particles[i].life -= delta
		particles[i].p += particles[i].v * delta
		particles[i].v.y += delta * 90
		if particles[i].life <= 0:
			particles.remove_at(i)
	queue_redraw()
func _draw() -> void:
	if is_instance_valid(target):
		var p := target.global_position
		var c := Color("fff0a8")
		for side in [-1,1]:
			draw_line(p+Vector2(side*30,-26), p+Vector2(side*30,-15), c, 2)
			draw_line(p+Vector2(side*30,-26), p+Vector2(side*19,-26), c, 2)
			draw_line(p+Vector2(side*30,26), p+Vector2(side*30,15), c, 2)
			draw_line(p+Vector2(side*30,26), p+Vector2(side*19,26), c, 2)
	if not enabled:
		return
	for mote in motes:
		var p := Vector2(mote.x + sin(clock*0.25+mote.z)*22, mote.y+sin(clock*0.4+mote.z)*13)
		var alpha := 0.22 + sin(clock+mote.z)*0.12
		draw_rect(Rect2(p,Vector2(3,3)), Color(1,0.97,0.7,alpha))
	for item in particles:
		var color: Color = item.color
		color.a = item.life / 0.65
		draw_rect(Rect2(item.p,Vector2(4,4)), color)
	# A few butterflies over the flower beds; deterministic, subtle motion.
	for i in range(4):
		var p := Vector2(550+i*140+sin(clock*0.7+i)*25, 290+cos(clock*0.5+i)*22)
		var span := 2.0+absf(sin(clock*8+i))*4
		draw_line(p-Vector2(span,3),p,Color("ffe0a8"),3)
		draw_line(p+Vector2(span,-3),p,Color("f5bcb5"),3)
