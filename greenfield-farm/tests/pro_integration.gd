extends SceneTree
const Save = preload("res://scripts/fresh/save_store.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	var game = load("res://scenes/fresh/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(paused and game.hud.overlay.visible, "Title must pause simulation")
	game.started = true
	game.hud.started = true
	game.hud.close_menu()
	var player = game.player
	player.set_physics_process(false)
	player.position = Vector2(900,520)
	for spec in [[Vector2.DOWN,0],[Vector2.RIGHT,1],[Vector2.UP,2],[Vector2.LEFT,3]]:
		player.set_touch_move(spec[0])
		var columns := {}
		for i in range(18):
			await physics_frame
			player._physics_process(1.0/60.0)
			columns[int(player.walk_clock)] = true
		check(player.row == spec[1], "Wrong directional animation")
		check(columns.size() >= 3, "Walking must cycle distinct frames")
	player.position = Vector2(1905,520)
	player.set_touch_move(Vector2.RIGHT)
	for i in range(40):
		await physics_frame
		player._physics_process(1.0/60.0)
	check(player.position.x < 1920 and player.walk_clock == 0, "Collision must stop displacement and animation")
	player.velocity = Vector2.ZERO
	player.position = Vector2(900,520)
	player.set_touch_move(Vector2(0.2,0))
	for i in range(8):
		await physics_frame
		player._physics_process(1.0/60.0)
	check(player.position.x > 900, "Low analog movement must not be lost to pixel rounding")
	player.set_touch_move(Vector2.ZERO)
	player.velocity = Vector2.ZERO
	player.position = Vector2(240,640)
	for i in range(3): await physics_frame
	var plot = game.plots.get_child(0)
	check(player.find_target() == plot, "Displayed target and action target must agree")
	for expected in [1,2,3]:
		player.action_time = 0
		player.interact()
		check(plot.state == expected, "Planting cycle must advance once per action")
	plot._process(FreshPlot.GROW_SECONDS)
	check(plot.state == 4, "Watered crop must mature")
	player.action_time = 0
	player.interact()
	check(game.harvested_crops == 1 and plot.state == 1, "Harvest must reward once and retain prepared soil")
	game.hud.show_menu("pause")
	var old_minute: float = game.minute
	for i in range(4): await process_frame
	check(game.minute == old_minute, "Paused menu must freeze clock")
	game._setting_changed("touch",true)
	check(not game.hud.joystick.visible, "Touch controls must stay hidden behind menu")
	game.hud.close_menu()
	check(game.hud.joystick.visible, "Touch setting must apply after resume")
	var data: Dictionary = game._snapshot()
	var path := "user://pro_test_only.json"
	check(Save.write_snapshot(data,path), "Save write failed")
	check(Save.load_snapshot(path).harvest == 1, "Save/load round trip failed")
	data.harvest = 2
	check(Save.write_snapshot(data,path), "Second save failed")
	var f := FileAccess.open(path,FileAccess.WRITE)
	f.store_string("broken")
	f.close()
	check(Save.load_snapshot(path).harvest == 1, "Corrupt primary must recover backup")
	data.plots[0].state = 999
	check(not Save.write_snapshot(data,path), "Invalid state must not replace a good save")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	print("Pro integration checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	game.started = false
	paused = false
	game.tone.stop()
	await create_timer(0.25).timeout
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
