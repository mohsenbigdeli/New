extends Area2D
class_name FreshPlot
const FARM = preload("res://assets/pro/kenney/tiny_farm.png")
@onready var soil: Sprite2D = $Soil
@onready var crop: Sprite2D = $Crop
var state := 0
var grow_time := 0.0
const GROW_SECONDS := 18.0
var pop: Tween

func _atlas(col: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = FARM
	atlas.region = Rect2(col * 16, row * 16, 16, 16)
	return atlas

func _ready() -> void:
	soil.texture = _atlas(3, 4)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); if(distance(c.rgb,vec3(0.517647,0.776471,0.411765))<0.035){c.a=0.0;} COLOR=c*COLOR; }"
	var material := ShaderMaterial.new()
	material.shader = shader
	soil.material = material
	_update_visual()

func _process(delta: float) -> void:
	if state == 3:
		grow_time = minf(GROW_SECONDS, grow_time + delta)
		if grow_time >= GROW_SECONDS:
			state = 4
			_update_visual()
	queue_redraw()

func action_label() -> String:
	return ["Prepare soil", "Plant seeds", "Water", "Growing", "Harvest"][state]

func interact() -> Dictionary:
	match state:
		0:
			state = 1
			_update_visual()
			return {"message":"Soil prepared. Plant your first seeds.", "effect":"soil"}
		1:
			state = 2
			_update_visual()
			return {"message":"Seeds planted. A little water comes next.", "effect":"plant"}
		2:
			state = 3
			grow_time = 0.0
			_update_visual()
			return {"message":"Watered. Your crop will be ready soon.", "effect":"water"}
		3:
			return {"message":"Growing · %ds remaining" % ceili(GROW_SECONDS - grow_time)}
		4:
			state = 1
			grow_time = 0.0
			_update_visual()
			return {"message":"Fresh from the garden. +1 harvest", "harvest":1, "effect":"harvest"}
	return {}

func _update_visual() -> void:
	soil.visible = true
	soil.modulate = Color("b9a783") if state == 0 else (Color("84878a") if state == 3 else Color.WHITE)
	crop.visible = state >= 2
	match state:
		2: crop.texture = _atlas(4, 1)
		3: crop.texture = _atlas(5, 2)
		4: crop.texture = _atlas(8, 2)
	crop.scale = Vector2(3, 3)
	queue_redraw()

func _draw() -> void:
	if state == 3:
		draw_rect(Rect2(-21, 22, 42, 4), Color("294a40"))
		draw_rect(Rect2(-20, 23, 40 * grow_time / GROW_SECONDS, 2), Color("a1d49b"))
	elif state == 4:
		draw_circle(Vector2(0, -29), 5, Color("f2cc73"))
		draw_line(Vector2(-2,-29), Vector2(0,-27), Color("365249"), 2)
		draw_line(Vector2(0,-27), Vector2(3,-31), Color("365249"), 2)
