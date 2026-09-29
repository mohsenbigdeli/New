extends Node2D
const SaveStore = preload("res://scripts/fresh/save_store.gd")
@onready var player: FreshPlayer = $World/Player
@onready var plots: Node2D = $World/Plots
var hud: FarmProHUD
var atmosphere: FarmAtmosphere
var tint: CanvasModulate
var harvested_crops := 0
var day := 1
var minute := 480.0
var autosave_clock := 0.0
var started := false
var settings := {"touch":false,"effects":true,"sound":true,"zoom":1.15}
var tone: AudioStreamPlayer
var tones := {}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	$HUD.queue_free()
	settings.touch = OS.has_feature("mobile")
	var config := ConfigFile.new()
	if config.load("user://greenfield_settings.cfg") == OK:
		for key in settings:
			settings[key] = config.get_value("preferences",key,settings[key])
	atmosphere = FarmAtmosphere.new()
	$World.add_child(atmosphere)
	tint = CanvasModulate.new()
	$World.add_child(tint)
	hud = FarmProHUD.new()
	add_child(hud)
	hud.command.connect(_command)
	hud.setting_changed.connect(_setting_changed)
	hud.joystick.move_changed.connect(player.set_touch_move)
	player.interaction_result.connect(_on_interaction_result)
	tone = AudioStreamPlayer.new()
	add_child(tone)
	tone.volume_db = -20
	tone.stream = _make_tone(440.0)
	for kind in ["soil","plant","water","harvest","talk"]:
		tones[kind] = _make_tone({"soil":220.0,"plant":440.0,"water":640.0,"harvest":880.0,"talk":330.0}[kind])
	_apply_settings()
	hud.has_save = not SaveStore.load_snapshot().is_empty()
	hud.show_menu("title")
	_update_status()

func _process(delta: float) -> void:
	if not started:
		return
	minute += delta * 2.0
	if minute >= 1200:
		minute = 360
		day += 1
		hud.show_toast("A new morning. Your garden is waiting.")
	var sunset := clampf((minute - 990) / 210.0,0,1)
	tint.color = Color.WHITE.lerp(Color("bdadca"), sunset*0.4)
	var target := player.find_target()
	atmosphere.target = target
	hud.set_target(target.action_label() if target is FreshPlot else ("Talk to Marnie" if target != null else ""))
	_update_status()
	autosave_clock += delta
	if autosave_clock >= 30:
		autosave_clock = 0
		save_game(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if not started or get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E, KEY_SPACE: player.interact()
			KEY_J: _command("journal")
			KEY_F5: save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if started: save_game(false)
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and started and is_instance_valid(hud):
		save_game(false)
		hud.show_menu("pause")
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(hud):
		hud.show_menu("pause" if started else "title")

func _command(action: String) -> void:
	match action:
		"resume":
			hud.close_menu()
		"new":
			harvested_crops = 0
			day = 1
			minute = 480
			player.position = Vector2(470,595)
			player.velocity = Vector2.ZERO
			for plot in plots.get_children():
				plot.state = 0
				plot.grow_time = 0
				plot._update_visual()
			_begin()
			save_game(false)
			hud.show_toast("Welcome home. Walk south to your garden beds.")
		"load":
			var data := SaveStore.load_snapshot()
			if data.is_empty():
				hud.close_menu()
				hud.show_toast("No readable save found. Start a new farm.")
				return
			_restore(data)
			_begin()
			hud.show_toast("Welcome back. Your farm is restored.")
		"save":
			save_game()
			if started:
				hud.close_menu()
		"journal":
			var counts := _plot_counts()
			hud.show_journal(harvested_crops, counts.x, counts.y)
		"guide": hud.show_menu("guide")
		"use": player.interact()

func _begin() -> void:
	started = true
	hud.started = true
	hud.close_menu()
	player.get_node("Camera2D").reset_smoothing()
	_update_status()

func _snapshot() -> Dictionary:
	var beds: Array = []
	for plot in plots.get_children():
		beds.append({"state":plot.state,"grow_time":plot.grow_time})
	return {"version":1,"day":day,"minute":minute,"harvest":harvested_crops,"position":[player.position.x,player.position.y],"plots":beds}

func _restore(data: Dictionary) -> void:
	day = maxi(1,int(data.get("day",1)))
	minute = clampf(float(data.get("minute",480)),360,1199)
	harvested_crops = maxi(0,int(data.get("harvest",0)))
	player.position = Vector2(clampf(float(data.position[0]),30,1890),clampf(float(data.position[1]),30,1026))
	player.velocity = Vector2.ZERO
	for i in range(plots.get_child_count()):
		var plot = plots.get_child(i)
		plot.state = int(data.plots[i].state)
		plot.grow_time = clampf(float(data.plots[i].get("grow_time",0)),0,FreshPlot.GROW_SECONDS)
		plot._update_visual()

func save_game(show_feedback := true) -> bool:
	if not started:
		return false
	var saved := SaveStore.write_snapshot(_snapshot())
	hud.has_save = saved or hud.has_save
	if show_feedback:
		hud.show_toast("Progress saved." if saved else "Could not save. Please check available storage.")
	return saved

func _plot_counts() -> Vector2i:
	var result := Vector2i.ZERO
	for plot in plots.get_children():
		if plot.state == 3: result.x += 1
		if plot.state == 4: result.y += 1
	return result

func _update_status() -> void:
	var counts := _plot_counts()
	hud.update_status(day,int(minute),harvested_crops,counts.y)

func _on_interaction_result(data: Dictionary) -> void:
	if data.has("harvest"):
		harvested_crops += int(data.harvest)
		if harvested_crops == 5:
			data.message = "First harvest complete! Five crops, grown by you."
	if data.has("effect"):
		atmosphere.burst(data.position, data.effect)
		if settings.sound:
			tone.stream = tones.get(data.effect, tones.talk)
			tone.play()
	if data.has("message"):
		hud.show_toast(data.message)
	_update_status()

func _setting_changed(key: String, value: Variant) -> void:
	settings[key] = value
	_apply_settings()
	var config := ConfigFile.new()
	for setting in settings:
		config.set_value("preferences",setting,settings[setting])
	config.save("user://greenfield_settings.cfg")

func _apply_settings() -> void:
	hud.apply_settings(settings)
	atmosphere.enabled = bool(settings.effects)
	player.reduced_motion = not bool(settings.effects)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * clampf(float(settings.zoom),0.9,1.5)
	camera.position_smoothing_enabled = bool(settings.effects)
	if not settings.touch:
		hud.joystick.release()

func _make_tone(frequency: float) -> AudioStreamWAV:
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	var bytes := PackedByteArray()
	var count := 4410
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / 22050.0
		var envelope := sin(PI * float(i) / count) * exp(-t*15)
		var sample := int(sin(t * TAU * frequency) * envelope * 18000)
		bytes.encode_s16(i * 2, sample)
	audio.data = bytes
	return audio
func _exit_tree() -> void:
	if is_instance_valid(tone):
		tone.stop()
