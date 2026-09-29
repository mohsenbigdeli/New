extends Area2D
class_name FreshPlot

@onready var soil: Polygon2D = $Soil
@onready var crop: Sprite2D = $Crop

var state := 0
var grow_time := 0.0

func _ready() -> void:
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
			return {"message":"Soil tilled. USE again to plant a turnip."}
		1:
			state = 2
			_update_visual()
			return {"message":"Turnip planted. Water it with USE."}
		2:
			state = 3
			grow_time = 0.0
			_update_visual()
			return {"message":"Watered. The turnip will grow in a few seconds."}
		3:
			return {"message":"The turnip is still growing…"}
		4:
			state = 0
			grow_time = 0.0
			_update_visual()
			return {"message":"Turnip harvested!", "harvest":1}
	return {}

func _update_visual() -> void:
	crop.visible = state >= 2
	match state:
		0:
			soil.color = Color("#6fa95d")
			crop.visible = false
		1:
			soil.color = Color("#8a5f3d")
		2:
			soil.color = Color("#8a5f3d")
			crop.scale = Vector2(0.16, 0.16)
			crop.modulate = Color("#9bc77b")
		3:
			soil.color = Color("#654b3e")
			crop.scale = Vector2(0.25, 0.25)
			crop.modulate = Color("#80b966")
		4:
			soil.color = Color("#75523c")
			crop.scale = Vector2(0.38, 0.38)
			crop.modulate = Color.WHITE
