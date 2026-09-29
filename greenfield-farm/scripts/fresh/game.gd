extends Node2D

@onready var player: FreshPlayer = $World/Player
@onready var joystick = $HUD/Joystick
@onready var use_button: Button = $HUD/UseButton
@onready var message_label: Label = $HUD/MessageBox/Message
@onready var crop_label: Label = $HUD/CropCard/CropCount

var harvested_turnips := 0

func _ready() -> void:
	joystick.move_changed.connect(player.set_touch_move)
	use_button.pressed.connect(player.interact)
	player.interaction_result.connect(_on_interaction_result)
	_show_message("Welcome home. Six garden beds are ready for your first crop.")
	_update_crop_label()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			player.interact()

func _on_interaction_result(data: Dictionary) -> void:
	if data.has("harvest"):
		harvested_turnips += int(data["harvest"])
		_update_crop_label()
	_show_message(String(data.get("message", "")))

func _show_message(text: String) -> void:
	message_label.text = text

func _update_crop_label() -> void:
	crop_label.text = "TURNIPS  %d" % harvested_turnips
