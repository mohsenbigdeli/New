extends Node2D
class_name FarmWorld

const TILE_SIZE := 64
const COLS := 18
const ROWS := 12
const ORIGIN := Vector2(80, 80)

var cells: Dictionary = {}
var current_day := 1

func _ready() -> void:
	queue_redraw()

func world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - ORIGIN
	return Vector2i(floor(local.x / TILE_SIZE), floor(local.y / TILE_SIZE))

func cell_to_world(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell.x * TILE_SIZE + TILE_SIZE * 0.5, cell.y * TILE_SIZE + TILE_SIZE * 0.5)

func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < COLS and cell.y < ROWS

func get_cell(cell: Vector2i) -> Dictionary:
	if not cells.has(cell):
		cells[cell] = {"tilled": false, "watered": false, "crop": "", "stage": 0, "age": 0}
	return cells[cell]

func till(cell: Vector2i) -> bool:
	if not is_valid_cell(cell): return false
	var data := get_cell(cell)
	if data.tilled: return false
	data.tilled = true
	cells[cell] = data
	queue_redraw()
	return true

func plant(cell: Vector2i) -> bool:
	if not is_valid_cell(cell): return false
	var data := get_cell(cell)
	if not data.tilled or data.crop != "": return false
	data.crop = "turnip"
	data.stage = 0
	data.age = 0
	cells[cell] = data
	queue_redraw()
	return true

func water(cell: Vector2i) -> bool:
	if not is_valid_cell(cell): return false
	var data := get_cell(cell)
	if not data.tilled or data.watered: return false
	data.watered = true
	cells[cell] = data
	queue_redraw()
	return true

func harvest(cell: Vector2i) -> bool:
	if not is_valid_cell(cell): return false
	var data := get_cell(cell)
	if data.crop == "" or data.stage < 3: return false
	data.crop = ""
	data.stage = 0
	data.age = 0
	cells[cell] = data
	queue_redraw()
	return true

func next_day() -> void:
	current_day += 1
	for key in cells.keys():
		var data: Dictionary = cells[key]
		if data.crop != "" and data.watered:
			data.age += 1
			data.stage = clampi(data.age, 0, 3)
		data.watered = false
		cells[key] = data
	queue_redraw()

func get_save_data() -> Dictionary:
	var serialized := {}
	for key in cells.keys():
		serialized["%d,%d" % [key.x, key.y]] = cells[key]
	return {"day": current_day, "cells": serialized}

func load_save_data(data: Dictionary) -> void:
	current_day = int(data.get("day", 1))
	cells.clear()
	var saved_cells: Dictionary = data.get("cells", {})
	for key in saved_cells.keys():
		var parts := String(key).split(",")
		if parts.size() == 2:
			cells[Vector2i(int(parts[0]), int(parts[1]))] = saved_cells[key]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 900), Color("#65a852"))
	draw_rect(Rect2(ORIGIN - Vector2(8, 8), Vector2(COLS*TILE_SIZE+16, ROWS*TILE_SIZE+16)), Color("#3f7d3a"), true)
	for y in ROWS:
		for x in COLS:
			var c := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(x*TILE_SIZE, y*TILE_SIZE), Vector2(TILE_SIZE-2, TILE_SIZE-2))
			var data := get_cell(c)
			var base := Color("#78b75a") if (x+y)%2 == 0 else Color("#72ae55")
			if data.tilled:
				base = Color("#7a5230")
			if data.watered:
				base = Color("#60442f")
			draw_rect(rect, base, true)
			if data.crop != "":
				_draw_crop(rect.get_center(), int(data.stage))
	draw_circle(Vector2(1120, 660), 92, Color("#4aa6c8"))
	draw_circle(Vector2(1120, 660), 72, Color("#57b7d5"))
	for p in [Vector2(50,50),Vector2(1210,60),Vector2(50,820),Vector2(1180,830)]:
		draw_circle(p, 28, Color("#2f6f38"))
		draw_rect(Rect2(p + Vector2(-6,20), Vector2(12,28)), Color("#765033"), true)

func _draw_crop(center: Vector2, stage: int) -> void:
	var s := 5.0 + stage * 4.0
	draw_line(center + Vector2(0, 15), center + Vector2(0, -s), Color("#285b2d"), 5)
	draw_circle(center + Vector2(-s*0.65, -s*0.3), s*0.55, Color("#49a942"))
	draw_circle(center + Vector2(s*0.65, -s*0.3), s*0.55, Color("#58bd4e"))
	if stage >= 3:
		draw_circle(center + Vector2(0, 8), 12, Color("#e7e9da"))
		draw_circle(center + Vector2(0, 11), 5, Color("#b598d5"))
