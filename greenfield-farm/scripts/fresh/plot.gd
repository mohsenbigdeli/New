extends Area2D
class_name FreshPlot

const FARM := preload("res://assets/pro/kenney/tiny_farm.png")

@onready var soil: Sprite2D = $Soil
@onready var crop: Sprite2D = $Crop

# 0 untouched, 1 tilled, 2 planted/dry, 3 planted/watered,
# 4 sprout/dry, 5 sprout/watered, 6 mature
var state := 0

func _atlas(col: int, row: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = FARM
	atlas.region = Rect2(col * 16, row * 16, 16, 16)
	return atlas

func _ready() -> void:
	add_to_group("farm_plots")
	soil.texture = _atlas(3, 4)
	_update_visual()

func interact() -> Dictionary:
	return {"kind":"plot", "target":self}

func next_action() -> String:
	match state:
		0:
			return "till"
		1:
			return "plant"
		2, 4:
			return "water"
		3, 5:
			return "wait"
		6:
			return "harvest"
	return "wait"

func apply_action(action: String) -> void:
	match action:
		"till":
			if state == 0:
				state = 1
		"plant":
			if state == 1:
				state = 2
		"water":
			if state == 2:
				state = 3
			elif state == 4:
				state = 5
		"harvest":
			if state == 6:
				state = 1
	_update_visual()

func new_day() -> void:
	if state == 3:
		state = 4
	elif state == 5:
		state = 6
	_update_visual()

func get_save_data() -> Dictionary:
	return {"state":state}

func load_save_data(data) -> void:
	if data is Dictionary:
		state = clampi(int(data.get("state", 0)), 0, 6)
		_update_visual()

func _update_visual() -> void:
	soil.visible = state >= 1
	crop.visible = state >= 2
	soil.modulate = Color(0.78, 0.74, 0.68, 1.0) if state in [3, 5] else Color(1, 1, 1, 1)
	crop.position = Vector2(0, -6)
	match state:
		2, 3:
			crop.texture = _atlas(4, 0)
		4, 5:
			crop.texture = _atlas(4, 2)
		6:
			crop.texture = _atlas(8, 1)
