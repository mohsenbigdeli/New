extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _run() -> void:
	var player := FarmPlayer.new()
	root.add_child(player)
	player.set_physics_process(false)
	player.position = Vector2(600, 600)
	player.set_custom_character_sheet(load("res://assets/art/v23/farmer_walk_sheet.svg"), 4, 4, Vector2(0.72, 0.72))
	await physics_frame
	for direction in [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]:
		player.set_virtual_move(direction)
		var seen := {}
		for step in range(30):
			await physics_frame
			player._physics_process(1.0 / 60.0)
			seen[player.character_sprite.frame_coords.x] = true
		check(player.is_walking, "Directional movement must animate")
		check(player.character_sprite.frame_coords.y == player._sheet_row_for_facing(), "Wrong facing row")
		check(seen.has(0) and seen.has(1) and seen.has(2), "Both stride poses and contact pose must appear")
	player.set_virtual_move(Vector2.ZERO)
	player._physics_process(1.0 / 60.0)
	check(not player.is_walking and player.character_sprite.frame_coords.x == 0, "Idle must reset pose")
	player.position.x = player.world_size.x - 42.0
	player.set_virtual_move(Vector2.RIGHT)
	await physics_frame
	player._physics_process(1.0 / 60.0)
	check(not player.is_walking, "World boundary must not produce walking in place")
	player.position = Vector2(600, 600)
	player.set_virtual_move(Vector2(0.5, 0))
	await physics_frame
	player._physics_process(1.0 / 60.0)
	check(is_equal_approx(player.velocity.x, player.speed * 0.5), "Analog movement must preserve stick strength")
	player.set_controls_locked(true)
	var before := player.position
	player._physics_process(1.0 / 60.0)
	check(player.position == before and not player.is_walking and player.walk_time == 0.0, "Locked controls must stop and reset gait")
	player.free()
	print("Player motion checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
