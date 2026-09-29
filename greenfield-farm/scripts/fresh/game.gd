extends Node2D

@onready var player: FreshPlayer = $World/Player
@onready var joystick = $HUD/Joystick
@onready var use_button: Button = $HUD/UseButton
@onready var message_box: Panel = $HUD/MessageBox
@onready var message_label: Label = $HUD/MessageBox/Message
@onready var crop_label: Label = $HUD/CropCard/CropCount

var harvested_crops := 0
var message_serial := 0

func _ready() -> void:
	joystick.move_changed.connect(player.set_touch_move)
	use_button.pressed.connect(player.interact)
	player.interaction_result.connect(_on_interaction_result)
	_show_message("Morning. Marnie left a few beds ready for planting.", 4.2)
	_update_crop_label()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			player.interact()

func _on_interaction_result(data: Dictionary) -> void:
	if data.has("harvest"):
		harvested_crops += int(data["harvest"])
		_update_crop_label()
	var text := String(data.get("message", ""))
	if not text.is_empty():
		_show_message(text)

func _show_message(text: String, hold_seconds: float = 3.4) -> void:
	if text.is_empty():
		return
	message_serial += 1
	var serial := message_serial
	message_label.text = text
	message_box.visible = true
	message_box.modulate.a = 1.0
	await get_tree().create_timer(hold_seconds).timeout
	if serial != message_serial:
		return
	var tween := create_tween()
	tween.tween_property(message_box, "modulate:a", 0.0, 0.18)
	await tween.finished
	if serial == message_serial:
		message_box.visible = false
		message_box.modulate.a = 1.0

func _update_crop_label() -> void:
	crop_label.text = "HARVEST  %d" % harvested_crops
