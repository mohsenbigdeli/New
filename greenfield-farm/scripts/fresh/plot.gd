extends Area2D
class_name FreshPlot

const FARM := preload("res://assets/pro/kenney/tiny_farm.png")

@onready var soil: Sprite2D = $Soil
@onready var crop: Sprite2D = $Crop

var state := 0
var grow_time := 0.0

func _atlas(col: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = FARM
	atlas.region = Rect2(col * 16, row * 16, 16, 16)
	return atlas

func _ready() -> void:
	soil.texture = _atlas(3, 4)
	_update_visual()

func _process(delta: float) -> void:
	if state == 3:
		grow_time += delta
		if grow_time >= 8.0:
			state = 4
			_update_visual()

func interact() -> Dictionary:
	match state:
		0:
			state = 1
			_update_visual()
			return {"message":"The soil is ready."}
		1:
			state = 2
			_update_visual()
			return {"message":"Seeds planted."}
		2:
			state = 3
			grow_time = 0.0
			_update_visual()
			return {"message":"Watered. Give it a moment to grow."}
		3:
			return {"message":"Still growing…"}
		4:
			state = 0
			grow_time = 0.0
			_update_visual()
			return {"message":"Harvested!", "harvest":1}
	return {}

func _update_visual() -> void:
	soil.visible = state >= 1
	crop.visible = state >= 2
	match state:
		2:
			crop.texture = _atlas(4, 1)
		3:
			crop.texture = _atlas(5, 2)
		4:
			crop.texture = _atlas(8, 2)
