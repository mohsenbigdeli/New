extends Area2D

@export_multiline var message := "Hello."
@export var action := ""

func interact() -> Dictionary:
	return {"message":message, "action":action}
